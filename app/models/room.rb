class Room < ApplicationRecord
  belongs_to :user
  has_many :room_permissions, dependent: :destroy

  validates :name, presence: true
end
