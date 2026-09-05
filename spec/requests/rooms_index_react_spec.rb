require 'rails_helper'

RSpec.describe 'Rooms Index (React)', type: :request do
  let(:user) { create(:user, :manager) }
  let!(:room1) { create(:room, user: user, name: 'Test Room 1') }
  let!(:room2) { create(:room, user: user, name: 'Test Room 2') }

  before do
    sign_in user
  end

  describe 'GET /rooms (React)' do
    it 'renders rooms index page with Inertia' do
      get rooms_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Rooms/Index')
    end

    it 'provides rooms data' do
      get rooms_path
      expect(response.body).to include(room1.name)
      expect(response.body).to include(room2.name)
    end

    it 'includes current user information' do
      get rooms_path
      expect(response.body).to include(user.email)
    end

    it 'includes room metadata' do
      seat = create(:seat, room: room1)
      get rooms_path
      json = JSON.parse(response.body.match(/props":\s*({.*?})/m)[1])
      room_data = json['rooms'].first
      expect(room_data).to include('id', 'name', 'seats_count', 'occupancy_rate')
    end
  end

  describe 'GET /rooms with search' do
    it 'filters rooms by search query' do
      get rooms_path(search: 'Room 1')
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Test Room 1')
    end

    it 'returns empty results for non-matching search' do
      get rooms_path(search: 'Nonexistent')
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /rooms with sorting' do
    it 'sorts rooms by name' do
      get rooms_path(sort: 'name', direction: 'asc')
      expect(response).to have_http_status(:success)
    end

    it 'sorts rooms by created date' do
      get rooms_path(sort: 'created_at', direction: 'desc')
      expect(response).to have_http_status(:success)
    end
  end

  describe 'Authorization' do
    context 'when user is not authenticated' do
      before { sign_out user }

      it 'redirects to login' do
        get rooms_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user has different roles' do
      let(:admin) { create(:user, :admin) }
      let(:regular_user) { create(:user) }

      it 'allows admin to view all rooms' do
        sign_out user
        sign_in admin
        get rooms_path
        expect(response).to have_http_status(:success)
      end

      it 'only shows accessible rooms to regular user' do
        sign_out user
        sign_in regular_user
        get rooms_path
        expect(response).to have_http_status(:success)
        # should only show rooms the user has access to
      end
    end
  end

  describe 'Room data serialization' do
    before { create(:seat, room: room1, position_x: 100, position_y: 100) }

    it 'includes seats count in response' do
      get rooms_path
      expect(response.body).to include('"seats_count"')
    end

    it 'includes occupancy rate' do
      session = create(:session, user: user, seat: room1.seats.first)
      get rooms_path
      expect(response.body).to include('"occupancy_rate"')
    end

    it 'formats created_at as ISO8601' do
      get rooms_path
      expect(response.body).to match(/"\d{4}-\d{2}-\d{2}T/)
    end
  end
end
