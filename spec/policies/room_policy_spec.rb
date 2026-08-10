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
end
