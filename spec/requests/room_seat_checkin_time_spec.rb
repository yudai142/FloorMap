require "rails_helper"

RSpec.describe "Room seat check-in time", type: :request do
  let(:user) { create(:user) }

  it "includes the check-in time of active sessions in the room data" do
    room = create(:room, user: user)
    seat = create(:seat, room: room, row_number: 0, column_number: 1)
    session = create(:session, user: user, seat: seat, status: :active, check_in_time: Time.zone.parse("2026-11-28 09:30:00"))
    sign_in user

    get "/rooms/#{room.share_token}/canvas_data", headers: { "Accept" => "application/json" }

    item = response.parsed_body["sessions"].find { |s| s["id"] == session.id }
    expect(item["check_in_time"]).to be_present
  end
end
