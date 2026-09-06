class Session < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :visitor, optional: true
  belongs_to :seat
  has_one :room, through: :seat

  enum :status, { active: "active", checked_out: "checked_out", timed_out: "timed_out" }, validate: true

  validates :seat_id, :check_in_time, presence: true
  validates :status, presence: true
  validate :user_or_visitor_present
  validate :seat_not_already_occupied

  scope :active, -> { where(status: :active) }
  scope :completed, -> { where(status: [ :checked_out, :timed_out ]) }
  scope :by_user, ->(user) { where(user_id: user.id) }
  scope :by_visitor, ->(visitor) { where(visitor_id: visitor.id) }
  scope :by_date, ->(date) { where(created_at: date.beginning_of_day..date.end_of_day) }
  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :clear_seat_caches
  after_create_commit :broadcast_seat_updated
  after_create_commit :schedule_auto_checkout
  after_create_commit :schedule_user_auto_checkout
  after_update_commit :clear_seat_caches, if: :saved_change_to_status?
  after_update_commit :broadcast_seat_updated, if: :saved_change_to_status?
  after_update_commit :schedule_user_auto_checkout, if: :saved_change_to_user_auto_checkout_time?

  def duration
    end_time = check_out_time || Time.current
    (end_time - check_in_time).to_i
  end

  def check_out!
    update(status: "checked_out", check_out_time: Time.current)
  end

  def has_auto_checkout?
    auto_checkout_at.present? && auto_checkout_at > Time.current
  end

  def auto_checkout_time_formatted
    return nil unless auto_checkout_at
    auto_checkout_at.strftime("%H:%M")
  end

  private

  def schedule_auto_checkout
    return if checkout_timer_minutes.blank? || status != "active"

    checkout_time = check_in_time + checkout_timer_minutes.minutes
    update_column(:auto_checkout_at, checkout_time)
    AutoCheckoutJob.set(wait_until: checkout_time).perform_later(id)
  end

  def schedule_user_auto_checkout
    return if !user_auto_checkout_enabled || user_auto_checkout_time.blank? || status != "active"

    AutoCheckoutJob.set(wait_until: user_auto_checkout_time).perform_later(id)
  end

  def clear_seat_caches
    seat.clear_caches
  end

  def broadcast_seat_updated
    RoomsChannel.broadcast_to(room, type: "seat_updated", seat: seat.canvas_data)
  end

  def user_or_visitor_present
    return if user_id.present? || visitor_id.present? || device_identifier.present?

    errors.add(:base, "ユーザー、訪問者、またはデバイス識別子のいずれかが必要です")
  end

  def seat_not_already_occupied
    return unless status == "active" && seat_id.present?

    existing = Session.active.where(seat_id: seat_id).first
    if existing
      errors.add(:base, "この座席は既に使用されています")
    end
  end
end
