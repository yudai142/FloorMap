require 'rails_helper'

RSpec.describe 'Canvas Editor', type: :request do
  let(:user) { create(:user, :manager) }
  let(:room) { create(:room, user: user) }

  describe 'GET /rooms/:share_token/canvas_editor' do
    context 'when user is owner' do
      before do
        sign_in user
      end

      it 'renders canvas editor page' do
        get "/rooms/#{room.share_token}/canvas_editor"
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Canvas')
      end

      it 'provides initial props' do
        get "/rooms/#{room.share_token}/canvas_editor"
        expect(response.body).to include(room.name)
      end

      it 'includes canvas-related styles and scripts' do
        get "/rooms/#{room.share_token}/canvas_editor"
        expect(response.body).to include('application')
      end

      it 'includes canvas dimensions in props' do
        room.update(width: 1200, height: 800)
        get "/rooms/#{room.share_token}/canvas_editor"
        expect(response.body).to include('1200')
        expect(response.body).to include('800')
      end

      it 'returns default dimensions when not set' do
        room.update(width: nil, height: nil)
        get "/rooms/#{room.share_token}/canvas_editor"
        expect(response.body).to include('1000')
        expect(response.body).to include('700')
      end
    end

    context 'when user is not owner' do
      let(:other_user) { create(:user, :manager) }

      before do
        sign_in other_user
      end

      it 'denies access' do
        get "/rooms/#{room.share_token}/canvas_editor"
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'PATCH /rooms/:share_token/floor_plan' do
    let(:floor_plan_data) do
      [
        { type: 'rectangle', x: 10, y: 10, width: 100, height: 80, color: '#3b82f6', lineWidth: 2 },
        { type: 'circle', x: 150, y: 50, width: 40, height: 40, color: '#ef4444', lineWidth: 1 }
      ]
    end

    context 'when user is owner' do
      before do
        sign_in user
      end

      it 'saves floor plan data' do
        patch "/rooms/#{room.share_token}/floor_plan", params: { room: { floor_plan_data: floor_plan_data } }
        expect(response).to have_http_status(:ok)
        saved_data = room.reload.floor_plan_data
        expect(saved_data.length).to eq(2)
        expect(saved_data.first['type']).to eq('rectangle')
      end

      it 'returns updated floor plan data' do
        patch "/rooms/#{room.share_token}/floor_plan", params: { room: { floor_plan_data: floor_plan_data } }
        json = JSON.parse(response.body)
        expect(json['floor_plan_data']).to be_present
      end

      it 'handles empty floor plan' do
        patch "/rooms/#{room.share_token}/floor_plan", params: { room: { floor_plan_data: [] } }
        expect(response).to have_http_status(:ok)
        expect(room.reload.floor_plan_data).to eq([])
      end
    end

    context 'when user is not owner' do
      let(:other_user) { create(:user, :manager) }

      before do
        sign_in other_user
      end

      it 'denies access' do
        patch "/rooms/#{room.share_token}/floor_plan", params: { room: { floor_plan_data: floor_plan_data } }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'GET /rooms/:share_token/canvas_data' do
    let!(:seat1) { create(:seat, room: room, position_x: 100, position_y: 150) }
    let!(:seat2) { create(:seat, room: room, position_x: 250, position_y: 150) }

    it 'returns canvas data' do
      get "/rooms/#{room.share_token}/canvas_data"
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['room']).to include('id', 'name', 'description')
      expect(json['seats']).to be_an(Array)
      expect(json).to have_key('floor_plan_data')
    end

    it 'includes seat position data' do
      get "/rooms/#{room.share_token}/canvas_data"
      json = JSON.parse(response.body)
      seat_data = json['seats'].first
      expect(seat_data).to include('id', 'position_x', 'position_y')
    end

    it 'includes floor plan data' do
      room.update(floor_plan_data: [ { type: 'rectangle', x: 0, y: 0 } ])
      get "/rooms/#{room.share_token}/canvas_data"
      json = JSON.parse(response.body)
      expect(json['floor_plan_data']).to eq([ { 'type' => 'rectangle', 'x' => 0, 'y' => 0 } ])
    end
  end
end
