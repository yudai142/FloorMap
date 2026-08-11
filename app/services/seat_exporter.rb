require "csv"

class SeatExporter
  def initialize(room)
    @room = room
  end

  def to_csv
    CSV.generate do |csv|
      csv << headers
      @room.seats.each do |seat|
        csv << seat_row(seat)
      end
    end
  end

  private

  def headers
    [ "座席ID", "行", "列", "タイプ", "作成日時" ]
  end

  def seat_row(seat)
    [
      seat.seat_identifier,
      seat.row_number,
      seat.column_number,
      seat.seat_type,
      seat.created_at.strftime("%Y-%m-%d %H:%M:%S")
    ]
  end
end
