class CheckRoomAutoCheckoutJob < ApplicationJob
  queue_as :default

  def perform
    current_time = Time.current.strftime("%H:%M")

    # ルームレベルの auto_checkout_time をチェック
    Room.where(auto_checkout_enabled: true).where("auto_checkout_time IS NOT NULL").find_each do |room|
      next unless room.auto_checkout_time == current_time

      # そのルームの全アクティブセッションをチェックアウト
      active_sessions = Session.active.joins(:seat).where(seats: { room_id: room.id })

      active_sessions.each do |session|
        session.update(status: "checked_out", check_out_time: Time.current)
      end
    end
  end
end
