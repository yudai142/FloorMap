require "rails_helper"

RSpec.describe SeatPolicy do
  let(:room_owner) { create(:user, role: :manager) }
  let(:other_user) { create(:user) }
  let(:admin_user) { create(:user, role: :admin) }
  let(:room) { create(:room, user: room_owner) }
  let(:seat) { create(:seat, room:) }

  describe "#show?" do
    it "allows room owner to view seat" do
      policy = SeatPolicy.new(room_owner, seat)
      expect(policy.show?).to be true
    end

    it "allows user with view permission to view seat" do
      create(:room_permission, room:, user: other_user, permission_type: :view)
      policy = SeatPolicy.new(other_user, seat)
      expect(policy.show?).to be true
    end

    it "denies user without permission" do
      policy = SeatPolicy.new(other_user, seat)
      expect(policy.show?).to be false
    end

    it "allows admin to view seat" do
      policy = SeatPolicy.new(admin_user, seat)
      expect(policy.show?).to be true
    end
  end

  describe "#create?" do
    it "allows room owner to create seat" do
      policy = SeatPolicy.new(room_owner, Seat.new(room:))
      expect(policy.create?).to be true
    end

    it "denies non-owner from creating seat" do
      policy = SeatPolicy.new(other_user, Seat.new(room:))
      expect(policy.create?).to be false
    end

    it "allows admin to create seat" do
      policy = SeatPolicy.new(admin_user, Seat.new(room:))
      expect(policy.create?).to be true
    end
  end

  describe "#update?" do
    it "allows room owner to update seat" do
      policy = SeatPolicy.new(room_owner, seat)
      expect(policy.update?).to be true
    end

    it "denies non-owner from updating seat" do
      policy = SeatPolicy.new(other_user, seat)
      expect(policy.update?).to be false
    end

    it "allows admin to update seat" do
      policy = SeatPolicy.new(admin_user, seat)
      expect(policy.update?).to be true
    end
  end

  describe "#destroy?" do
    it "allows room owner to destroy seat" do
      policy = SeatPolicy.new(room_owner, seat)
      expect(policy.destroy?).to be true
    end

    it "denies non-owner from destroying seat" do
      policy = SeatPolicy.new(other_user, seat)
      expect(policy.destroy?).to be false
    end

    it "allows admin to destroy seat" do
      policy = SeatPolicy.new(admin_user, seat)
      expect(policy.destroy?).to be true
    end
  end
end
