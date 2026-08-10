require 'rails_helper'

RSpec.describe RoomsController, type: :controller do
  let(:admin_user) { create(:user, :admin) }
  let(:manager) { create(:user, :manager) }
  let(:regular_user) { create(:user, :user) }
  let(:room) { create(:room, user: manager) }

  describe '#show' do
    context 'when user is the owner' do
      before { sign_in manager }

      it 'returns http success' do
        get :show, params: { id: room.id }
        expect(response).to have_http_status(:success)
      end

      it 'assigns the room' do
        get :show, params: { id: room.id }
        expect(assigns(:room)).to eq(room)
      end
    end

    context 'when user has permission' do
      before do
        create(:room_permission, room: room, user: regular_user)
        sign_in regular_user
      end

      it 'returns http success' do
        get :show, params: { id: room.id }
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user has no permission' do
      before { sign_in regular_user }

      it 'raises Pundit::NotAuthorizedError' do
        expect { get :show, params: { id: room.id } }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe '#create' do
    before { sign_in manager }

    it 'creates a new room' do
      expect {
        post :create, params: { room: { name: 'New Room', description: 'Test description' } }
      }.to change(Room, :count).by(1)
    end

    it 'associates the room with the current user' do
      post :create, params: { room: { name: 'New Room', description: 'Test description' } }
      expect(Room.last.user).to eq(manager)
    end

    it 'redirects to the room show page' do
      post :create, params: { room: { name: 'New Room', description: 'Test description' } }
      expect(response).to redirect_to(Room.last)
    end
  end

  describe '#update' do
    before { sign_in manager }

    it 'updates the room' do
      patch :update, params: { id: room.id, room: { name: 'Updated Name' } }
      room.reload
      expect(room.name).to eq('Updated Name')
    end

    context 'when user is not the owner' do
      before { sign_in regular_user }

      it 'raises Pundit::NotAuthorizedError' do
        expect {
          patch :update, params: { id: room.id, room: { name: 'Updated Name' } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe '#destroy' do
    before { sign_in manager }

    it 'deletes the room' do
      room_id = room.id
      delete :destroy, params: { id: room_id }
      expect(Room.find_by(id: room_id)).to be_nil
    end

    it 'redirects to rooms index' do
      delete :destroy, params: { id: room.id }
      expect(response).to redirect_to(rooms_url)
    end

    context 'when user is not the owner' do
      before { sign_in regular_user }

      it 'raises Pundit::NotAuthorizedError' do
        expect {
          delete :destroy, params: { id: room.id }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
