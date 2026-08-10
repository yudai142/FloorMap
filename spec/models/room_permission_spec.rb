require "rails_helper"

RSpec.describe RoomPermission, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:room) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:permission_type) }
    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_presence_of(:room_id) }

    context "uniqueness of user_id scoped to room_id" do
      let(:user) { create(:user) }
      let(:room) { create(:room) }

      it "allows multiple permissions for same user in different rooms" do
        room2 = create(:room)
        permission1 = create(:room_permission, user:, room:, permission_type: :view)
        permission2 = build(:room_permission, user:, room: room2, permission_type: :edit)
        expect(permission2).to be_valid
      end

      it "disallows duplicate user_id + room_id combinations" do
        create(:room_permission, user:, room:, permission_type: :view)
        duplicate = build(:room_permission, user:, room:, permission_type: :edit)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:user_id]).to include("has already been taken")
      end
    end
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:permission_type).with_values(view: 0, edit: 1, manage: 2) }
  end

  describe "permission types" do
    let(:room) { create(:room) }
    let(:user) { create(:user) }

    describe "view permission" do
      it "allows users to view room and seat information" do
        permission = create(:room_permission, room:, user:, permission_type: :view)
        expect(permission.view?).to be true
        expect(permission.edit?).to be false
        expect(permission.manage?).to be false
      end
    end

    describe "edit permission" do
      it "allows users to edit seats and check-in status" do
        permission = create(:room_permission, room:, user:, permission_type: :edit)
        expect(permission.edit?).to be true
        expect(permission.manage?).to be false
      end
    end

    describe "manage permission" do
      it "allows users to manage room permissions and all features" do
        permission = create(:room_permission, room:, user:, permission_type: :manage)
        expect(permission.manage?).to be true
        expect(permission.view?).to be true
        expect(permission.edit?).to be true
      end
    end
  end

  describe "creation and persistence" do
    let(:room) { create(:room) }
    let(:user) { create(:user) }

    it "creates and persists valid room permission" do
      permission = create(:room_permission, room:, user:, permission_type: :edit)
      expect(permission).to be_persisted
      expect(permission.room_id).to eq(room.id)
      expect(permission.user_id).to eq(user.id)
      expect(permission.permission_type).to eq("edit")
    end

    it "associates permission with both user and room" do
      permission = create(:room_permission, room:, user:, permission_type: :view)
      expect(permission.user).to eq(user)
      expect(permission.room).to eq(room)
    end
  end

  describe "user_email attribute" do
    let(:room) { create(:room) }
    let(:user) { create(:user, email: 'test@example.com') }

    context "when user_email is provided" do
      it "finds user by email and sets user_id" do
        permission = build(:room_permission, room:, user_email: 'test@example.com', permission_type: :view)
        permission.valid?
        expect(permission.user_id).to eq(user.id)
      end

      it "validates presence of user with that email" do
        permission = build(:room_permission, room:, user_email: 'nonexistent@example.com', permission_type: :view)
        expect(permission).not_to be_valid
        expect(permission.errors[:user_email]).to include("メールアドレスが見つかりません")
      end
    end
  end
end
