class User < ApplicationRecord
  devise :database_authenticatable,
         :registerable,
         :recoverable, :rememberable, :validatable,
         :two_factor_authenticatable

  enum :role, { user: 0, manager: 1, admin: 2 }

  has_many :rooms, dependent: :destroy
  has_many :room_permissions, dependent: :destroy
  has_many :sessions, dependent: :destroy
  has_many :notifications, dependent: :destroy

  validates :email, presence: true, uniqueness: true

  def owner_of?(room)
    room.user_id == id
  end

  def has_permission_in?(room)
    room_permissions.exists?(room_id: room.id)
  end
end
