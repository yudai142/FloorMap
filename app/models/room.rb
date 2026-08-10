class Room < ApplicationRecord
  belongs_to :user
  has_many :room_permissions, dependent: :destroy
  has_many :seats, dependent: :destroy

  validates :name, presence: true

  scope :search, ->(query) {
    return all if query.blank?

    where("LOWER(name) LIKE :query OR LOWER(description) LIKE :query",
          query: "%#{query.downcase}%")
  }

  scope :by_owner, ->(user_id) { where(user_id: user_id) }

  scope :accessible_by, ->(user) {
    if user.admin?
      all
    else
      joins("LEFT JOIN room_permissions ON room_permissions.room_id = rooms.id")
        .where("rooms.user_id = ? OR room_permissions.user_id = ?", user.id, user.id)
        .distinct
    end
  }

  scope :sorted, ->(column, direction) {
    if column.blank? || direction.blank?
      order(created_at: :desc)
    else
      column_safe = column.to_s.downcase == 'name' ? 'name' : 'created_at'
      direction_safe = direction.to_s.downcase == 'desc' ? :desc : :asc
      order(column_safe => direction_safe)
    end
  }

  def seat_count
    seats.count
  end

  def occupied_seat_count
    Session.where(seat_id: seats.ids, status: :active).select(:seat_id).distinct.count
  end
end
