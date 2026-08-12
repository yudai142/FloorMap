require 'rails_helper'

RSpec.describe 'Check-in / Check-out Functionality', type: :request do
  describe 'Phase 4: チェックイン・チェックアウト機能' do
    let(:user) { create(:user, :manager) }
    let(:room) { create(:room, user: user) }
    let(:seat) { create(:seat, room: room) }

    before do
      sign_in user
    end

    after do
      sign_out user
    end

    describe 'Check-in Feature' do
      describe 'GET /sessions/check_in' do
        it 'displays check-in form with available seats' do
          get check_in_form_sessions_path(room_id: room.id)
          expect(response).to have_http_status(:success)
          expect(response.body).to include(seat.seat_identifier)
        end

        it 'filters seats by room' do
          room2 = create(:room, user: user)
          seat2 = create(:seat, room: room2)

          get check_in_form_sessions_path(room_id: room.id)
          expect(response.body).to include(seat.seat_identifier)
          expect(response.body).not_to include(seat2.seat_identifier)
        end

        it 'shows current user sessions' do
          active_session = create(:session, user: user, seat: seat)
          get check_in_form_sessions_path
          expect(response.body).to include(active_session.seat.seat_identifier)
        end
      end

      describe 'POST /sessions/check_in' do
        it 'creates a new session for the seat' do
          expect {
            post check_in_sessions_path, params: { seat_id: seat.id }
          }.to change(Session, :count).by(1)

          session = Session.last
          expect(session.user_id).to eq(user.id)
          expect(session.seat_id).to eq(seat.id)
          expect(session.status).to eq("active")
          expect(session.check_in_time).to be_present
        end

        it 'validates seat exists' do
          post check_in_sessions_path, params: { seat_id: 99999 }
          expect(response).to have_http_status(:not_found)
        end

        it 'records check-in timestamp' do
          before_time = Time.current
          post check_in_sessions_path, params: { seat_id: seat.id }
          after_time = Time.current

          session = Session.last
          expect(session.check_in_time).to be_between(before_time, after_time)
        end
      end
    end

    describe 'Check-out Feature' do
      describe 'DELETE /sessions/check_out' do
        it 'ends the current session' do
          session = create(:session, user: user, seat: seat, status: :active)

          delete check_out_sessions_path, params: { session_id: session.id }

          session.reload
          expect(session.status).to eq("checked_out")
          expect(session.check_out_time).to be_present
        end

        it 'validates session exists' do
          delete check_out_sessions_path, params: { session_id: 99999 }
          expect(response).to have_http_status(:not_found)
        end

        it 'records check-out timestamp' do
          session = create(:session, user: user, seat: seat, status: :active)
          before_time = Time.current

          delete check_out_sessions_path, params: { session_id: session.id }

          after_time = Time.current
          session.reload
          expect(session.check_out_time).to be_between(before_time, after_time)
        end

        it 'prevents checkout of other users session' do
          other_user = create(:user)
          session = create(:session, user: other_user, seat: seat, status: :active)

          delete check_out_sessions_path, params: { session_id: session.id }
          expect(response).to have_http_status(:forbidden)
        end

        it 'allows admin to checkout any session' do
          admin_user = create(:user, :admin)
          sign_in admin_user
          session = create(:session, user: user, seat: seat, status: :active)

          delete check_out_sessions_path, params: { session_id: session.id }
          expect(response).to have_http_status(:redirect)
        end
      end

      describe 'GET /sessions/history' do
        it 'displays user session history' do
          completed_session = create(:session, :checked_out, user: user, seat: seat)

          get sessions_history_path
          expect(response).to have_http_status(:success)
          expect(response.body).to include(seat.seat_identifier)
        end

        it 'shows session duration' do
          session = create(:session, :checked_out, user: user, seat: seat,
                          check_in_time: 2.hours.ago, check_out_time: 1.hour.ago)

          get sessions_history_path
          expect(response.body).to include("1h 0m")
        end

        it 'only shows completed sessions' do
          active_session = create(:session, user: user, seat: seat, status: :active)
          completed_session = create(:session, :checked_out, user: user, seat: seat)

          get sessions_history_path
          expect(response.body).to include(completed_session.seat.seat_identifier)
          expect(response.body).not_to include(active_session.seat.seat_identifier)
        end
      end
    end

    describe 'Session Management' do
      describe 'Session Model' do
        it 'validates seat_id presence' do
          session = Session.new(user_id: user.id, check_in_time: Time.current)
          expect(session).not_to be_valid
          expect(session.errors[:seat_id]).to be_present
        end

        it 'validates user or visitor presence' do
          session = Session.new(seat_id: seat.id, check_in_time: Time.current)
          expect(session).not_to be_valid
          expect(session.errors[:base]).to include("ユーザーまたは訪問者のいずれかが必要です")
        end

        it 'validates status enum' do
          session = create(:session, user: user, seat: seat)
          expect(session.status).to eq("active")

          session.status = :checked_out
          expect(session).to be_valid
        end

        it 'requires check_in_time' do
          session = Session.new(user_id: user.id, seat_id: seat.id)
          expect(session).not_to be_valid
        end

        it 'allows nil check_out_time for active sessions' do
          session = create(:session, user: user, seat: seat, check_out_time: nil)
          expect(session).to be_valid
          expect(session.check_out_time).to be_nil
        end
      end

      describe 'Session Scopes' do
        it 'active scope returns only active sessions' do
          active = create(:session, user: user, seat: seat, status: :active)
          completed = create(:session, :checked_out, user: user, seat: seat)

          expect(Session.active).to include(active)
          expect(Session.active).not_to include(completed)
        end

        it 'completed scope returns checked_out and timed_out sessions' do
          active = create(:session, user: user, seat: seat, status: :active)
          checked_out = create(:session, :checked_out, user: user, seat: seat)
          timed_out = create(:session, :timed_out, user: user, seat: seat)

          expect(Session.completed).to include(checked_out, timed_out)
          expect(Session.completed).not_to include(active)
        end

        it 'by_user scope filters by user_id' do
          other_user = create(:user)
          session = create(:session, user: user, seat: seat)
          other_session = create(:session, user: other_user, seat: seat)

          expect(Session.by_user(user)).to include(session)
          expect(Session.by_user(user)).not_to include(other_session)
        end

        it 'by_date scope filters by date' do
          today = create(:session, user: user, seat: seat)
          yesterday = create(:session, user: user, seat: seat, created_at: 1.day.ago)

          expect(Session.by_date(Date.today)).to include(today)
          expect(Session.by_date(Date.today)).not_to include(yesterday)
        end

        it 'recent scope returns sessions in descending order' do
          session1 = create(:session, user: user, seat: seat, created_at: 1.hour.ago)
          session2 = create(:session, user: user, seat: seat, created_at: 2.hours.ago)

          expect(Session.recent.first).to eq(session1)
          expect(Session.recent.last).to eq(session2)
        end
      end

      describe 'Session Methods' do
        it 'calculates duration between check_in and check_out' do
          session = create(:session, user: user, seat: seat,
                          check_in_time: 1.hour.ago, check_out_time: 10.minutes.ago)

          duration = session.duration
          expect(duration).to be_between(3000, 3600)
        end

        it 'calculates duration until now for active sessions' do
          session = create(:session, user: user, seat: seat, check_in_time: 10.minutes.ago)

          duration = session.duration
          expect(duration).to be_between(500, 700)
        end
      end
    end

    describe 'Authorization' do
      let(:other_user) { create(:user) }

      it 'allows user to check-in themselves' do
        post check_in_sessions_path, params: { seat_id: seat.id }
        session = Session.last
        expect(session.user_id).to eq(user.id)
      end

      it 'prevents user from checking out others session' do
        sign_out user
        sign_in other_user

        session = create(:session, user: user, seat: seat, status: :active)
        delete check_out_sessions_path, params: { session_id: session.id }

        expect(response).to have_http_status(:forbidden)
        expect(session.reload.status).to eq("active")
      end

      it 'allows admin to manage all sessions' do
        admin = create(:user, :admin)
        sign_out user
        sign_in admin

        session = create(:session, user: user, seat: seat, status: :active)
        delete check_out_sessions_path, params: { session_id: session.id }

        expect(response).to have_http_status(:redirect)
        expect(session.reload.status).to eq("checked_out")
      end
    end

    describe 'Real-time Updates' do
      it 'broadcasts check-in event' do
        allow(ActionCable.server).to receive(:broadcast)

        post check_in_sessions_path, params: { seat_id: seat.id }

        expect(ActionCable.server).to have_received(:broadcast).with(
          "room_#{room.id}",
          hash_including(type: 'check_in')
        )
      end

      it 'broadcasts check-out event' do
        allow(ActionCable.server).to receive(:broadcast)

        session = create(:session, user: user, seat: seat, status: :active)
        delete check_out_sessions_path, params: { session_id: session.id }

        expect(ActionCable.server).to have_received(:broadcast).with(
          "room_#{room.id}",
          hash_including(type: 'check_out')
        )
      end
    end

    describe 'Auto Check-out' do
      pending 'auto checks out inactive sessions' do
        # Should automatically check-out after inactivity period
        # Implemented in Phase 9: 自動チェックアウトジョブ
      end

      pending 'records auto check-out status' do
        # Should mark session as :timed_out
      end

      pending 'sends notification before auto check-out' do
        # Should notify user before auto check-out
      end
    end
  end
end
