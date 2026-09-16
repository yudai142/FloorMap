require "rails_helper"

RSpec.describe RoomPermission, type: :model do
  describe "associations" do
    it "has user association" do
      permission = build(:room_permission)
      expect(permission).to respond_to(:user)
    end

    it "has room association" do
      permission = build(:room_permission)
      expect(permission).to respond_to(:room)
    end
  end

  describe "validations" do
    it "validates presence of permission_type" do
      permission = build(:room_permission, permission_type: nil)
      expect(permission).not_to be_valid
    end

    it "validates presence of user_id" do
      permission = build(:room_permission, user_id: nil)
      expect(permission).not_to be_valid
    end

    it "validates presence of room_id" do
      permission = build(:room_permission, room_id: nil)
      expect(permission).not_to be_valid
    end

    context "uniqueness of user_id scoped to room_id" do
      let(:user) { create(:user) }
      let(:room) { create(:room) }

      it "allows multiple permissions for same user in different rooms" do
        room2 = create(:room)
        create(:room_permission, user:, room:, permission_type: :view)
        permission2 = build(:room_permission, user:, room: room2, permission_type: :edit)
        expect(permission2).to be_valid
      end

      it "disallows duplicate user_id + room_id combinations" do
        create(:room_permission, user:, room:, permission_type: :view)
        duplicate = build(:room_permission, user:, room:, permission_type: :edit)
        expect(duplicate).not_to be_valid
      end
    end
  end

  describe "enums" do
    it "has view, edit, manage permission types" do
      permission = build(:room_permission, permission_type: :view)
      expect(permission.view?).to be true
    end
  end

  describe "permission types" do
    let(:room) { create(:room) }
    let(:user) { create(:user) }

    it "creates view permission" do
      permission = create(:room_permission, room:, user:, permission_type: :view)
      expect(permission.view?).to be true
      expect(permission.edit?).to be false
    end

    it "creates edit permission" do
      permission = create(:room_permission, room:, user:, permission_type: :edit)
      expect(permission.edit?).to be true
    end

    it "creates manage permission" do
      permission = create(:room_permission, room:, user:, permission_type: :manage)
      expect(permission.manage?).to be true
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
    end

    it "associates permission with both user and room" do
      permission = create(:room_permission, room:, user:, permission_type: :view)
      expect(permission.user).to eq(user)
      expect(permission.room).to eq(room)
    end
  end

  describe "user_email attribute" do
    let(:room) { create(:room) }

    it "finds user by email and sets user_id" do
      user = create(:user, email: 'test@example.com')
      permission = RoomPermission.new(room_id: room.id, permission_type: :view, user_email: 'test@example.com')
      permission.valid?
      expect(permission.user_id).to eq(user.id)
    end

    it "validates presence of user with that email" do
      permission = RoomPermission.new(room_id: room.id, permission_type: :view, user_email: 'nonexistent@example.com')
      expect(permission).not_to be_valid
      expect(permission.errors[:user_email]).to include("メールアドレスが見つかりません")
    end
  end
end
