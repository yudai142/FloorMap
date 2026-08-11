class Seat < ApplicationRecord
  belongs_to :room
  has_many :sessions, dependent: :destroy

  validates :room_id, presence: true
  validates :row_number, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :column_number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :seat_type, presence: true
  validates :row_number, uniqueness: { scope: [ :column_number, :room_id ] }
  validates :position_x, numericality: { allow_nil: true }
  validates :position_y, numericality: { allow_nil: true }

  enum :seat_type, { regular: "regular", accessible: "accessible", vip: "vip" }

  after_update_commit :clear_caches
  after_destroy_commit :clear_caches

  def clear_caches
    Rails.cache.delete("seat:#{id}:identifier")
    Rails.cache.delete("seat:#{id}:canvas_data")
    Rails.cache.delete("room:#{room_id}:seat_count")
    Rails.cache.delete("room:#{room_id}:occupied_seat_count")
    Rails.cache.delete("room:#{room_id}:occupancy_rate")
    Rails.cache.delete("room:#{room_id}:seats_grouped_by_row")
  end

  def seat_identifier
    Rails.cache.fetch("seat:#{id}:identifier", expires_in: 1.hour) do
      row_letter = (row_number + 65).chr
      "#{row_letter}#{column_number}"
    end
  end

  def move_to(x:, y:)
    update(position_x: x, position_y: y)
  end

  def grid_position
    { row: row_number, column: column_number }
  end

  def canvas_data
    Rails.cache.fetch("seat:#{id}:canvas_data", expires_in: 5.minutes) do
      active_session = sessions.active.last
      {
        id: id,
        seat_identifier: seat_identifier,
        position_x: position_x,
        position_y: position_y,
        row_number: row_number,
        column_number: column_number,
        seat_type: seat_type,
        grid_position: grid_position,
        session: active_session ? { id: active_session.id, user_id: active_session.user_id } : nil
      }
    end
  end
end
