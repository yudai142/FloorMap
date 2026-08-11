class Room < ApplicationRecord
  belongs_to :user
  has_many :room_permissions, dependent: :destroy
  has_many :seats, dependent: :destroy
  has_many :share_links, dependent: :destroy

  validates :name, presence: true

  scope :search, ->(query) {
    return all if query.blank?

    where("LOWER(name) LIKE :query OR LOWER(description) LIKE :query",
          query: "%#{query.downcase}%")
  }

  scope :by_owner, ->(user_id) { where(user_id: user_id) }

  scope :accessible_by, ->(user) {
    if user.admin?
      all.includes(:seats, :room_permissions)
    else
      joins("LEFT JOIN room_permissions ON room_permissions.room_id = rooms.id")
        .where("rooms.user_id = ? OR room_permissions.user_id = ?", user.id, user.id)
        .distinct
        .includes(:seats, :room_permissions)
    end
  }

  scope :sorted, ->(column, direction) {
    if column.blank? || direction.blank?
      order(created_at: :desc)
    else
      col = [ "name", "created_at" ].include?(column.to_s) ? column : "created_at"
      dir = [ "desc", "asc" ].include?(direction.to_s) ? direction.to_sym : :desc
      order(col => dir)
    end
  }

  def seat_count
    Rails.cache.fetch("room:#{id}:seat_count", expires_in: 1.hour) do
      seats.count
    end
  end

  def occupied_seat_count
    Rails.cache.fetch("room:#{id}:occupied_seat_count", expires_in: 30.minutes) do
      Session.where(seat_id: seats.ids, status: :active).select(:seat_id).distinct.count
    end
  end

  def visitor_seats
    seats.joins(sessions: :visitor).where(sessions: { status: :active }).select("DISTINCT seats.*")
  end

  def occupancy_rate
    return 0 if seat_count.zero?

    Rails.cache.fetch("room:#{id}:occupancy_rate", expires_in: 30.minutes) do
      ((occupied_seat_count.to_f / seat_count) * 100).round
    end
  end

  def seats_grouped_by_row
    Rails.cache.fetch("room:#{id}:seats_grouped_by_row", expires_in: 1.hour) do
      seats.order(:row_number, :column_number).group_by(&:row_number)
    end
end

  def seat_with_session(seat)
    session = Session.where(seat_id: seat.id, status: :active).last
    { seat: seat, session: session, user: session&.user }
  end
end
