class RoomPermission < ApplicationRecord
  belongs_to :user
  belongs_to :room

  enum :permission_type, { view: 0, edit: 1, manage: 2 }

  attr_accessor :user_email

  validates :permission_type, presence: true
  validates :user_id, presence: true, uniqueness: { scope: :room_id }
  validates :room_id, presence: true

  before_validation :find_user_by_email, if: -> { user_email.present? }

  private

  def find_user_by_email
    user = User.find_by(email: user_email)
    if user
      self.user_id = user.id
    else
      errors.add(:user_email, "メールアドレスが見つかりません")
    end
  end
end
