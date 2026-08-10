require 'rails_helper'

RSpec.describe Room, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:room_permissions).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
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
