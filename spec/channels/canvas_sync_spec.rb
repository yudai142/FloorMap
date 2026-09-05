require 'rails_helper'

RSpec.describe RoomsChannel, type: :channel do
  let(:user) { create(:user, :manager) }
  let(:room) { create(:room, user: user) }
  let(:seat) { create(:seat, room: room, position_x: 100, position_y: 100) }

  describe 'Canvas Editor Subscriptions' do
    before do
      stub_connection(current_user: user)
    end

    it 'subscribes to room channel' do
      subscribe(room_id: room.id)
      expect(subscription).to be_confirmed
    end

    it 'denies subscription for unauthorized user' do
      other_user = create(:user)
      stub_connection(current_user: other_user)
      subscribe(room_id: room.id)
      expect(subscription).to be_rejected
    end
  end

  describe 'Seat Updates Broadcasting' do
    before do
      stub_connection(current_user: user)
      subscribe(room_id: room.id)
    end

    it 'broadcasts seat created event' do
      expect {
        seat.broadcast_seat_updated
      }.to have_broadcasted_to(room).with(hash_including(type: 'seat_updated'))
    end

    it 'broadcasts seat position update' do
      expect {
        seat.update(position_x: 200, position_y: 200)
      }.to have_broadcasted_to(room).with(hash_including(type: 'seat_updated'))
    end

    it 'broadcasts seat deleted event' do
      expect {
        seat.broadcast_seat_removed
      }.to have_broadcasted_to(room).with(hash_including(type: 'seat_removed'))
    end

    it 'includes seat data in seat_updated event' do
      expect {
        seat.broadcast_seat_updated
      }.to have_broadcasted_to(room).with(hash_including(
        type: 'seat_updated',
        seat: hash_including('id', 'position_x', 'position_y')
      ))
    end
  end

  describe 'Floor Plan Updates Broadcasting' do
    before do
      stub_connection(current_user: user)
      subscribe(room_id: room.id)
    end

    it 'broadcasts floor plan updated event' do
      floor_plan = [{ type: 'rectangle', x: 0, y: 0, width: 100, height: 100 }]
      expect {
        room.update(floor_plan_data: floor_plan)
      }.to have_broadcasted_to(room).with(hash_including(type: 'floor_plan_updated'))
    end

    it 'includes floor plan data in broadcast' do
      floor_plan = [{ type: 'rectangle', x: 0, y: 0 }]
      expect {
        room.update(floor_plan_data: floor_plan)
      }.to have_broadcasted_to(room).with(hash_including(
        type: 'floor_plan_updated',
        floor_plan_data: floor_plan.map(&:stringify_keys)
      ))
    end
  end

  describe 'Session Updates Broadcasting' do
    before do
      stub_connection(current_user: user)
      subscribe(room_id: room.id)
    end

    it 'broadcasts seat updated on check-in' do
      expect {
        create(:session, user: user, seat: seat)
      }.to have_broadcasted_to(room).with(hash_including(
        type: 'seat_updated'
      ))
    end

    it 'includes occupancy info in broadcast' do
      expect {
        session = create(:session, user: user, seat: seat)
      }.to have_broadcasted_to(room).with(hash_including(
        type: 'seat_updated',
        seat: hash_including('occupied', 'occupant_name')
      ))
    end

    it 'broadcasts seat updated on check-out' do
      session = create(:session, user: user, seat: seat)
      expect {
        session.check_out!
      }.to have_broadcasted_to(room).with(hash_including(
        type: 'seat_updated'
      ))
    end
  end

  describe 'Canvas Data Consistency' do
    before do
      stub_connection(current_user: user)
      subscribe(room_id: room.id)
    end

    it 'broadcasts fresh seat data after position update' do
      seat.update(position_x: 250, position_y: 250)
      expect(transmission).to include(
        type: 'seat_updated',
        seat: hash_including(
          position_x: 250,
          position_y: 250
        )
      )
    end

    it 'broadcasts with all required canvas fields' do
      seat.broadcast_seat_updated
      seat_data = transmission['seat']

      expect(seat_data).to include(
        'id',
        'seat_identifier',
        'position_x',
        'position_y',
        'seat_type',
        'occupied'
      )
    end
  end

  describe 'Multiple User Synchronization' do
    let(:user2) { create(:user, :manager) }

    before do
      stub_connection(current_user: user)
      subscribe(room_id: room.id)
    end

    it 'broadcasts to all subscribers in room' do
      expect {
        seat.update(position_x: 300, position_y: 300)
      }.to have_broadcasted_to(room)
    end

    it 'includes event timestamp for ordering' do
      seat.broadcast_seat_updated
      expect(transmission).to include('timestamp')
    end
  end
end
