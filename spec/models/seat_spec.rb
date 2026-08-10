require "rails_helper"

RSpec.describe Seat, type: :model do
  describe "associations" do
    it "belongs to room" do
      seat = build(:seat)
      expect(seat).to respond_to(:room)
    end
  end

  describe "validations" do
    it "validates presence of room_id" do
      seat = build(:seat, room_id: nil)
      expect(seat).not_to be_valid
      expect(seat.errors[:room_id]).to be_present
    end

    it "validates presence of row_number" do
      seat = build(:seat, row_number: nil)
      expect(seat).not_to be_valid
      expect(seat.errors[:row_number]).to be_present
    end

    it "validates presence of column_number" do
      seat = build(:seat, column_number: nil)
      expect(seat).not_to be_valid
      expect(seat.errors[:column_number]).to be_present
    end

    it "validates presence of seat_type" do
      seat = build(:seat, seat_type: nil)
      expect(seat).not_to be_valid
    end

    context "uniqueness of row_number scoped to column_number and room_id" do
      let(:room) { create(:room) }

      it "allows same row_number in different rooms" do
        create(:seat, room:, row_number: 1, column_number: 1)
        seat2 = build(:seat, room: create(:room), row_number: 1, column_number: 1)
        expect(seat2).to be_valid
      end

      it "allows same row_number with different column_number in same room" do
        create(:seat, room:, row_number: 1, column_number: 1)
        seat2 = build(:seat, room:, row_number: 1, column_number: 2)
        expect(seat2).to be_valid
      end

      it "disallows duplicate row_number and column_number in same room" do
        create(:seat, room:, row_number: 1, column_number: 1)
        duplicate = build(:seat, room:, row_number: 1, column_number: 1)
        expect(duplicate).not_to be_valid
      end
    end
  end

  describe "enums" do
    it "has seat types" do
      seat = build(:seat, seat_type: :regular)
      expect(seat.regular?).to be true
    end

    it "has accessible seat type" do
      seat = build(:seat, :accessible)
      expect(seat.accessible?).to be true
    end

    it "has vip seat type" do
      seat = build(:seat, :vip)
      expect(seat.vip?).to be true
    end
  end

  describe "creation and persistence" do
    let(:room) { create(:room) }

    it "creates and persists valid seat" do
      seat = create(:seat, room:)
      expect(seat).to be_persisted
      expect(seat.room_id).to eq(room.id)
    end

    it "associates seat with room" do
      seat = create(:seat, room:)
      expect(seat.room).to eq(room)
    end
  end

  describe "seat identification" do
    it "generates seat_identifier from row and column" do
      seat = create(:seat, row_number: 0, column_number: 3)
      expect(seat.seat_identifier).to eq("A3")
    end

    it "converts row number to letter (0 = A)" do
      seat = create(:seat, row_number: 0)
      expect(seat.seat_identifier).to start_with("A")
    end

    it "converts row number to letter (1 = B)" do
      seat = create(:seat, row_number: 1)
      expect(seat.seat_identifier).to start_with("B")
    end
  end
end
