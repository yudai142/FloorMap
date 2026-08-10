require "rails_helper"

RSpec.describe SessionPolicy do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:admin_user) { create(:user, role: :admin) }
  let(:room) { create(:room) }
  let(:seat) { create(:seat, room:) }
  let(:session) { create(:session, user:, seat:) }

  describe "#check_in?" do
    it "allows user to check in" do
      policy = SessionPolicy.new(user, Session.new(seat:))
      expect(policy.check_in?).to be true
    end

    it "denies if user already has active session" do
      create(:session, user:, seat:)
      policy = SessionPolicy.new(user, Session.new(seat:))
      expect(policy.check_in?).to be false
    end
  end

  describe "#check_out?" do
    it "allows user to check out own session" do
      policy = SessionPolicy.new(user, session)
      expect(policy.check_out?).to be true
    end

    it "denies other user from checking out" do
      policy = SessionPolicy.new(other_user, session)
      expect(policy.check_out?).to be false
    end

    it "allows admin to check out any session" do
      policy = SessionPolicy.new(admin_user, session)
      expect(policy.check_out?).to be true
    end
  end

  describe "#view?" do
    it "allows user to view own session" do
      policy = SessionPolicy.new(user, session)
      expect(policy.view?).to be true
    end

    it "denies other user from viewing" do
      policy = SessionPolicy.new(other_user, session)
      expect(policy.view?).to be false
    end

    it "allows admin to view any session" do
      policy = SessionPolicy.new(admin_user, session)
      expect(policy.view?).to be true
    end
  end

  describe "#history?" do
    it "allows user to view own history" do
      policy = SessionPolicy.new(user, Session.new(user:))
      expect(policy.history?).to be true
    end

    it "allows admin to view all history" do
      policy = SessionPolicy.new(admin_user, Session.new)
      expect(policy.history?).to be true
    end
  end
end
