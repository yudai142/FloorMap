require 'rails_helper'

RSpec.describe 'Seat Positions API', type: :request do
  let(:manager) { create(:user, :manager) }
  let(:room) { create(:room, user: manager) }
  let(:seat1) { create(:seat, room: room) }
  let(:seat2) { create(:seat, room: room) }

  before { sign_in manager }

  describe 'PATCH /rooms/:room_id/seats/:id/position' do
    it 'updates seat position' do
      patch position_room_seat_path(room, seat1), params: {
        seat: { position_x: 100, position_y: 200 }
      }

      expect(response).to have_http_status(:ok)
      seat1.reload
      expect(seat1.position_x).to eq(100)
      expect(seat1.position_y).to eq(200)
    end

    it 'returns updated seat as JSON' do
      patch position_room_seat_path(room, seat1), params: {
        seat: { position_x: 150, position_y: 250 }
      }

      expect(response.content_type).to include('application/json')
      json = JSON.parse(response.body)
      expect(json['position_x']).to eq(150)
      expect(json['position_y']).to eq(250)
    end

    it 'denies access if not owner' do
      other_user = create(:user, :manager)
      sign_in other_user

      patch position_room_seat_path(room, seat1), params: {
        seat: { position_x: 100, position_y: 200 }
      }

      expect(response).to redirect_to(root_path)
    end
  end

  describe 'PATCH /rooms/:room_id/seats/batch_position' do
    it 'updates multiple seat positions' do
      patch batch_position_room_seats_path(room), params: {
        positions: [
          { id: seat1.id, x: 100, y: 200 },
          { id: seat2.id, x: 300, y: 400 }
        ]
      }

      expect(response).to have_http_status(:ok)
      seat1.reload
      seat2.reload
      expect(seat1.position_x).to eq(100)
      expect(seat1.position_y).to eq(200)
      expect(seat2.position_x).to eq(300)
      expect(seat2.position_y).to eq(400)
    end

    it 'returns updated seats as JSON' do
      patch batch_position_room_seats_path(room), params: {
        positions: [
          { id: seat1.id, x: 100, y: 200 },
          { id: seat2.id, x: 300, y: 400 }
        ]
      }

      expect(response.content_type).to include('application/json')
      json = JSON.parse(response.body)
      expect(json.length).to eq(2)
    end
  end

  describe 'GET /rooms/:room_id/canvas_data' do
    before do
      seat1.update(position_x: 100, position_y: 200)
      seat2.update(position_x: 300, position_y: 400)
    end

    it 'returns room with seat positions' do
      get room_canvas_data_path(room)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['room']['name']).to eq(room.name)
      expect(json['seats'].length).to eq(2)
      expect(json['seats'][0]['position_x']).to eq(100)
    end

    it 'includes active sessions' do
      session = create(:session, seat: seat1, status: :active)

      get room_canvas_data_path(room)

      json = JSON.parse(response.body)
      seat_data = json['seats'].find { |s| s['id'] == seat1.id }
      expect(seat_data['session']['user_id']).to eq(session.user_id)
    end
  end
end
