require 'rails_helper'

RSpec.describe 'CSV Export Functionality', type: :request do
  describe 'Issue #66: CSV エクスポート機能' do
    let(:user) { create(:user, :manager) }
    let(:room) { create(:room, user: user) }
    let(:seats) { create_list(:seat, 5, room: room) }

    before { sign_in user }

    describe 'Seat CSV Export' do
      pending 'GET /rooms/:id/seats/export returns CSV file' do
        get room_seats_export_path(room), as: :csv
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('text/csv')
      end

      pending 'CSV contains seat data with correct headers' do
        get room_seats_export_path(room), as: :csv
        expect(response.body).to include('座席ID', '行', '列', 'ステータス')
      end

      pending 'CSV exports all seats in room' do
        get room_seats_export_path(room), as: :csv
        expect(response.body.lines.count).to eq(seats.count + 1)
      end

      pending 'Authorization check: only manager can export' do
        visitor = create(:user)
        sign_in visitor
        get room_seats_export_path(room), as: :csv
        expect(response).to have_http_status(:forbidden)
      end

      pending 'File encoding is UTF-8' do
        get room_seats_export_path(room), as: :csv
        expect(response.text_encoding).to eq(Encoding::UTF_8)
      end
    end

    describe 'Room CSV Export' do
      pending 'GET /rooms/export returns CSV file with all rooms' do
        create_list(:room, 3, user: user)
        get rooms_export_path, as: :csv
        expect(response.content_type).to include('text/csv')
      end

      pending 'CSV contains room metadata' do
        get rooms_export_path, as: :csv
        expect(response.body).to include('ルーム名', '容量', '作成日時')
      end
    end
  end
end
