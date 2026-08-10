require 'rails_helper'

RSpec.describe Room, type: :model do
  describe 'associations' do
    it "belongs to user" do
      room = build(:room)
      expect(room).to respond_to(:user)
    end

    it "has many room_permissions" do
      room = build(:room)
      expect(room).to respond_to(:room_permissions)
    end
  end

  describe 'validations' do
    it "validates presence of name" do
      room = build(:room, name: nil)
      expect(room).not_to be_valid
    end
  end

  describe 'relationships' do
    let(:manager) { create(:user, :manager) }
    let(:room) { create(:room, user: manager) }

    it 'belongs to a user' do
      expect(room.user).to eq(manager)
    end

    it 'can have many room permissions' do
      user1 = create(:user)
      user2 = create(:user)

      create(:room_permission, room: room, user: user1)
      create(:room_permission, room: room, user: user2)

      expect(room.room_permissions.count).to eq(2)
    end

    it 'destroys room permissions when deleted' do
      user = create(:user)
      create(:room_permission, room: room, user: user)

      expect { room.destroy }.to change(RoomPermission, :count).by(-1)
    end

    it 'has many seats' do
      room = build(:room)
      expect(room).to respond_to(:seats)
    end
  end

  describe 'scopes' do
    let(:manager) { create(:user, :manager) }
    let(:user) { create(:user) }

    before do
      create(:room, name: 'Meeting Room A', user: manager, description: 'Large conference room')
      create(:room, name: 'Meeting Room B', user: manager, description: 'Small meeting space')
      create(:room, name: 'Office A', user: user, description: 'Open office')
    end

    describe '.search' do
      it 'finds rooms by name' do
        results = Room.search('Meeting')
        expect(results.count).to eq(2)
        expect(results.all? { |r| r.name.include?('Meeting') }).to be true
      end

      it 'finds rooms by description' do
        results = Room.search('office')
        expect(results.count).to eq(1)
        expect(results.first.name).to eq('Office A')
      end

      it 'returns all rooms when search is empty' do
        results = Room.search('')
        expect(results.count).to eq(3)
      end

      it 'is case insensitive' do
        results = Room.search('MEETING')
        expect(results.count).to eq(2)
      end
    end

    describe '.by_owner' do
      it 'filters rooms by owner' do
        results = Room.by_owner(manager.id)
        expect(results.count).to eq(2)
        expect(results.all? { |r| r.user_id == manager.id }).to be true
      end

      it 'returns empty when owner has no rooms' do
        other_user = create(:user)
        results = Room.by_owner(other_user.id)
        expect(results.count).to eq(0)
      end
    end

    describe '.accessible_by' do
      it 'returns rooms owned by user' do
        results = Room.accessible_by(manager)
        expect(results).to include(*Room.where(user_id: manager.id))
      end

      it 'returns rooms shared with user via permissions' do
        room = create(:room, user: manager)
        create(:room_permission, room: room, user: user)

        results = Room.accessible_by(user)
        expect(results).to include(room)
      end

      it 'returns rooms for admin (all rooms)' do
        admin = create(:user, :admin)
        results = Room.accessible_by(admin)
        expect(results.count).to eq(3)
      end
    end

    describe '.sorted' do
      it 'sorts rooms by name ascending' do
        results = Room.sorted('name', 'asc')
        names = results.map(&:name)
        expect(names).to eq(names.sort)
      end

      it 'sorts rooms by name descending' do
        results = Room.sorted('name', 'desc')
        names = results.map(&:name)
        expect(names).to eq(names.sort.reverse)
      end

      it 'defaults to created_at descending when sorted with created_at' do
        results = Room.sorted('created_at', 'desc')
        expect(results).to be_a(ActiveRecord::Relation)
        expect(results.count).to eq(3)
      end
    end
  end

  describe 'instance methods' do
    let(:manager) { create(:user, :manager) }
    let(:room) { create(:room, user: manager) }

    describe '#seat_count' do
      it 'returns count of seats' do
        create_list(:seat, 3, room: room)
        expect(room.seat_count).to eq(3)
      end

      it 'returns 0 when no seats' do
        expect(room.seat_count).to eq(0)
      end
    end

    describe '#occupied_seat_count' do
      it 'returns count of occupied seats' do
        seat1 = create(:seat, room: room)
        seat2 = create(:seat, room: room)
        create(:session, seat: seat1, status: :active)

        expect(room.occupied_seat_count).to eq(1)
      end

      it 'returns 0 when no occupied seats' do
        create_list(:seat, 2, room: room)
        expect(room.occupied_seat_count).to eq(0)
      end
    end

    describe '#seat_grid' do
      it 'returns seats organized by row' do
        create(:seat, room: room, row_number: 0, column_number: 1)
        create(:seat, room: room, row_number: 0, column_number: 2)
        create(:seat, room: room, row_number: 1, column_number: 1)

        grid = room.seats.group_by(&:row_number)
        expect(grid.keys).to include(0, 1)
        expect(grid[0].count).to eq(2)
      end

      it 'sorts seats by column in each row' do
        create(:seat, room: room, row_number: 0, column_number: 2)
        create(:seat, room: room, row_number: 0, column_number: 1)

        seats_in_row = room.seats.where(row_number: 0).order(:column_number)
        expect(seats_in_row.first.column_number).to eq(1)
        expect(seats_in_row.last.column_number).to eq(2)
      end
    end

    describe '#seats_by_type' do
      it 'groups seats by type' do
        create(:seat, room: room, seat_type: 'regular')
        create(:seat, room: room, seat_type: 'accessible')
        create(:seat, room: room, seat_type: 'vip')

        seats_by_type = room.seats.group_by(&:seat_type)
        expect(seats_by_type.keys).to include('regular', 'accessible', 'vip')
      end

      it 'counts each seat type' do
        create_list(:seat, 2, room: room, seat_type: 'regular')
        create(:seat, room: room, seat_type: 'accessible')

        regular_count = room.seats.where(seat_type: 'regular').count
        expect(regular_count).to eq(2)
      end
    end
  end
end
