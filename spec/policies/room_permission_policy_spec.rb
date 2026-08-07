require "rails_helper"

RSpec.describe RoomPermissionPolicy do
  let(:room_owner) { create(:user, role: :manager) }
  let(:other_user) { create(:user) }
  let(:room) { create(:room, user: room_owner) }
  let(:room_permission) { create(:room_permission, room:) }

  describe "create?" do
    context "when user is room owner" do
      it "allows room owner to create permissions" do
        policy = RoomPermissionPolicy.new(room_owner, RoomPermission.new(room:))
        expect(policy).to permit_action(:create?)
      end
    end

    context "when user is not room owner" do
      it "denies non-room owner from creating permissions" do
        policy = RoomPermissionPolicy.new(other_user, RoomPermission.new(room:))
        expect(policy).not_to permit_action(:create?)
      end
    end

    context "when user is admin" do
      it "allows admin to create permissions on any room" do
        admin = create(:user, role: :admin)
        policy = RoomPermissionPolicy.new(admin, RoomPermission.new(room:))
        expect(policy).to permit_action(:create?)
      end
    end
  end

  describe "destroy?" do
    context "when user is room owner" do
      it "allows room owner to destroy permissions" do
        policy = RoomPermissionPolicy.new(room_owner, room_permission)
        expect(policy).to permit_action(:destroy?)
      end
    end

    context "when user is not room owner" do
      it "denies non-room owner from destroying permissions" do
        policy = RoomPermissionPolicy.new(other_user, room_permission)
        expect(policy).not_to permit_action(:destroy?)
      end
    end

    context "when user is admin" do
      it "allows admin to destroy permissions on any room" do
        admin = create(:user, role: :admin)
        policy = RoomPermissionPolicy.new(admin, room_permission)
        expect(policy).to permit_action(:destroy?)
      end
    end
  end
end
