require "rails_helper"

RSpec.describe "Importing a template into a room", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe "GET /floor_plan_templates/:id/content" do
    it "returns the shapes and seats of a template the user can read" do
      template = create(:floor_plan_template, user: user, floor_plan_data: [ { "type" => "rectangle", "x" => 5, "y" => 6, "width" => 7, "height" => 8 } ])
      create(:floor_plan_template_seat, floor_plan_template: template, position_x: 40, position_y: 50, seat_type: "vip")
      sign_in user

      get content_floor_plan_template_path(template), headers: { "Accept" => "application/json" }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["floor_plan_data"].first).to include("type" => "rectangle", "x" => 5)
      expect(body["seats"]).to eq([ { "position_x" => 40.0, "position_y" => 50.0, "seat_type" => "vip" } ])
    end

    it "does not return a private template of another user" do
      template = create(:floor_plan_template, user: other_user, is_public: false)
      sign_in user

      get content_floor_plan_template_path(template), headers: { "Accept" => "application/json" }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /rooms/:share_token/canvas_editor" do
    it "lists the templates the user can read" do
      room = create(:room, user: user)
      create(:floor_plan_template, user: user, name: "自分のテンプレートA")
      create(:floor_plan_template, user: other_user, is_public: true, name: "公開テンプレートB")
      create(:floor_plan_template, user: other_user, is_public: false, name: "非公開テンプレートC")
      sign_in user

      get "/rooms/#{room.share_token}/canvas_editor"

      body = CGI.unescapeHTML(response.body)
      expect(body).to include("自分のテンプレートA")
      expect(body).to include("公開テンプレートB")
      expect(body).not_to include("非公開テンプレートC")
    end
  end

  describe "template detail page and room editor preselection" do
    it "lists the user's rooms on the template page" do
      room = create(:room, user: user, name: "自分のルームX")
      template = create(:floor_plan_template, user: user)
      sign_in user

      get floor_plan_template_path(template)

      expect(CGI.unescapeHTML(response.body)).to include("自分のルームX")
      expect(CGI.unescapeHTML(response.body)).to include(room.share_token)
    end

    it "preselects a readable template given in the room editor URL" do
      room = create(:room, user: user)
      template = create(:floor_plan_template, user: user)
      sign_in user

      get "/rooms/#{room.share_token}/canvas_editor?template_id=#{template.id}"

      expect(CGI.unescapeHTML(response.body)).to include(%("initial_template_id":#{template.id}))
    end
  end

  describe "GET /floor_plan_templates/:id/rooms" do
    it "lists only the user's own rooms" do
      create(:room, user: user, name: "自分のルームP")
      create(:room, user: other_user, name: "他人のルームQ")
      template = create(:floor_plan_template, user: user)
      sign_in user

      get rooms_floor_plan_template_path(template)

      body = CGI.unescapeHTML(response.body)
      expect(body).to include("自分のルームP")
      expect(body).not_to include("他人のルームQ")
    end

    it "redirects when the template is not readable" do
      template = create(:floor_plan_template, user: other_user, is_public: false)
      sign_in user

      get rooms_floor_plan_template_path(template)

      expect(response).to redirect_to(floor_plan_templates_path)
    end
  end
end
