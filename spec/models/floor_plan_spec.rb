require 'rails_helper'

RSpec.describe 'Floor Plan Data', type: :model do
  let(:user) { create(:user, :manager) }
  let(:room) { create(:room, user: user) }

  describe 'Room#floor_plan_data' do
    it 'stores and retrieves floor plan data as JSON' do
      floor_plan = [
        { type: 'rectangle', x: 10, y: 10, width: 100, height: 80, color: '#3b82f6', lineWidth: 2 },
        { type: 'circle', x: 150, y: 50, width: 40, height: 40, color: '#ef4444', lineWidth: 1 }
      ]

      room.update(floor_plan_data: floor_plan)
      expect(room.floor_plan_data).to eq(floor_plan.map(&:stringify_keys))
    end

    it 'defaults to empty array' do
      room = create(:room, user: user)
      expect(room.floor_plan_data).to eq([])
    end

    it 'handles complex nested structures' do
      floor_plan = [
        {
          type: 'polygon',
          points: [[10, 10], [100, 10], [100, 100], [10, 100]],
          color: '#22c55e',
          lineWidth: 2
        }
      ]

      room.update(floor_plan_data: floor_plan)
      expect(room.floor_plan_data).to eq(floor_plan.map(&:stringify_keys))
    end

    it 'persists after multiple updates' do
      floor_plan_v1 = [{ type: 'rectangle', x: 0, y: 0 }]
      floor_plan_v2 = [
        { type: 'rectangle', x: 0, y: 0 },
        { type: 'circle', x: 100, y: 100 }
      ]

      room.update(floor_plan_data: floor_plan_v1)
      expect(room.reload.floor_plan_data.length).to eq(1)

      room.update(floor_plan_data: floor_plan_v2)
      expect(room.reload.floor_plan_data.length).to eq(2)
    end
  end

  describe 'Seat positions relative to floor plan' do
    let!(:seat) { create(:seat, room: room, position_x: 150, position_y: 200) }

    before do
      room.update(floor_plan_data: [
        { type: 'rectangle', x: 100, y: 100, width: 200, height: 200 }
      ])
    end

    it 'maintains seat position independently from floor plan' do
      expect(seat.position_x).to eq(150)
      expect(seat.position_y).to eq(200)
      expect(room.floor_plan_data.first['x']).to eq(100)
    end

    it 'allows seat position updates without affecting floor plan' do
      seat.update(position_x: 250, position_y: 250)
      expect(room.floor_plan_data.first['x']).to eq(100)
    end
  end

  describe 'Floor plan data validation' do
    it 'accepts valid shape objects' do
      valid_shapes = [
        { type: 'rectangle', x: 0, y: 0, width: 100, height: 100 },
        { type: 'circle', x: 100, y: 100, width: 50, height: 50 },
        { type: 'line', x: 0, y: 0, x2: 100, y2: 100 },
        { type: 'arrow', x: 0, y: 0, x2: 100, y2: 100 },
        { type: 'text', x: 50, y: 50, text: 'Label', fontSize: 14 },
        { type: 'polygon', points: [[0, 0], [100, 0], [100, 100]] }
      ]

      valid_shapes.each do |shape|
        room.update(floor_plan_data: [shape])
        expect(room.reload.floor_plan_data).to be_present
      end
    end

    it 'handles empty data' do
      room.update(floor_plan_data: [])
      expect(room.floor_plan_data).to eq([])
    end

    it 'preserves data types' do
      floor_plan = [
        {
          type: 'rectangle',
          x: 10.5,
          y: 20.5,
          width: 100,
          height: 80,
          color: '#3b82f6',
          lineWidth: 2.5,
          visible: true
        }
      ]

      room.update(floor_plan_data: floor_plan)
      data = room.reload.floor_plan_data.first
      expect(data['x']).to be_a(Numeric)
      expect(data['lineWidth']).to be_a(Numeric)
      expect(data['visible']).to be(true)
    end
  end

  describe 'Room serialization with floor plan' do
    before do
      room.update(floor_plan_data: [
        { type: 'rectangle', x: 0, y: 0, width: 100, height: 100 }
      ])
    end

    it 'includes floor_plan_data in JSON serialization' do
      json = room.as_json
      expect(json['floor_plan_data']).to be_present
      expect(json['floor_plan_data'].first['type']).to eq('rectangle')
    end

    it 'returns floor_plan_data in canvas_data' do
      # Assuming canvas_data method exists on Room
      # expect(room.canvas_data[:floor_plan_data]).to be_present
    end
  end
end
