require 'rails_helper'

RSpec.describe Seat, type: :model do
  let(:user) { create(:user) }
  let(:room) { create(:room, user: user) }
  let(:seat) { create(:seat, room: room, row_number: 0, column_number: 1) }

  describe 'caching' do
    before do
      Rails.cache.clear
    end

    describe '#seat_identifier' do
      it '座席識別子を生成する' do
        result = seat.seat_identifier
        expect(result).to eq('A1')
      end

      it '行番号と列番号から正しく識別子を生成する' do
        seat_b3 = create(:seat, room: room, row_number: 1, column_number: 3)
        expect(seat_b3.seat_identifier).to eq('B3')
      end

      it 'キャッシュキーが設定される' do
        seat.seat_identifier

        cached_value = Rails.cache.read("seat:#{seat.id}:identifier")
        expect(cached_value).to eq('A1')
      end

      it 'キャッシュがあれば再利用する' do
        Rails.cache.write("seat:#{seat.id}:identifier", 'CACHED')

        result = seat.seat_identifier
        expect(result).to eq('CACHED')
      end
    end

    describe '#canvas_data' do
      it 'キャンバスデータを含む必要なフィールドを返す' do
        data = seat.canvas_data
        expect(data).to include(
          :id, :seat_identifier, :position_x, :position_y,
          :row_number, :column_number, :seat_type, :grid_position
        )
      end

      it 'アクティブなセッション情報を含む' do
        user2 = create(:user)
        session = create(:session, user: user2, seat: seat, status: :active)

        data = seat.canvas_data
        expect(data[:session]).to include(id: session.id, user_id: user2.id)
      end

      it 'アクティブなセッションがない場合は session: nil を返す' do
        user2 = create(:user)
        create(:session, user: user2, seat: seat, status: :checked_out)

        data = seat.canvas_data
        expect(data[:session]).to be_nil
      end

      it 'キャッシュキーが設定される' do
        data = seat.canvas_data

        cached_value = Rails.cache.read("seat:#{seat.id}:canvas_data")
        expect(cached_value).to eq(data)
      end
    end

    describe 'clear_caches method' do
      it '座席のキャッシュキーを削除する' do
        seat_key = "seat:#{seat.id}:identifier"
        Rails.cache.write(seat_key, 'A1')

        seat.clear_caches

        expect(Rails.cache.read(seat_key)).to be_nil
      end

      it 'canvas_data キャッシュを削除する' do
        canvas_key = "seat:#{seat.id}:canvas_data"
        Rails.cache.write(canvas_key, { test: 'data' })

        seat.clear_caches

        expect(Rails.cache.read(canvas_key)).to be_nil
      end

      it 'ルーム関連のキャッシュキーも削除する' do
        room_keys = [
          "room:#{room.id}:seat_count",
          "room:#{room.id}:occupied_seat_count",
          "room:#{room.id}:occupancy_rate",
          "room:#{room.id}:seats_grouped_by_row"
        ]

        room_keys.each { |key| Rails.cache.write(key, 'cached') }

        seat.clear_caches

        room_keys.each { |key| expect(Rails.cache.read(key)).to be_nil }
      end
    end

    describe 'cache performance' do
      it 'キャッシュが存在すれば重複計算を避ける' do
        # 初回呼び出しでキャッシュを作成
        result1 = seat.seat_identifier
        cached_result = Rails.cache.read("seat:#{seat.id}:identifier")

        # キャッシュ内容を変更
        Rails.cache.write("seat:#{seat.id}:identifier", 'MODIFIED')

        # 二度目の呼び出しでキャッシュされた値を使用
        result2 = seat.seat_identifier
        expect(result2).to eq('MODIFIED')
      end
    end
  end
end
