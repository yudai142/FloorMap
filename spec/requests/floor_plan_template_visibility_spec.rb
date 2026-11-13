require "rails_helper"

RSpec.describe "FloorPlanTemplate visibility", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe "viewing a template" do
    before { sign_in user }

    it "shows a public template of another user" do
      template = create(:floor_plan_template, user: other_user, is_public: true)
      get floor_plan_template_path(template)
      expect(response).to have_http_status(:success)
    end

    it "hides a private template of another user" do
      template = create(:floor_plan_template, user: other_user, is_public: false)
      get floor_plan_template_path(template)
      expect(response).to redirect_to(floor_plan_templates_path)
    end

    it "hides the details page of a private template of another user" do
      template = create(:floor_plan_template, user: other_user, is_public: false)
      get details_floor_plan_template_path(template)
      expect(response).to redirect_to(floor_plan_templates_path)
    end

    it "lets an admin view a private template of another user" do
      admin = create(:user, role: :admin)
      sign_in admin
      template = create(:floor_plan_template, user: other_user, is_public: false)
      get floor_plan_template_path(template)
      expect(response).to have_http_status(:success)
    end
  end

  describe "saving visibility from the details form" do
    let(:template) { create(:floor_plan_template, user: user, is_public: false) }

    before { sign_in user }

    it "returns success for a JSON request so the form can navigate away" do
      patch floor_plan_template_path(template),
            params: { floor_plan_template: { name: template.name, description: "説明", is_public: true } }.to_json,
            headers: { "Content-Type" => "application/json", "Accept" => "application/json" }

      expect(response).to have_http_status(:ok)
      expect(template.reload.is_public).to be(true)
    end

    it "returns success when the client sends the default fetch Accept header" do
      patch floor_plan_template_path(template),
            params: { floor_plan_template: { name: template.name, description: "説明", is_public: true } }.to_json,
            headers: { "Content-Type" => "application/json", "Accept" => "*/*" }

      expect(response).to have_http_status(:ok)
      expect(template.reload.is_public).to be(true)
    end
  end

  describe "listing templates" do
    before { sign_in user }

    it "lists public templates of other users on the public page, not their private ones" do
      create(:floor_plan_template, user: other_user, is_public: true, name: "公開テンプレートX")
      create(:floor_plan_template, user: other_user, is_public: false, name: "非公開テンプレートY")

      get public_floor_plan_templates_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("公開テンプレートX")
      expect(response.body).not_to include("非公開テンプレートY")
    end

    it "shows only my templates on the my templates page" do
      create(:floor_plan_template, user: user, name: "マイテンプレートZ")
      create(:floor_plan_template, user: other_user, is_public: true, name: "他人の公開テンプレートW")

      get floor_plan_templates_path
      expect(response.body).to include("マイテンプレートZ")
      expect(response.body).not_to include("他人の公開テンプレートW")
    end
  end

  describe "creating a room from a template" do
    before { sign_in user }

    it "allows a public template of another user" do
      template = create(:floor_plan_template, user: other_user, is_public: true)

      expect {
        post rooms_path, params: { room: { name: "公開会議室", floor_plan_template_id: template.id } },
                         headers: { "Accept" => "application/json" }
      }.to change(Room, :count).by(1)
    end

    it "rejects a private template of another user" do
      template = create(:floor_plan_template, user: other_user, is_public: false)

      expect {
        post rooms_path, params: { room: { name: "非公開会議室", floor_plan_template_id: template.id } },
                         headers: { "Accept" => "application/json" }
      }.not_to change(Room, :count)
      expect(response).to have_http_status(:not_found)
    end
  end
end
