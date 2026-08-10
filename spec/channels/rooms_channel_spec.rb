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

    it "rejects subscription for unauthorized user" do
      stub_connection(current_user: regular_user)
      subscribe(room_id: room.id)

      expect(subscription).to be_rejected
    end
  end

  describe "broadcasting" do
    it "broadcasts seat update when seat changes" do
      stub_connection(current_user: manager)
      subscribe(room_id: room.id)

      seat = create(:seat, room: room)
      user = create(:user)
      session = create(:session, seat: seat, user: user)

      expect {
        session.update(status: :completed)
      }.to have_broadcasted_to(room).with(hash_including(type: "seat_updated"))
    end
  end
end
