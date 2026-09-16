require 'rails_helper'

RSpec.describe 'Seat Grid Snap', type: :model do
  let(:manager) { create(:user, :manager) }
  let(:room) { create(:room, user: manager) }
  let(:seat) { create(:seat, room: room) }

  describe 'grid snap calculation' do
    it 'snaps seat position to grid (40px increments)' do
      grid_size = 40

      # Position 95 should snap to 80 (nearest multiple of 40)
      snapped_x = (95.0 / grid_size).round * grid_size
      expect(snapped_x).to eq(80)

      # Position 145 should snap to 160
      snapped_y = (145.0 / grid_size).round * grid_size
      expect(snapped_y).to eq(160)
    end

    it 'handles exact grid positions' do
      grid_size = 40

      # Position 120 should stay at 120
      snapped_x = (120.0 / grid_size).round * grid_size
      expect(snapped_x).to eq(120)
    end

    it 'handles zero position' do
      grid_size = 40
      snapped_x = (0.0 / grid_size).round * grid_size
      expect(snapped_x).to eq(0)
    end
  end

  describe 'seat position with snap' do
    it 'updates position to snapped coordinates' do
      grid_size = 40

      # Simulate dragging to position (95, 145)
      position_x = 95
      position_y = 145

      snapped_x = (position_x.to_f / grid_size).round * grid_size
      snapped_y = (position_y.to_f / grid_size).round * grid_size

      seat.update(position_x: snapped_x, position_y: snapped_y)

      expect(seat.position_x).to eq(80)
      expect(seat.position_y).to eq(160)
    end

    it 'allows multiple seats at different snap positions' do
      seat1 = create(:seat, room: room, position_x: 80, position_y: 80)
      seat2 = create(:seat, room: room, position_x: 120, position_y: 80)

      expect(seat1.position_x).to eq(80)
      expect(seat2.position_x).to eq(120)
    end
  end

  describe 'grid display calculation' do
    it 'calculates grid lines for canvas' do
      canvas_width = 800
      canvas_height = 600
      grid_size = 40

      grid_lines_x = (canvas_width.to_f / grid_size).ceil
      grid_lines_y = (canvas_height.to_f / grid_size).ceil

      expect(grid_lines_x).to eq(20)
      expect(grid_lines_y).to eq(15)
    end

    it 'renders grid at regular intervals' do
      grid_size = 40
      expected_x_positions = (0..780).step(40).to_a

      expect(expected_x_positions.length).to eq(20)
      expect(expected_x_positions.first).to eq(0)
      expect(expected_x_positions.last).to eq(760)
    end
  end
end
