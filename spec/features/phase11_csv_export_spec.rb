require 'rails_helper'

RSpec.describe 'CSV Export Functionality', type: :request do
  describe 'Issue #66: CSV エクスポート機能' do
    let(:user) { create(:user, :manager) }
    let(:room) { create(:room, user: user) }

    before do
      sign_in user
      create_list(:seat, 5, room: room)
    end

    describe 'Seat CSV Export' do
      it 'GET /rooms/:id/seats/export returns CSV file' do
        get export_room_seats_path(room)
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('text/csv')
      end

      it 'CSV contains seat data with correct headers' do
        get export_room_seats_path(room)
        expect(response.body).to include('座席ID', '行', '列', 'タイプ')
      end

      it 'CSV exports all seats in room' do
        get export_room_seats_path(room)
        expect(response.body.lines.count).to eq(room.seats.count + 1)
      end

      it 'Authorization check: only manager can export' do
        other_user = create(:user)
        sign_in other_user
        get export_room_seats_path(room)
        # Non-managers cannot export other users' rooms
        expect([ 302, 403 ]).to include(response.status)
      end

      it 'Response has correct filename' do
        get export_room_seats_path(room)
        disposition = response.headers['Content-Disposition']
        expect(disposition).to include('filename=')
        expect(disposition).to include('.csv')
      end
    end

    describe 'Room CSV Export' do
      it 'GET /rooms/export returns CSV file with all rooms' do
        create_list(:room, 3, user: user)
        get export_rooms_path
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('text/csv')
      end

      it 'CSV contains room metadata' do
        get export_rooms_path
        expect(response.body).to include('ルーム名', '座席数', '占有座席数')
      end

      it 'CSV exports only user rooms for manager' do
        create_list(:room, 3, user: user)
        other_user = create(:user, :manager)
        create_list(:room, 2, user: other_user)

        get export_rooms_path
        lines = response.body.lines
        expect(lines.count).to eq(user.rooms.count + 1)
      end
    end
  end
end
