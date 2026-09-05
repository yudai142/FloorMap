require 'rails_helper'

RSpec.describe RoomsChannel, type: :channel do
  let(:manager) { create(:user, :manager) }
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let(:room) { create(:room, user: manager) }

  describe "#subscribed" do
    it "subscribes to room stream for room owner" do
      stub_connection(current_user: manager)
      subscribe(room_id: room.id)

      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_for(room)
    end

    it "subscribes to room stream for admin" do
      stub_connection(current_user: admin)
      subscribe(room_id: room.id)

      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_for(room)
    end

    it "subscribes to room stream for user with room_permission" do
      room_permission = create(:room_permission, room: room, user: regular_user)
      stub_connection(current_user: regular_user)
      subscribe(room_id: room.id)

      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_for(room)
    end

    it "rejects subscription for unauthorized user" do
      stub_connection(current_user: regular_user)
      subscribe(room_id: room.id)

      expect(subscription).to be_rejected
    end
  end

  describe "Seat broadcasting" do
    before do
      stub_connection(current_user: manager)
      subscribe(room_id: room.id)
    end

    it "broadcasts seat_updated on seat creation" do
      expect {
        create(:seat, room: room)
      }.to have_broadcasted_to(room).with(
        hash_including(type: "seat_updated")
      )
    end

    it "broadcasts seat_updated on seat position change" do
      seat = create(:seat, room: room)

      expect {
        seat.update(position_x: 200, position_y: 200)
      }.to have_broadcasted_to(room).with(
        hash_including(type: "seat_updated")
      )
    end

    it "broadcasts seat_removed on seat deletion" do
      seat = create(:seat, room: room)

      expect {
        seat.destroy
      }.to have_broadcasted_to(room).with(
        hash_including(type: "seat_removed")
      )
    end
  end

  describe "Session broadcasting" do
    before do
      stub_connection(current_user: manager)
      subscribe(room_id: room.id)
    end

    it "broadcasts seat_updated on check-in" do
      seat = create(:seat, room: room)

      expect {
        create(:session, seat: seat, user: manager)
      }.to have_broadcasted_to(room).with(
        hash_including(type: "seat_updated")
      )
    end

    it "broadcasts seat_updated on check-out" do
      seat = create(:seat, room: room)
      session = create(:session, seat: seat, user: manager)

      expect {
        session.check_out!
      }.to have_broadcasted_to(room).with(
        hash_including(type: "seat_updated")
      )
    end
  end

  describe "Floor plan broadcasting" do
    before do
      stub_connection(current_user: manager)
      subscribe(room_id: room.id)
    end

    it "broadcasts floor_plan_updated when floor plan changes" do
      floor_plan = [{ type: 'rectangle', x: 0, y: 0, width: 100, height: 100 }]

      expect {
        room.update(floor_plan_data: floor_plan)
      }.to have_broadcasted_to(room).with(
        hash_including(type: "floor_plan_updated")
      )
    end
  end
end
