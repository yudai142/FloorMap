require 'rails_helper'

RSpec.describe Visitor, type: :model do
  describe 'associations' do
    it 'has many sessions with dependent destroy' do
      visitor = create(:visitor)
      room = create(:room)
      seat = create(:seat, room: room)
      session = create(:session, visitor: visitor, seat: seat)

      expect {
        visitor.destroy
      }.to change(Session, :count).by(-1)
    end
  end

  describe 'validations' do
    context 'presence' do
      it 'requires session_id' do
        visitor = Visitor.new(nickname: "Test")
        expect(visitor).not_to be_valid
        expect(visitor.errors[:session_id]).to be_present
      end

      it 'requires nickname' do
        visitor = Visitor.new(session_id: "abc123")
        expect(visitor).not_to be_valid
        expect(visitor.errors[:nickname]).to be_present
      end
    end

    context 'uniqueness' do
      it 'enforces unique session_id' do
        create(:visitor, session_id: "unique_123")
        visitor = build(:visitor, session_id: "unique_123")
        expect(visitor).not_to be_valid
        expect(visitor.errors[:session_id]).to be_present
      end
    end

    context 'length' do
      it 'allows nickname up to 255 characters' do
        visitor = build(:visitor, nickname: "a" * 255)
        expect(visitor).to be_valid
      end

      it 'rejects nickname longer than 255 characters' do
        visitor = build(:visitor, nickname: "a" * 256)
        expect(visitor).not_to be_valid
      end
    end
  end

  describe 'attributes' do
    let(:visitor) { create(:visitor) }

    it 'has session_id' do
      expect(visitor.session_id).to be_present
    end

    it 'has nickname' do
      expect(visitor.nickname).to be_present
    end

    it 'has created_at timestamp' do
      expect(visitor.created_at).to be_present
    end
  end

  describe 'scopes' do
    describe '.expired' do
      it 'returns visitors older than 24 hours' do
        old_visitor = create(:visitor, created_at: 25.hours.ago)
        recent_visitor = create(:visitor, created_at: 1.hour.ago)

        expect(Visitor.expired).to include(old_visitor)
        expect(Visitor.expired).not_to include(recent_visitor)
      end
    end

    describe '.recent' do
      it 'returns visitors ordered by creation date DESC' do
        visitor1 = create(:visitor, created_at: 1.hour.ago)
        visitor2 = create(:visitor, created_at: 2.hours.ago)

        expect(Visitor.recent).to eq([visitor1, visitor2])
      end
    end
  end

  describe 'instance methods' do
    describe '#active?' do
      it 'returns true if visitor has active sessions' do
        visitor = create(:visitor)
        room = create(:room)
        seat = create(:seat, room: room)
        create(:session, visitor: visitor, seat: seat, status: :active)

        expect(visitor.active?).to be true
      end

      it 'returns false if no active sessions' do
        visitor = create(:visitor)
        expect(visitor.active?).to be false
      end
    end

    describe '#current_seat' do
      it 'returns the seat of the active session' do
        visitor = create(:visitor)
        room = create(:room)
        seat = create(:seat, room: room)
        create(:session, visitor: visitor, seat: seat, status: :active)

        expect(visitor.current_seat).to eq(seat)
      end

      it 'returns nil if no active session' do
        visitor = create(:visitor)
        expect(visitor.current_seat).to be_nil
      end
    end

    describe '#check_in_to_seat' do
      it 'creates a new session for the seat' do
        visitor = create(:visitor)
        room = create(:room)
        seat = create(:seat, room: room)

        expect {
          visitor.check_in_to_seat(seat)
        }.to change(Session, :count).by(1)
      end

      it 'returns false for nil seat' do
        visitor = create(:visitor)
        expect(visitor.check_in_to_seat(nil)).to be false
      end
    end

    describe '#check_out' do
      it 'completes the active session' do
        visitor = create(:visitor)
        room = create(:room)
        seat = create(:seat, room: room)
        session = create(:session, visitor: visitor, seat: seat, status: :active)

        visitor.check_out

        session.reload
        expect(session.status).to eq("completed")
      end

      it 'returns false if no active session' do
        visitor = create(:visitor)
        expect(visitor.check_out).to be false
      end
    end

    describe '#display_name' do
      it 'returns the nickname' do
        visitor = create(:visitor, nickname: "John")
        expect(visitor.display_name).to eq("John")
      end
    end
  end
end
