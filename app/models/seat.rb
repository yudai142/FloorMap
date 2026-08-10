class Seat < ApplicationRecord
  belongs_to :room

  validates :room_id, presence: true
  validates :row_number, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :column_number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :seat_type, presence: true
  validates :row_number, uniqueness: { scope: [ :column_number, :room_id ] }

  enum :seat_type, { regular: "regular", accessible: "accessible", vip: "vip" }

  def seat_identifier
    row_letter = (row_number + 65).chr
    "#{row_letter}#{column_number}"
  end
end
