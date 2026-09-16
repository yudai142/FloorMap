require 'rails_helper'

RSpec.describe CheckRoomAutoCheckoutJob, type: :job do
  describe '#perform' do
    let(:user) { create(:user) }
    let(:room) { create(:room, user: user) }

    context 'when room auto_checkout is enabled and time matches' do
      before do
        room.update(auto_checkout_enabled: true, auto_checkout_time: Time.current.strftime("%H:%M"))
      end

      it 'checks out all active sessions in the room' do
        seat1 = create(:seat, room: room)
        seat2 = create(:seat, room: room)
        session1 = create(:session, seat: seat1, status: 'active')
        session2 = create(:session, seat: seat2, status: 'active')

        expect {
          CheckRoomAutoCheckoutJob.new.perform
        }.to change { session1.reload.status }.from('active').to('checked_out')
          .and change { session2.reload.status }.from('active').to('checked_out')
      end
    end

    context 'when auto_checkout is disabled' do
      before do
        room.update(auto_checkout_enabled: false, auto_checkout_time: Time.current.strftime("%H:%M"))
      end

      it 'does not check out sessions' do
        seat = create(:seat, room: room)
        session = create(:session, seat: seat, status: 'active')

        CheckRoomAutoCheckoutJob.new.perform

        expect(session.reload.status).to eq('active')
      end
    end

    context 'when time does not match' do
      before do
        room.update(auto_checkout_enabled: true, auto_checkout_time: '23:59')
      end

      it 'does not check out sessions' do
        seat = create(:seat, room: room)
        session = create(:session, seat: seat, status: 'active')

        CheckRoomAutoCheckoutJob.new.perform

        expect(session.reload.status).to eq('active')
      end
    end
  end
end
