class RoomPermission < ApplicationRecord
  belongs_to :user
  belongs_to :room

  enum permission_type: { view: 0, edit: 1, manage: 2 }

  validates :permission_type, presence: true
  validates :user_id, presence: true, uniqueness: { scope: :room_id }
  validates :room_id, presence: true
end
