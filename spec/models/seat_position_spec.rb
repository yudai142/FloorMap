require 'rails_helper'

RSpec.describe 'Seat Position', type: :model do
  let(:manager) { create(:user, :manager) }
  let(:room) { create(:room, user: manager) }
  let(:seat) { create(:seat, room: room) }

  describe 'seat position attributes' do
    it 'has position_x and position_y' do
      seat.update(position_x: 100, position_y: 200)
      seat.reload
      expect(seat.position_x).to eq(100)
      expect(seat.position_y).to eq(200)
    end

    it 'allows updating seat position' do
      expect {
        seat.update(position_x: 150, position_y: 250)
      }.to change { seat.position_x }.from(nil).to(150)
    end

    it 'has default position values' do
      new_seat = build(:seat, room: room)
      expect(new_seat.position_x).to be_nil
      expect(new_seat.position_y).to be_nil
    end
  end

  describe '#move_to' do
    it 'updates position_x and position_y' do
      seat.move_to(x: 100, y: 200)
      expect(seat.position_x).to eq(100)
      expect(seat.position_y).to eq(200)
    end

    it 'persists position changes' do
      seat.move_to(x: 100, y: 200)
      seat.reload
      expect(seat.position_x).to eq(100)
      expect(seat.position_y).to eq(200)
    end
  end

  describe '#grid_position' do
    it 'returns row_number and column_number as grid position' do
      seat = create(:seat, room: room, row_number: 2, column_number: 3)
      expect(seat.grid_position).to eq(row: 2, column: 3)
    end
  end

  describe 'position validation' do
    it 'allows nil positions' do
      seat = build(:seat, room: room, position_x: nil, position_y: nil)
      expect(seat).to be_valid
    end

    it 'validates position_x is numeric' do
      seat = build(:seat, room: room, position_x: 'invalid')
      expect(seat).not_to be_valid
    end

    it 'validates position_y is numeric' do
      seat = build(:seat, room: room, position_y: 'invalid')
      expect(seat).not_to be_valid
    end
  end
end
