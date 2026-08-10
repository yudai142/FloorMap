require "rails_helper"

RSpec.describe RoomPermissionPolicy do
  let(:room_owner) { create(:user, role: :manager) }
  let(:other_user) { create(:user) }
  let(:room) { create(:room, user: room_owner) }
  let(:room_permission) { create(:room_permission, room:) }

  describe "#create?" do
    it "allows room owner to create permissions" do
      policy = RoomPermissionPolicy.new(room_owner, RoomPermission.new(room:))
      expect(policy.create?).to be true
    end

    it "denies non-room owner from creating permissions" do
      policy = RoomPermissionPolicy.new(other_user, RoomPermission.new(room:))
      expect(policy.create?).to be false
    end

    it "allows admin to create permissions on any room" do
      admin = create(:user, role: :admin)
      policy = RoomPermissionPolicy.new(admin, RoomPermission.new(room:))
      expect(policy.create?).to be true
    end
  end

  describe "#destroy?" do
    it "allows room owner to destroy permissions" do
      policy = RoomPermissionPolicy.new(room_owner, room_permission)
      expect(policy.destroy?).to be true
    end

    it "denies non-room owner from destroying permissions" do
      policy = RoomPermissionPolicy.new(other_user, room_permission)
      expect(policy.destroy?).to be false
    end

    it "allows admin to destroy permissions on any room" do
      admin = create(:user, role: :admin)
      policy = RoomPermissionPolicy.new(admin, room_permission)
      expect(policy.destroy?).to be true
    end
  end
end
