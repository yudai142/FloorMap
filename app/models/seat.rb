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

  def seat_identifier
    row_letter = (row_number + 65).chr
    "#{row_letter}#{column_number}"
  end

  def move_to(x:, y:)
    update(position_x: x, position_y: y)
  end

  def grid_position
    { row: row_number, column: column_number }
  end

  def canvas_data
    {
      id: id,
      seat_identifier: seat_identifier,
      position_x: position_x,
      position_y: position_y,
      row_number: row_number,
      column_number: column_number,
      seat_type: seat_type,
      grid_position: grid_position
    }
  end
end
