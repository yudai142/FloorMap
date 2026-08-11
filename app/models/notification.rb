class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :room

  validates :user_id, presence: true
  validates :room_id, presence: true
  validates :notification_type, presence: true
  validates :title, presence: true
  validates :body, presence: true

  enum :notification_type, {
    check_in: "check_in",
    check_out: "check_out",
    system_update: "system_update",
    warning: "warning"
  }

  scope :unread, -> { where(read_at: nil).order(created_at: :desc) }
  scope :read, -> { where.not(read_at: nil).order(created_at: :desc) }

  def unread?
    read_at.nil?
  end

  def mark_as_read!
    update(read_at: Time.current)
  end
end
