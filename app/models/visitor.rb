class Visitor < ApplicationRecord
  has_many :sessions, dependent: :destroy

  validates :session_id, presence: true
  validates :nickname, presence: true, length: { maximum: 255 }

  scope :expired, -> { where("created_at < ?", 24.hours.ago) }
  scope :recent, -> { order(created_at: :desc) }

  def active?
    sessions.active.exists?
  end

  def current_seat
    sessions.active.last&.seat
  end

  def check_in_to_seat(seat)
    # TODO: Implement check-in logic
  end

  def check_out
    # TODO: Implement check-out logic
  end
end
