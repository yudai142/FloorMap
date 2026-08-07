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
    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:room_id) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:permission_type).with_values(view: 0, edit: 1, manage: 2) }
  end

  describe "permissions" do
    let(:room) { create(:room) }
    let(:user) { create(:user) }

    it "creates a room permission with view type" do
      permission = build(:room_permission, room:, user:, permission_type: :view)
      expect(permission.permission_type).to eq("view")
    end

    it "creates a room permission with edit type" do
      permission = build(:room_permission, room:, user:, permission_type: :edit)
      expect(permission.permission_type).to eq("edit")
    end

    it "creates a room permission with manage type" do
      permission = build(:room_permission, room:, user:, permission_type: :manage)
      expect(permission.permission_type).to eq("manage")
    end
  end
end
