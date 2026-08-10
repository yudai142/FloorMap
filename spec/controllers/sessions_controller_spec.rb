require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  let(:user) { create(:user) }
  let(:room) { create(:room) }
  let(:seat) { create(:seat, room:) }

  describe '#check_in' do
    context 'when user is authenticated' do
      before { sign_in user }

      it 'creates a new session' do
        expect {
          post :check_in, params: { seat_id: seat.id }
        }.to change(Session, :count).by(1)
      end

      it 'associates session with current user and seat' do
        post :check_in, params: { seat_id: seat.id }
        session = Session.last
        expect(session.user).to eq(user)
        expect(session.seat).to eq(seat)
      end

      it 'sets active status' do
        post :check_in, params: { seat_id: seat.id }
        session = Session.last
        expect(session.active?).to be true
      end

      it 'sets check_in_time' do
        post :check_in, params: { seat_id: seat.id }
        session = Session.last
        expect(session.check_in_time).to be_present
      end

      it 'redirects with success message' do
        post :check_in, params: { seat_id: seat.id }
        expect(response).to redirect_to(room_path(room))
        expect(flash[:notice]).to include('チェックインしました')
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to login' do
        post :check_in, params: { seat_id: seat.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user already has active session' do
      before do
        sign_in user
        create(:session, user:, seat:)
      end

      it 'returns error message' do
        post :check_in, params: { seat_id: seat.id }
        expect(flash[:alert]).to include('既にチェックイン済みです')
      end
    end
  end

  describe '#check_out' do
    before { sign_in user }

    it 'updates session to completed' do
      session = create(:session, user:, seat:)
      delete :check_out, params: { id: session.id }

      session.reload
      expect(session.completed?).to be true
      expect(session.check_out_time).to be_present
    end

    it 'redirects with success message' do
      session = create(:session, user:, seat:)
      delete :check_out, params: { id: session.id }

      expect(response).to redirect_to(room_path(room))
      expect(flash[:notice]).to include('チェックアウトしました')
    end

    context 'when session does not exist' do
      it 'returns error' do
        delete :check_out, params: { id: 99999 }
        expect(response).to redirect_to(room_path(room))
      end
    end
  end

  describe '#current_session' do
    before { sign_in user }

    context 'when user has active session' do
      it 'returns active session' do
        session = create(:session, user:, seat:)
        get :current_session

        expect(response).to have_http_status(:success)
        expect(assigns(:session)).to eq(session)
      end
    end

    context 'when user has no active session' do
      it 'returns nil' do
        get :current_session

        expect(response).to have_http_status(:success)
        expect(assigns(:session)).to be_nil
      end
    end
  end

  describe '#history' do
    before { sign_in user }

    it 'returns all sessions for current user' do
      create_list(:session, 3, user:)
      get :history

      expect(response).to have_http_status(:success)
      expect(assigns(:sessions).count).to eq(3)
    end

    it 'orders sessions by check_in_time descending' do
      session1 = create(:session, user:, check_in_time: 2.hours.ago)
      session2 = create(:session, user:, check_in_time: 1.hour.ago)
      session3 = create(:session, user:, check_in_time: Time.current)

      get :history
      sessions = assigns(:sessions)

      expect(sessions.first.id).to eq(session3.id)
      expect(sessions.last.id).to eq(session1.id)
    end
  end
end
