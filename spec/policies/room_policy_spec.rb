require 'rails_helper'

RSpec.describe RoomPolicy, type: :policy do
  let(:admin_user) { create(:user, :admin) }
  let(:manager) { create(:user, :manager) }
  let(:regular_user) { create(:user, :user) }
  let(:room) { create(:room, user: manager) }

  describe '#show?' do
    it 'allows owner to view room' do
      policy = RoomPolicy.new(manager, room)
      expect(policy.show?).to be true
    end

    it 'allows user with permission to view room' do
      create(:room_permission, room: room, user: regular_user)
      policy = RoomPolicy.new(regular_user, room)
      expect(policy.show?).to be true
    end

    it 'denies user without permission' do
      policy = RoomPolicy.new(regular_user, room)
      expect(policy.show?).to be false
    end
  end

  describe '#create?' do
    it 'allows manager to create room' do
      policy = RoomPolicy.new(manager, room)
      expect(policy.create?).to be true
    end

    it 'allows admin to create room' do
      policy = RoomPolicy.new(admin_user, room)
      expect(policy.create?).to be true
    end

    it 'denies regular user from creating room' do
      policy = RoomPolicy.new(regular_user, room)
      expect(policy.create?).to be false
    end
  end

  describe '#update?' do
    it 'allows owner to update room' do
      policy = RoomPolicy.new(manager, room)
      expect(policy.update?).to be true
    end

    it 'denies non-owner from updating room' do
      policy = RoomPolicy.new(regular_user, room)
      expect(policy.update?).to be false
    end
  end

  describe '#destroy?' do
    it 'allows owner to destroy room' do
      policy = RoomPolicy.new(manager, room)
      expect(policy.destroy?).to be true
    end

    it 'denies non-owner from destroying room' do
      policy = RoomPolicy.new(regular_user, room)
      expect(policy.destroy?).to be false
    end
  end

  describe '#index?' do
    it 'allows any authenticated user' do
      policy = RoomPolicy.new(regular_user, room)
      expect(policy.index?).to be true
    end

    it 'allows admin user' do
      policy = RoomPolicy.new(admin_user, room)
      expect(policy.index?).to be true
    end

    it 'allows manager user' do
      policy = RoomPolicy.new(manager, room)
      expect(policy.index?).to be true
    end
  end

  describe '.scope' do
    let(:policy_scope) { RoomPolicy::Scope.new(regular_user, Room.all) }

    before do
      create(:room, name: 'Regular User Room', user: regular_user)
      create(:room, name: 'Manager Room', user: manager)
      create(:room_permission, room: room, user: regular_user)
    end

    it 'returns rooms owned by user' do
      scoped = policy_scope.resolve
      expect(scoped).to include(Room.find_by(name: 'Regular User Room'))
    end

    it 'returns rooms shared with user' do
      scoped = policy_scope.resolve
      expect(scoped).to include(room)
    end

    it 'does not return rooms with no access' do
      scoped = policy_scope.resolve
      expect(scoped).not_to include(Room.find_by(name: 'Manager Room'))
    end

    context 'for admin user' do
      let(:admin_policy_scope) { RoomPolicy::Scope.new(admin_user, Room.all) }

      it 'returns all rooms' do
        scoped = admin_policy_scope.resolve
        expect(scoped.count).to eq(Room.count)
      end
    end
  end
end
