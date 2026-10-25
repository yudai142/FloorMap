require "rails_helper"

RSpec.describe Seat, "canvas_data cache" do
  let(:room) { create(:room) }

  it "reflects a moved position after the seat is updated" do
    seat = create(:seat, room: room, position_x: 150, position_y: 300)
    expect(seat.canvas_data[:position_x]).to eq(150.0)

    seat.update!(position_x: 250, position_y: 350)

    expect(seat.reload.canvas_data[:position_x]).to eq(250.0)
    expect(seat.canvas_data[:position_y]).to eq(350.0)
  end
end
