class Visitor < ApplicationRecord
  has_many :sessions, dependent: :destroy

  validates :session_id, presence: true, uniqueness: true
  validates :nickname, presence: true, length: { maximum: 255 }

  scope :expired, -> { where("created_at < ?", 24.hours.ago) }
  scope :recent, -> { order(created_at: :desc) }

  def active?
    sessions.active.exists?
  end

  def current_seat
    sessions.active.last&.seat
  end

  def current_room
    current_seat&.room
  end

  def check_in_to_seat(seat)
    return false if seat.nil?

    sessions.create(seat: seat, check_in_time: Time.current, status: :active)
  end

  def check_out
    active_session = sessions.active.last
    return false if active_session.nil?

    active_session.check_out!
  end

  def display_name
    nickname
  end
end
