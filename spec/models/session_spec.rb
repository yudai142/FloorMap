require "rails_helper"

RSpec.describe Session, type: :model do
  describe "associations" do
    it "belongs to user" do
      session = build(:session)
      expect(session).to respond_to(:user)
    end

    it "belongs to seat" do
      session = build(:session)
      expect(session).to respond_to(:seat)
    end
  end

  describe "validations" do
    it "validates presence of user_id" do
      session = build(:session, user_id: nil)
      expect(session).not_to be_valid
      expect(session.errors[:user_id]).to be_present
    end

    it "validates presence of seat_id" do
      session = build(:session, seat_id: nil)
      expect(session).not_to be_valid
      expect(session.errors[:seat_id]).to be_present
    end

    it "validates presence of check_in_time" do
      session = build(:session, check_in_time: nil)
      expect(session).not_to be_valid
    end

    it "validates presence of status" do
      session = build(:session, status: nil)
      expect(session).not_to be_valid
    end
  end

  describe "enums" do
    it "has active status" do
      session = build(:session, status: :active)
      expect(session.active?).to be true
    end

    it "has completed status" do
      session = build(:session, :checked_out)
      expect(session.completed?).to be true
    end

    it "has expired status" do
      session = build(:session, :expired)
      expect(session.expired?).to be true
    end
  end

  describe "check-in/out logic" do
    let(:user) { create(:user) }
    let(:room) { create(:room) }
    let(:seat) { create(:seat, room:) }

    it "creates an active session on check-in" do
      session = create(:session, user:, seat:)
      expect(session.active?).to be true
      expect(session.check_in_time).to be_present
      expect(session.check_out_time).to be_nil
    end

    it "sets check_out_time on checkout" do
      session = create(:session, user:, seat:)
      session.update(check_out_time: Time.current, status: :completed)

      expect(session.completed?).to be true
      expect(session.check_out_time).to be_present
    end

    it "calculates duration between check-in and check-out" do
      check_in = 1.hour.ago
      check_out = Time.current

      session = create(:session, user:, seat:, check_in_time: check_in)
      session.update(check_out_time: check_out, status: :completed)

      duration = (check_out - check_in).to_i
      expect(session.duration).to eq(duration)
    end
  end

  describe "persistence" do
    let(:user) { create(:user) }
    let(:seat) { create(:seat) }

    it "creates and persists valid session" do
      session = create(:session, user:, seat:)
      expect(session).to be_persisted
      expect(session.user_id).to eq(user.id)
      expect(session.seat_id).to eq(seat.id)
    end

    it "associates session with both user and seat" do
      session = create(:session, user:, seat:)
      expect(session.user).to eq(user)
      expect(session.seat).to eq(seat)
    end
  end

  describe "scopes" do
    let(:user) { create(:user) }
    let(:seat) { create(:seat) }

    before do
      create(:session, user:, seat:, status: :active)
      create(:session, :checked_out, user:, seat:)
      create(:session, :expired, user:, seat:)
    end

    it "filters active sessions" do
      active = Session.active
      expect(active.count).to eq(1)
      expect(active.all? { |s| s.active? }).to be true
    end

    it "filters completed sessions" do
      completed = Session.completed
      expect(completed.count).to eq(1)
      expect(completed.all? { |s| s.completed? }).to be true
    end

    it "finds user's current session" do
      current = Session.where(user:).active.last
      expect(current).to be_present
      expect(current.active?).to be true
    end
  end
end
