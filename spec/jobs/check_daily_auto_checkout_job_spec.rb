require 'rails_helper'

RSpec.describe CheckDailyAutoCheckoutJob, type: :job do
  let(:user) { create(:user) }
  let(:manager) { create(:user, :manager) }
  let(:room) { create(:room, user: manager) }
  let(:seat) { create(:seat, room: room) }

  describe '#perform' do
    context 'with active sessions that exceeded timeout' do
      it 'checks out expired sessions' do
        # Create an active session that exceeded the timeout threshold
        session = create(:session, user: user, seat: seat, status: :active, check_in_time: 25.hours.ago)

        expect {
          CheckDailyAutoCheckoutJob.perform_now
        }.to change { session.reload.status }.from('active').to('timed_out')
      end

      it 'sets check_out_time when checking out' do
        session = create(:session, user: user, seat: seat, status: :active, check_in_time: 25.hours.ago)

        CheckDailyAutoCheckoutJob.perform_now

        expect(session.reload.check_out_time).not_to be_nil
      end

      it 'handles multiple expired sessions' do
        session1 = create(:session, user: user, seat: seat, status: :active, check_in_time: 25.hours.ago)
        session2 = create(:session, user: user, seat: create(:seat, room: room), status: :active, check_in_time: 30.hours.ago)

        expect {
          CheckDailyAutoCheckoutJob.perform_now
        }.to change { Session.where(status: :timed_out).count }.by(2)
      end
    end

    context 'with active sessions that have not exceeded timeout' do
      it 'does not check out recent sessions' do
        session = create(:session, user: user, seat: seat, status: :active, check_in_time: 5.hours.ago)

        expect {
          CheckDailyAutoCheckoutJob.perform_now
        }.not_to change { session.reload.status }
      end
    end

    context 'with already completed sessions' do
      it 'ignores completed sessions' do
        session = create(:session, user: user, seat: seat, status: :checked_out, check_in_time: 25.hours.ago)

        expect {
          CheckDailyAutoCheckoutJob.perform_now
        }.not_to change { session.reload.status }
      end
    end

    context 'job execution logging' do
      it 'creates a job log record' do
        expect {
          CheckDailyAutoCheckoutJob.perform_now
        }.to change { JobLog.where(job_type: 'CheckDailyAutoCheckoutJob').count }
      end

      it 'records the number of checked out sessions' do
        create(:session, user: user, seat: seat, status: :active, check_in_time: 25.hours.ago)
        create(:session, user: user, seat: create(:seat, room: room), status: :active, check_in_time: 30.hours.ago)

        CheckDailyAutoCheckoutJob.perform_now

        log = JobLog.where(job_type: 'CheckDailyAutoCheckoutJob').last
        expect(log.metadata['checked_out_count']).to eq(2)
      end
    end
  end
end
