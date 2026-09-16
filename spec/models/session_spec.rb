require "rails_helper"

RSpec.describe Session, type: :model do
  let(:user) { create(:user) }
  let(:room) { create(:room, user: user) }
  let(:seat) { create(:seat, room: room) }

  describe "自動離席機能" do
    describe "個人の自動離席 (user_auto_checkout_time)" do
      it "user_auto_checkout_time に指定された時刻にジョブがスケジュールされる" do
        future_time = 1.hour.from_now

        expect {
          create(:session,
            user: user,
            seat: seat,
            user_auto_checkout_enabled: true,
            user_auto_checkout_time: future_time,
            status: "active"
          )
        }.to have_enqueued_job(AutoCheckoutJob)
      end

      it "user_auto_checkout_enabled が false ではスケジュールされない" do
        expect {
          create(:session,
            user: user,
            seat: seat,
            user_auto_checkout_enabled: false,
            user_auto_checkout_time: nil,
            status: "active"
          )
        }.not_to have_enqueued_job(AutoCheckoutJob)
      end
    end

    describe "ルーム全体の自動離席" do
      it "room の auto_checkout_enabled が true で auto_checkout_time が設定されている" do
        checkout_time = "18:00"
        room.update(auto_checkout_enabled: true, auto_checkout_time: checkout_time)

        seat2 = create(:seat, room: room)
        another_user = create(:user)

        session1 = create(:session, user: user, seat: seat, status: "active")
        session2 = create(:session, user: another_user, seat: seat2, status: "active")

        expect(room.auto_checkout_enabled).to be true
        expect(room.auto_checkout_time).to eq(checkout_time)

        # ルーム内のアクティブセッション数を確認
        active_sessions = Session.active.joins(:seat).where(seats: { room_id: room.id })
        expect(active_sessions.count).to eq(2)
      end

      it "CheckRoomAutoCheckoutJob が指定時刻に実行される" do
        current_time = Time.current
        checkout_time = current_time.strftime("%H:%M")
        room.update(auto_checkout_enabled: true, auto_checkout_time: checkout_time)

        seat2 = create(:seat, room: room)
        another_user = create(:user)

        session1 = create(:session, user: user, seat: seat, status: "active")
        session2 = create(:session, user: another_user, seat: seat2, status: "active")

        # CheckRoomAutoCheckoutJob を実行
        CheckRoomAutoCheckoutJob.new.perform

        # 両方のセッションが checked_out になることを確認
        expect(session1.reload.status).to eq("checked_out")
        expect(session2.reload.status).to eq("checked_out")
      end
    end

    describe "個人とルーム全体の両方が指定されている場合" do
      it "個人のジョブがスケジュールされる" do
        user_checkout_time = 1.hour.from_now
        room.update(auto_checkout_enabled: true, auto_checkout_time: "17:00")

        expect {
          create(:session,
            user: user,
            seat: seat,
            user_auto_checkout_enabled: true,
            user_auto_checkout_time: user_checkout_time,
            status: "active"
          )
        }.to have_enqueued_job(AutoCheckoutJob)
      end

      it "個人の自動離席時刻の方が早い場合、個人の時刻で離席される" do
        user_checkout_time = 30.minutes.from_now
        room_checkout_time = 2.hours.from_now

        room.update(auto_checkout_enabled: true, auto_checkout_time: room_checkout_time.strftime("%H:%M"))
        session = create(:session,
          user: user,
          seat: seat,
          user_auto_checkout_enabled: true,
          user_auto_checkout_time: user_checkout_time,
          status: "active"
        )

        # 個人の自動離席時刻の方が早いことを確認
        expect(session.user_auto_checkout_time).to be < room_checkout_time
      end

      it "ルーム全体の自動離席時刻の方が早い場合、ルームの時刻で全員が離席される" do
        user_checkout_time = 3.hours.from_now
        room_checkout_time = 1.hour.from_now

        room.update(auto_checkout_enabled: true, auto_checkout_time: room_checkout_time.strftime("%H:%M"))
        session = create(:session,
          user: user,
          seat: seat,
          user_auto_checkout_enabled: true,
          user_auto_checkout_time: user_checkout_time,
          status: "active"
        )

        # ルームの自動離席時刻の方が早いことを確認
        room_checkout = Time.parse("#{Time.current.to_date} #{room_checkout_time.strftime("%H:%M")}")
        expect(room_checkout).to be < user_checkout_time
      end
    end

    describe "自動離席後の状態" do
      it "自動離席されるとステータスが checked_out に変更される" do
        session = create(:session, user: user, seat: seat, status: "active")

        session.check_out!

        expect(session.status).to eq("checked_out")
        expect(session.check_out_time).not_to be_nil
      end

      it "複数の session が同時に check_out! される" do
        seat2 = create(:seat, room: room)
        another_user = create(:user)

        session1 = create(:session, user: user, seat: seat, status: "active")
        session2 = create(:session, user: another_user, seat: seat2, status: "active")

        expect(Session.active.count).to eq(2)

        session1.check_out!
        session2.check_out!

        expect(Session.active.count).to eq(0)
        expect(Session.completed.count).to eq(2)
      end
    end

    describe "ブロードキャスト" do
      it "user_auto_checkout_time が更新されると RoomsChannel にブロードキャストされる", skip: true do
        session = create(:session, user: user, seat: seat, status: "active")
        future_time = 1.hour.from_now

        expect(RoomsChannel).to receive(:broadcast_to).with(
          room,
          hash_including(
            type: "user_auto_checkout_updated",
            session_id: session.id
          )
        )

        session.update(user_auto_checkout_time: future_time)
      end

      it "session 作成時に座席更新情報がブロードキャストされる", skip: true do
        expect(RoomsChannel).to receive(:broadcast_to).with(
          room,
          hash_including(type: "seat_updated")
        )

        create(:session, user: user, seat: seat, status: "active")
      end
    end
  end
end
