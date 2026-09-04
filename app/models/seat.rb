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

  GRID_SIZE = 40

  after_create_commit :clear_caches
  after_create_commit :broadcast_seat_updated
  after_update_commit :clear_caches
  after_update_commit :broadcast_seat_updated
  after_destroy_commit :clear_caches
  after_destroy_commit :broadcast_seat_removed

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

  def self.grid_position_for(position_x:, position_y:)
    {
      row_number: [(position_y.to_f / GRID_SIZE).round, 0].max,
      column_number: [(position_x.to_f / GRID_SIZE).round, 0].max + 1
    }
  end

  def canvas_data
    Rails.cache.fetch("seat:#{id}:canvas_data", expires_in: 5.minutes) do
      active_session = sessions.active.last
      session_data = nil

      if active_session
        if active_session.user_id
          session_data = { id: active_session.id, user_id: active_session.user_id, type: "user" }
        elsif active_session.visitor_id
          session_data = { id: active_session.id, visitor_id: active_session.visitor_id, type: "visitor", name: active_session.visitor&.display_name }
        end
      end

      {
        id: id,
        seat_identifier: seat_identifier,
        position_x: position_x,
        position_y: position_y,
        row_number: row_number,
        column_number: column_number,
        seat_type: seat_type,
        grid_position: grid_position,
        session: session_data
      }
    end
  end

  private

  def broadcast_seat_updated
    RoomsChannel.broadcast_to(room, type: "seat_updated", seat: canvas_data)
  end

  def broadcast_seat_removed
    RoomsChannel.broadcast_to(room, type: "seat_removed", seat_id: id)
  end
end
