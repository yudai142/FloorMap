class User < ApplicationRecord
  devise :database_authenticatable,
         :registerable,
         :recoverable, :rememberable, :validatable,
         :two_factor_authenticatable

  enum role: { user: 0, manager: 1, admin: 2 }

  has_many :rooms, dependent: :destroy
  has_many :room_permissions, dependent: :destroy

  validates :email, presence: true, uniqueness: true
end
