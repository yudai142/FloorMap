class Session < ApplicationRecord
  belongs_to :user
  belongs_to :seat

  validates :user_id, presence: true
  validates :seat_id, presence: true
  validates :check_in_time, presence: true
  validates :status, presence: true

  enum :status, { active: "active", completed: "completed", expired: "expired" }

  after_create_commit { broadcast_seat_updated }
  after_update_commit { broadcast_seat_updated }
  after_create_commit { create_check_in_notification }
  after_update_commit :create_check_out_notification, if: :just_completed?

  scope :active, -> { where(status: :active) }
  scope :completed, -> { where(status: :completed) }
  scope :expired, -> { where(status: :expired) }

  def duration
    return nil if check_out_time.nil?

    (check_out_time - check_in_time).to_i
  end

  def check_out!
    update(check_out_time: Time.current, status: :completed)
  end

  private

  def broadcast_seat_updated
    RoomsChannel.broadcast_to(seat.room, {
      type: "seat_updated",
      seat: seat.canvas_data
    })
  end

  def create_check_in_notification
    room = seat.room
    title = "<strong>#{user.email}</strong>さんが<strong>#{seat.seat_identifier}</strong>にチェックインしました。"
    body = "ユーザー #{user.email} が座席 #{seat.seat_identifier} にチェックインしました。"

    create_notifications_for_room(room, "check_in", title, body)
  end

  def create_check_out_notification
    room = seat.room
    title = "<strong>#{user.email}</strong>さんが<strong>#{seat.seat_identifier}</strong>からチェックアウトしました。"
    body = "ユーザー #{user.email} が座席 #{seat.seat_identifier} からチェックアウトしました。"

    create_notifications_for_room(room, "check_out", title, body)
  end

  def create_notifications_for_room(room, notification_type, title, body)
    room.user.notifications.create!(
      room: room,
      notification_type: notification_type,
      title: title,
      body: body
    )
  end

  def just_completed?
    status_was == "active" && status == "completed"
  end
end
