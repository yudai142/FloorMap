require 'rails_helper'

RSpec.describe Room, type: :model do
  let(:user) { create(:user) }
  let(:room) { create(:room, user: user) }

  describe 'caching' do
    before do
      Rails.cache.clear
    end

    describe '#seat_count' do
      it '座席数をキャッシュで取得する' do
        create_list(:seat, 3, room: room)
        result = room.seat_count
        expect(result).to eq(3)

        # キャッシュキーに値が保存されていることを確認
        cached_value = Rails.cache.read("room:#{room.id}:seat_count")
        expect(cached_value).to eq(3)
      end

      it 'キャッシュが存在する場合は再利用する' do
        create_list(:seat, 3, room: room)

        # 初回呼び出し
        result1 = room.seat_count
        expect(result1).to eq(3)

        # キャッシュを手動で上書き
        Rails.cache.write("room:#{room.id}:seat_count", 99)

        # 二度目の呼び出しはキャッシュされた値を返す
        result2 = room.seat_count
        expect(result2).to eq(99)
      end
    end

    describe '#occupied_seat_count' do
      it 'アクティブなセッション数をカウント' do
        seat1 = create(:seat, room: room)
        seat2 = create(:seat, room: room)
        user2 = create(:user)

        create(:session, user: user2, seat: seat1, status: :active)
        create(:session, user: user2, seat: seat2, status: :completed)

        expect(room.occupied_seat_count).to eq(1)
      end

      it '占有率計算のベースとなる' do
        create_list(:seat, 4, room: room)
        seat = room.seats.first
        user2 = create(:user)
        create(:session, user: user2, seat: seat, status: :active)

        expect(room.occupied_seat_count).to eq(1)
      end
    end

    describe '#occupancy_rate' do
      it '座席利用率をパーセンテージで計算' do
        create_list(:seat, 4, room: room)
        seat = room.seats.first
        user2 = create(:user)
        create(:session, user: user2, seat: seat, status: :active)

        rate = room.occupancy_rate
        expect(rate).to eq(25)
      end

      it '座席がない場合は0を返す' do
        expect(room.occupancy_rate).to eq(0)
      end

      it 'キャッシュキーが設定される' do
        create_list(:seat, 4, room: room)
        room.occupancy_rate

        cached_value = Rails.cache.read("room:#{room.id}:occupancy_rate")
        expect(cached_value).to be_present
      end
    end

    describe '#seats_grouped_by_row' do
      it '座席を行番号でグループ化' do
        create(:seat, room: room, row_number: 0, column_number: 1)
        create(:seat, room: room, row_number: 0, column_number: 2)
        create(:seat, room: room, row_number: 1, column_number: 1)

        result = room.seats_grouped_by_row
        expect(result.keys).to eq([ 0, 1 ])
        expect(result[0].length).to eq(2)
        expect(result[1].length).to eq(1)
      end

      it 'キャッシュで高速化' do
        create_list(:seat, 10, room: room)

        result1 = room.seats_grouped_by_row
        cached_value = Rails.cache.read("room:#{room.id}:seats_grouped_by_row")
        expect(cached_value).to eq(result1)

        result2 = room.seats_grouped_by_row
        expect(result2).to eq(result1)
      end
    end

    describe 'cache operations' do
      it 'キャッシュキーを削除できる' do
        cache_key = "room:#{room.id}:seat_count"
        Rails.cache.write(cache_key, 5)
        expect(Rails.cache.read(cache_key)).to eq(5)

        Rails.cache.delete(cache_key)
        expect(Rails.cache.read(cache_key)).to be_nil
      end

      it '複数キーを一括削除できる' do
        keys = [
          "room:#{room.id}:seat_count",
          "room:#{room.id}:occupied_seat_count",
          "room:#{room.id}:occupancy_rate"
        ]

        keys.each { |key| Rails.cache.write(key, 'cached') }
        keys.each { |key| Rails.cache.delete(key) }

        keys.each { |key| expect(Rails.cache.read(key)).to be_nil }
      end
    end
  end
end
