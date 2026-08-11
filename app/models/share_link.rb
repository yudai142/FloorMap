class ShareLink < ApplicationRecord
  belongs_to :room

  validates :token, presence: true, uniqueness: true
  before_create :generate_token

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at IS NOT NULL AND expires_at <= ?", Time.current) }

  def active?
    expires_at.nil? || expires_at > Time.current
  end

  def expired?
    !active?
  end

  def remaining_time
    return nil if expires_at.nil?
    (expires_at - Time.current).to_i
  end

  private

  def generate_token
    self.token = SecureRandom.hex(16)
  end
end
