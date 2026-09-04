require 'rails_helper'

RSpec.describe Session, type: :model do
  let(:user) { create(:user) }
  let(:manager) { create(:user, :manager) }
  let(:room) { create(:room, user: manager) }
  let(:seat) { create(:seat, room: room) }

  describe 'broadcasting' do
    it 'broadcasts seat_updated when session is created', truncation: true do
      expect {
        create(:session, user: user, seat: seat)
      }.to have_broadcasted_to(room).from_channel(RoomsChannel).with(hash_including(
        type: 'seat_updated'
      ))
    end

    it 'broadcasts seat_updated when session status changes', truncation: true do
      session = create(:session, user: user, seat: seat)

      expect {
        session.check_out!
      }.to have_broadcasted_to(room).from_channel(RoomsChannel).with(hash_including(
        type: 'seat_updated'
      ))
    end

    it 'includes active user session in canvas_data' do
      session = create(:session, user: user, seat: seat)

      expect(seat.canvas_data[:session]).to eq({
        id: session.id,
        user_id: session.user_id,
        type: "user"
      })
    end

    it 'includes active visitor session in canvas_data' do
      visitor = create(:visitor)
      session = create(:session, visitor: visitor, user_id: nil, seat: seat)

      expect(seat.canvas_data[:session]).to include({
        id: session.id,
        visitor_id: visitor.id,
        type: "visitor",
        name: visitor.display_name
      })
    end

    it 'returns nil session when no active session' do
      seat_without_session = create(:seat, room: room)

      expect(seat_without_session.canvas_data[:session]).to be_nil
    end
  end
end
