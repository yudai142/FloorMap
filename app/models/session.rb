class Session < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :visitor, optional: true
  belongs_to :seat
  has_one :room, through: :seat

  enum :status, { active: 0, checked_out: 1, timed_out: 2 }, validate: true

  validates :seat_id, :check_in_time, presence: true
  validates :status, presence: true
  validates :user_id, uniqueness: { scope: :seat_id, conditions: -> { where(status: :active) } }, allow_nil: true
  validate :user_or_visitor_present

  scope :active, -> { where(status: :active) }
  scope :completed, -> { where(status: [ :checked_out, :timed_out ]) }
  scope :by_user, ->(user) { where(user_id: user.id) }
  scope :by_visitor, ->(visitor) { where(visitor_id: visitor.id) }
  scope :by_date, ->(date) { where(created_at: date.beginning_of_day..date.end_of_day) }
  scope :recent, -> { order(created_at: :desc) }

  def duration
    end_time = check_out_time || Time.current
    (end_time - check_in_time).to_i
  end

  private

  def user_or_visitor_present
    return if user_id.present? || visitor_id.present?

    errors.add(:base, "ユーザーまたは訪問者のいずれかが必要です")
  end
end
