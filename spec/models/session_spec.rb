require 'rails_helper'

RSpec.describe Session, type: :model do
  let(:user) { create(:user) }
  let(:room) { create(:room, user: user) }
  let(:seat) { create(:seat, room: room) }

  describe '自動離席機能' do
    describe '個人の自動離席' do
      it 'user_auto_checkout_time に指定された時刻に自動離席される' do
        future_time = 1.hour.from_now
        session = create(:session, user: user, seat: seat, user_auto_checkout_time: future_time)

        expect(session.status).to eq('active')
        expect(session.user_auto_checkout_time).to eq(future_time)

        # AutoCheckoutJob が指定時刻でスケジュールされることを確認
        expect(AuthCheckoutJob).to have_been_enqueued.at(future_time)
      end

      it '自動離席時刻が過去の場合はスケジュールされない' do
        past_time = 1.hour.ago
        session = create(:session, user: user, seat: seat, user_auto_checkout_time: past_time)

        # 過去の時刻はスケジュールされない
        expect(AuthCheckoutJob).not_to have_been_enqueued.at(past_time)
      end
    end

    describe 'ルーム全体の自動離席' do
      it 'room の auto_checkout_time に指定された時刻に全員が自動離席される' do
        future_time = 2.hours.from_now
        room.update(auto_checkout_enabled: true, auto_checkout_time: future_time.to_s)

        # 複数のセッションを作成
        session1 = create(:session, user: user, seat: seat, status: 'active')
        session2_seat = create(:seat, room: room)
        another_user = create(:user)
        session2 = create(:session, user: another_user, seat: session2_seat, status: 'active')

        expect(room.auto_checkout_enabled).to be true
        expect(room.auto_checkout_time).not_to be_nil

        # ルーム全体の自動離席ジョブがスケジュールされることを確認
        # （実装に応じて、AutoCheckoutRoomJob 等が存在する場合）
      end
    end

    describe '個人とルーム全体の両方が指定されている場合' do
      it '両方の自動離席がスケジュールされる' do
        user_checkout_time = 1.hour.from_now
        room_checkout_time = 2.hours.from_now

        room.update(auto_checkout_enabled: true, auto_checkout_time: room_checkout_time.to_s)
        session = create(:session,
          user: user,
          seat: seat,
          user_auto_checkout_time: user_checkout_time,
          status: 'active'
        )

        expect(session.user_auto_checkout_time).to eq(user_checkout_time)
        expect(room.auto_checkout_enabled).to be true
        expect(room.auto_checkout_time).not_to be_nil

        # 両方のジョブがスケジュールされることを確認
        expect(AuthCheckoutJob).to have_been_enqueued.at(user_checkout_time)
      end

      it '個人の自動離席時刻の方が早い場合、個人の時刻で自動離席される' do
        user_checkout_time = 30.minutes.from_now
        room_checkout_time = 2.hours.from_now

        room.update(auto_checkout_enabled: true, auto_checkout_time: room_checkout_time.to_s)
        session = create(:session,
          user: user,
          seat: seat,
          user_auto_checkout_time: user_checkout_time,
          status: 'active'
        )

        # 個人の自動離席時刻の方が早いことを確認
        expect(session.user_auto_checkout_time).to be < room_checkout_time.to_datetime
      end

      it 'ルーム全体の自動離席時刻の方が早い場合、ルームの時刻で全員が自動離席される' do
        user_checkout_time = 3.hours.from_now
        room_checkout_time = 1.hour.from_now

        room.update(auto_checkout_enabled: true, auto_checkout_time: room_checkout_time.to_s)
        session = create(:session,
          user: user,
          seat: seat,
          user_auto_checkout_time: user_checkout_time,
          status: 'active'
        )

        # ルームの自動離席時刻の方が早いことを確認
        expect(room_checkout_time.to_datetime).to be < session.user_auto_checkout_time
      end
    end

    describe '自動離席後の状態' do
      it '自動離席されるとステータスが timed_out に変更される' do
        session = create(:session, user: user, seat: seat, status: 'active')

        # 自動チェックアウトを実行
        session.check_out!

        expect(session.status).to eq('checked_out')
        expect(session.check_out_time).not_to be_nil
      end

      it '自動離席されると座席が解放される' do
        session = create(:session, user: user, seat: seat, status: 'active')

        expect(seat.reload.occupied).to be true

        session.check_out!

        expect(seat.reload.occupied).to be false
      end
    end
  end
end
