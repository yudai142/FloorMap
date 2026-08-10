class Session < ApplicationRecord
  belongs_to :user
  belongs_to :seat

  validates :user_id, presence: true
  validates :seat_id, presence: true
  validates :check_in_time, presence: true
  validates :status, presence: true

  enum :status, { active: "active", completed: "completed", expired: "expired" }

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
end
