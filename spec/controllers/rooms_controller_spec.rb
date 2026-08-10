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

      it 'redirects when unauthorized' do
        get :show, params: { id: room.id }
        expect(response).to redirect_to(root_path)
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

      it 'redirects when unauthorized' do
        patch :update, params: { id: room.id, room: { name: 'Updated Name' } }
        expect(response).to redirect_to(root_path)
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

      it 'redirects when unauthorized' do
        delete :destroy, params: { id: room.id }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe '#index' do
    before { sign_in regular_user }

    it 'returns accessible rooms' do
      get :index
      expect(response).to have_http_status(:ok)
    end

    context 'with search parameter' do
      it 'filters rooms by name' do
        meeting_room = create(:room, name: 'Meeting Room', user: manager)
        office_room = create(:room, name: 'Office', user: manager)

        get :index, params: { search: 'Meeting' }
        expect(assigns(:rooms)).to include(meeting_room)
      end

      it 'filters rooms by description' do
        room1 = create(:room, name: 'Room 1', description: 'Large conference', user: manager)
        room2 = create(:room, name: 'Room 2', description: 'Small office', user: manager)

        get :index, params: { search: 'conference' }
        expect(assigns(:rooms)).to include(room1)
      end
    end

    context 'with sort parameter' do
      it 'sorts rooms by name ascending' do
        create(:room, name: 'Zebra Room', user: manager)
        create(:room, name: 'Alpha Room', user: manager)

        get :index, params: { sort: 'name', direction: 'asc' }
        rooms = assigns(:rooms)
        expect(rooms.first.name).to start_with('Alpha')
      end

      it 'sorts rooms by created_at descending' do
        room1 = create(:room, name: 'Room 1', user: manager)
        room2 = create(:room, name: 'Room 2', user: manager)

        get :index, params: { sort: 'created_at', direction: 'desc' }
        rooms = assigns(:rooms)
        expect(rooms.first.id).to eq(room2.id)
      end
    end

    context 'with filter by owner' do
      it 'filters rooms by owner_id' do
        manager_room = create(:room, user: manager)
        other_manager = create(:user, :manager)
        other_room = create(:room, user: other_manager)

        get :index, params: { owner_id: manager.id }
        expect(assigns(:rooms)).to include(manager_room)
      end
    end
  end
end
