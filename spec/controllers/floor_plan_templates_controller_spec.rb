require "rails_helper"

RSpec.describe FloorPlanTemplatesController, type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before { sign_in user }

  describe "GET /floor_plan_templates" do
    it "returns http success" do
      get floor_plan_templates_path
      expect(response).to have_http_status(:success)
    end

    it "assigns user's templates" do
      template = create(:floor_plan_template, user: user)
      get floor_plan_templates_path
      expect(assigns(:my_templates)).to include(template)
    end

    it "assigns public templates" do
      template = create(:floor_plan_template, user: other_user, is_public: true)
      get floor_plan_templates_path
      expect(assigns(:public_templates)).to include(template)
    end
  end

  describe "GET /floor_plan_templates/:id" do
    let(:template) { create(:floor_plan_template, user: user) }

    it "returns http success" do
      get floor_plan_template_path(template)
      expect(response).to have_http_status(:success)
    end

    it "assigns the template" do
      get floor_plan_template_path(template)
      expect(assigns(:template)).to eq(template)
    end
  end

  describe "POST /floor_plan_templates" do
    let(:valid_params) do
      {
        floor_plan_template: {
          name: "Test Template",
          description: "Test description",
          floor_plan_data: [],
          is_public: false
        }
      }
    end

    it "creates a new template" do
      expect {
        post floor_plan_templates_path, params: valid_params
      }.to change(FloorPlanTemplate, :count).by(1)
    end

    it "redirects to index" do
      post floor_plan_templates_path, params: valid_params
      expect(response).to redirect_to(floor_plan_templates_path)
    end

    it "shows success notice" do
      post floor_plan_templates_path, params: valid_params
      expect(flash[:notice]).to include("テンプレートが作成されました")
    end
  end

  describe "DELETE /floor_plan_templates/:id" do
    let(:template) { create(:floor_plan_template, user: user) }

    it "deletes the template" do
      expect {
        delete floor_plan_template_path(template)
      }.to change(FloorPlanTemplate, :count).by(-1)
    end

    it "redirects to index" do
      delete floor_plan_template_path(template)
      expect(response).to redirect_to(floor_plan_templates_path)
    end

    it "shows success notice" do
      delete floor_plan_template_path(template)
      expect(flash[:notice]).to include("テンプレートが削除されました")
    end
  end

  describe "authorization" do
    let(:other_template) { create(:floor_plan_template, user: other_user) }

    it "allows deletion of own template" do
      template = create(:floor_plan_template, user: user)
      expect {
        delete floor_plan_template_path(template)
      }.to change(FloorPlanTemplate, :count).by(-1)
    end

    it "denies deletion of other user's template" do
      expect {
        delete floor_plan_template_path(other_template)
      }.not_to change(FloorPlanTemplate, :count)
      expect(response).to redirect_to(root_path)
    end
  end
end
