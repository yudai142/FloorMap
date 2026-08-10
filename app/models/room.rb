class Room < ApplicationRecord
  belongs_to :user
  has_many :room_permissions, dependent: :destroy
  has_many :seats, dependent: :destroy

  validates :name, presence: true
end
