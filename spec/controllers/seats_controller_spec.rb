require 'rails_helper'

RSpec.describe SeatsController, type: :controller do
  let(:admin_user) { create(:user, :admin) }
  let(:manager) { create(:user, :manager) }
  let(:regular_user) { create(:user, :user) }
  let(:room) { create(:room, user: manager) }
  let(:seat) { create(:seat, room:) }

  describe '#show' do
    context 'when user is the room owner' do
      before { sign_in manager }

      it 'returns http success' do
        get :show, params: { room_id: room.id, id: seat.id }
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user has view permission' do
      before do
        create(:room_permission, room:, user: regular_user, permission_type: :view)
        sign_in regular_user
      end

      it 'returns http success' do
        get :show, params: { room_id: room.id, id: seat.id }
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user has no permission' do
      before { sign_in regular_user }

      it 'redirects when unauthorized' do
        get :show, params: { room_id: room.id, id: seat.id }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe '#create' do
    before { sign_in manager }

    it 'creates a new seat' do
      expect do
        post :create, params: { room_id: room.id, seat: { row_number: 1, column_number: 1, seat_type: :regular } }
      end.to change(Seat, :count).by(1)
    end

    it 'associates the seat with the room' do
      post :create, params: { room_id: room.id, seat: { row_number: 2, column_number: 3, seat_type: :accessible } }
      expect(Seat.last.room).to eq(room)
    end

    it 'redirects to the room show page' do
      post :create, params: { room_id: room.id, seat: { row_number: 1, column_number: 2, seat_type: :regular } }
      expect(response).to redirect_to(room_path(room))
    end

    context 'when user is not the owner' do
      before { sign_in regular_user }

      it 'redirects when unauthorized' do
        post :create, params: { room_id: room.id, seat: { row_number: 1, column_number: 1, seat_type: :regular } }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe '#update' do
    before { sign_in manager }

    it 'updates the seat' do
      patch :update, params: { room_id: room.id, id: seat.id, seat: { seat_type: :vip } }
      seat.reload
      expect(seat.vip?).to be true
    end

    context 'when user is not the owner' do
      before { sign_in regular_user }

      it 'redirects when unauthorized' do
        patch :update, params: { room_id: room.id, id: seat.id, seat: { seat_type: :vip } }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe '#destroy' do
    before { sign_in manager }

    it 'deletes the seat' do
      seat_id = seat.id
      delete :destroy, params: { room_id: room.id, id: seat_id }
      expect(Seat.find_by(id: seat_id)).to be_nil
    end

    it 'redirects to room show' do
      delete :destroy, params: { room_id: room.id, id: seat.id }
      expect(response).to redirect_to(room_path(room))
    end

    context 'when user is not the owner' do
      before { sign_in regular_user }

      it 'redirects when unauthorized' do
        delete :destroy, params: { room_id: room.id, id: seat.id }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe '#index' do
    context 'when user is the room owner' do
      before { sign_in manager }

      it 'returns http success' do
        get :index, params: { room_id: room.id }
        expect(response).to have_http_status(:success)
      end

      it 'lists all seats in the room' do
        create_list(:seat, 3, room:)
        get :index, params: { room_id: room.id }
        expect(assigns(:seats).count).to eq(3)
      end
    end

    context 'when user has edit permission' do
      before do
        create(:room_permission, room:, user: regular_user, permission_type: :edit)
        sign_in regular_user
      end

      it 'returns http success' do
        get :index, params: { room_id: room.id }
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user has no permission' do
      before { sign_in regular_user }

      it 'redirects when unauthorized' do
        get :index, params: { room_id: room.id }
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
