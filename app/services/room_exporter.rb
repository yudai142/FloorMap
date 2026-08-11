require "csv"

class RoomExporter
  def initialize(user)
    @user = user
  end

  def to_csv
    CSV.generate do |csv|
      csv << headers
      rooms.each do |room|
        csv << room_row(room)
      end
    end
  end

  private

  def headers
    [ "ルーム名", "座席数", "占有座席数", "占有率" ]
  end

  def room_row(room)
    [
      room.name,
      room.seats.count,
      room.occupied_seat_count,
      room.occupancy_rate&.round(2) || 0
    ]
  end

  def rooms
    case @user.role
    when "admin"
      Room.all
    else
      @user.rooms
    end
  end
end
