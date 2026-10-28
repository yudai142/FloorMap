require "rails_helper"

RSpec.describe "FloorPlanTemplateSeats", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:template) { create(:floor_plan_template, user: user) }
  let(:json_headers) { { "Accept" => "application/json", "Content-Type" => "application/json" } }

  describe "POST /floor_plan_templates/:id/seats" do
    before { sign_in user }

    it "creates a seat on the template" do
      expect {
        post floor_plan_template_seats_path(template),
             params: { seat: { position_x: 120, position_y: 80, seat_type: "regular" } }.to_json,
             headers: json_headers
      }.to change(template.template_seats, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include("position_x" => 120.0, "position_y" => 80.0, "seat_type" => "regular")
    end

    it "rejects a seat at an occupied position" do
      create(:floor_plan_template_seat, floor_plan_template: template, position_x: 120, position_y: 80)

      post floor_plan_template_seats_path(template),
           params: { seat: { position_x: 120, position_y: 80, seat_type: "regular" } }.to_json,
           headers: json_headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "forbids adding seats to another user's template" do
      other = create(:floor_plan_template, user: other_user)

      post floor_plan_template_seats_path(other),
           params: { seat: { position_x: 1, position_y: 1, seat_type: "regular" } }.to_json,
           headers: json_headers

      expect(response).to have_http_status(:forbidden)
      expect(other.template_seats.count).to eq(0)
    end
  end

  describe "PATCH /floor_plan_templates/:id/seats/:seat_id/position" do
    let(:seat) { create(:floor_plan_template_seat, floor_plan_template: template, position_x: 10, position_y: 20) }

    before { sign_in user }

    it "moves the seat" do
      patch position_floor_plan_template_seat_path(template, seat),
            params: { seat: { position_x: 300, position_y: 400 } }.to_json,
            headers: json_headers

      expect(response).to have_http_status(:ok)
      expect(seat.reload).to have_attributes(position_x: 300, position_y: 400)
    end
  end

  describe "DELETE /floor_plan_templates/:id/seats/:seat_id" do
    let!(:seat) { create(:floor_plan_template_seat, floor_plan_template: template) }

    before { sign_in user }

    it "removes the seat" do
      expect {
        delete floor_plan_template_seat_path(template, seat), headers: json_headers
      }.to change(FloorPlanTemplateSeat, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end

  describe "creating a room from a template" do
    before { sign_in user }

    it "carries the selected template into the new room form" do
      template = create(:floor_plan_template, user: user)

      get new_room_path(template_id: template.id)

      expect(CGI.unescapeHTML(response.body)).to include(%("floor_plan_template_id":#{template.id}))
    end

    it "does not carry a template the user cannot read" do
      other_private = create(:floor_plan_template, user: other_user, is_public: false)

      get new_room_path(template_id: other_private.id)

      expect(CGI.unescapeHTML(response.body)).to include(%("floor_plan_template_id":null))
    end

    it "copies the template seats into the room" do
      create(:floor_plan_template_seat, floor_plan_template: template, position_x: 40, position_y: 40, seat_type: "vip")
      create(:floor_plan_template_seat, floor_plan_template: template, position_x: 120, position_y: 40)

      expect {
        post rooms_path, params: { room: { name: "会議室A", floor_plan_template_id: template.id } },
                         headers: { "Accept" => "application/json" }
      }.to change(Seat, :count).by(2)

      room = Room.find_by!(name: "会議室A")
      expect(room.seats.pluck(:position_x, :position_y, :seat_type)).to match_array([ [ 40.0, 40.0, "vip" ], [ 120.0, 40.0, "regular" ] ])
    end
  end
end
