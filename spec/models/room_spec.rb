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
  end
end
