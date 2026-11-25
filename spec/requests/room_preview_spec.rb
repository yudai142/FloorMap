require "rails_helper"

RSpec.describe "Room preview image", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe "GET /rooms/:share_token/preview_svg" do
    it "renders the room's shapes and seats for its owner" do
      room = create(:room, user: user, floor_plan_data: [ { "type" => "rectangle", "x" => 10, "y" => 20, "width" => 100, "height" => 50, "color" => "#3b82f6" } ])
      create(:seat, room: room, position_x: 120, position_y: 80, row_number: 80, column_number: 120)
      sign_in user

      get "/rooms/#{room.share_token}/preview_svg"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("image/svg+xml")
      expect(response.body).to include('<rect x="10.0" y="20.0" width="100.0" height="50.0"')
      expect(response.body).to include('transform="translate(120.0, 80.0)"')
    end

    it "does not render a room the user cannot view" do
      room = create(:room, user: other_user)
      sign_in user

      get "/rooms/#{room.share_token}/preview_svg"

      expect(response).not_to have_http_status(:ok)
      expect(response.body).not_to include("<svg")
    end
  end

  describe "room list" do
    it "gives each of the user's rooms a preview URL" do
      room = create(:room, user: user, name: "プレビュー確認ルーム")
      sign_in user

      get rooms_path

      expect(CGI.unescapeHTML(response.body)).to include("preview_svg")
      expect(room.share_token).to be_present
    end
  end
end
