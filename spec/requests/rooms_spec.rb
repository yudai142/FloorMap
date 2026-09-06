require 'rails_helper'

RSpec.describe 'Rooms', type: :request do
  let(:user) { create(:user, :manager) }
  let(:room) { create(:room, user: user, width: 1000, height: 700) }

  before do
    sign_in user
  end

  describe 'PATCH /rooms/:share_token' do
    context 'when updating room attributes (HTML response)' do
      it 'updates room name and description' do
        patch "/rooms/#{room.share_token}", params: {
          room: { name: 'New Room Name', description: 'New Description' }
        }
        expect(response).to have_http_status(:redirect)
        expect(room.reload.name).to eq('New Room Name')
        expect(room.reload.description).to eq('New Description')
      end

      it 'updates canvas width and height' do
        patch "/rooms/#{room.share_token}", params: {
          room: { width: 1200, height: 800 }
        }
        expect(response).to have_http_status(:redirect)
        expect(room.reload.width).to eq(1200)
        expect(room.reload.height).to eq(800)
      end

      it 'updates all attributes together' do
        patch "/rooms/#{room.share_token}", params: {
          room: { name: 'Updated', description: 'Updated Desc', width: 1100, height: 750 }
        }
        room.reload
        expect(room.name).to eq('Updated')
        expect(room.description).to eq('Updated Desc')
        expect(room.width).to eq(1100)
        expect(room.height).to eq(750)
      end
    end

    context 'when sending JSON request' do
      it 'responds with JSON containing updated attributes' do
        patch "/rooms/#{room.share_token}.json", params: {
          room: { width: 1300, height: 900 }
        }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['width']).to eq(1300)
        expect(json['height']).to eq(900)
        expect(json).to include('id', 'share_token', 'name')
      end

      it 'persists canvas size changes to database' do
        patch "/rooms/#{room.share_token}.json", params: {
          room: { width: 1400, height: 1000 }
        }

        expect(room.reload.width).to eq(1400)
        expect(room.reload.height).to eq(1000)
      end
    end

    context 'when user is not owner' do
      let(:other_user) { create(:user, :manager) }

      before do
        sign_out user
        sign_in other_user
      end

      it 'denies access' do
        patch "/rooms/#{room.share_token}", params: {
          room: { width: 2000, height: 1500 }
        }
        expect(response).to have_http_status(:forbidden)
        expect(room.reload.width).to eq(1000)
      end
    end
  end

  describe 'GET /rooms/:share_token/canvas_editor' do
    context 'when user is owner' do
      it 'returns room with current canvas dimensions' do
        get "/rooms/#{room.share_token}/canvas_editor"
        expect(response).to have_http_status(:success)
        # Inertia.js ページの props を確認
        body = response.body
        expect(body).to include(room.width.to_s)
        expect(body).to include(room.height.to_s)
      end

      it 'returns default dimensions when width/height are nil' do
        room.update(width: nil, height: nil)
        get "/rooms/#{room.share_token}/canvas_editor"
        expect(response).to have_http_status(:success)
        body = response.body
        # デフォルト値 1000 と 700 が返却されるはず
        expect(body).to include('1000')
        expect(body).to include('700')
      end
    end

    context 'when user is not owner' do
      let(:other_user) { create(:user, :manager) }

      before do
        sign_out user
        sign_in other_user
      end

      it 'denies access' do
        get "/rooms/#{room.share_token}/canvas_editor"
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
