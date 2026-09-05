require 'rails_helper'

RSpec.describe 'Canvas Editor', type: :request do
  let(:user) { create(:user, :manager) }
  let(:room) { create(:room, user: user) }

  before do
    sign_in user
  end

  after do
    sign_out user
  end

  describe 'GET /rooms/:id/canvas_editor' do
    context 'when user is owner' do
      it 'renders canvas editor page' do
        get canvas_editor_room_path(room)
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Canvas')
      end

      it 'provides initial props' do
        get canvas_editor_room_path(room)
        expect(response.body).to include(room.name)
      end

      it 'includes canvas-related styles and scripts' do
        get canvas_editor_room_path(room)
        expect(response.body).to include('application')
      end
    end

    context 'when user is not owner' do
      let(:other_user) { create(:user, :manager) }

      it 'denies access' do
        sign_out user
        sign_in other_user
        get canvas_editor_room_path(room)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'PATCH /rooms/:id/floor_plan' do
    let(:floor_plan_data) do
      [
        { type: 'rectangle', x: 10, y: 10, width: 100, height: 80, color: '#3b82f6', lineWidth: 2 },
        { type: 'circle', x: 150, y: 50, width: 40, height: 40, color: '#ef4444', lineWidth: 1 }
      ]
    end

    context 'when user is owner' do
      it 'saves floor plan data' do
        patch floor_plan_room_path(room), params: { room: { floor_plan_data: floor_plan_data.to_json } }
        expect(response).to have_http_status(:ok)
        # JSON パラメータは文字列値として保存される
        saved_data = room.reload.floor_plan_data
        expect(saved_data.length).to eq(2)
        expect(saved_data.first['type']).to eq('rectangle')
      end

      it 'returns updated floor plan data' do
        patch floor_plan_room_path(room), params: { room: { floor_plan_data: floor_plan_data } }
        json = JSON.parse(response.body)
        expect(json['floor_plan_data']).to be_present
      end

      it 'handles empty floor plan' do
        patch floor_plan_room_path(room), params: { room: { floor_plan_data: [] } }
        expect(response).to have_http_status(:ok)
        expect(room.reload.floor_plan_data).to eq([])
      end
    end

    context 'when user is not owner' do
      let(:other_user) { create(:user, :manager) }

      it 'denies access' do
        sign_out user
        sign_in other_user
        patch floor_plan_room_path(room), params: { room: { floor_plan_data: floor_plan_data } }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'GET /rooms/:id/canvas_data' do
    let!(:seat1) { create(:seat, room: room, position_x: 100, position_y: 150) }
    let!(:seat2) { create(:seat, room: room, position_x: 250, position_y: 150) }

    context 'when user has permission' do
      it 'returns canvas data' do
        get canvas_data_room_path(room)
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json['room']).to include('id', 'name', 'description')
        expect(json['seats']).to be_an(Array)
        expect(json).to have_key('floor_plan_data')
      end

      it 'includes seat position data' do
        get canvas_data_room_path(room)
        json = JSON.parse(response.body)
        seat_data = json['seats'].first
        expect(seat_data).to include('id', 'position_x', 'position_y')
      end

      it 'includes floor plan data' do
        room.update(floor_plan_data: [{ type: 'rectangle', x: 0, y: 0 }])
        get canvas_data_room_path(room)
        json = JSON.parse(response.body)
        expect(json['floor_plan_data']).to eq([{ 'type' => 'rectangle', 'x' => 0, 'y' => 0 }])
      end
    end
  end
end
