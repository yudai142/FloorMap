require "rails_helper"

RSpec.describe "FloorPlanTemplate favorites", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe "POST /floor_plan_templates/:id/favorite" do
    it "adds a public template of another user once" do
      template = create(:floor_plan_template, user: other_user, is_public: true)
      sign_in user

      2.times { post favorite_floor_plan_template_path(template) }

      expect(response).to have_http_status(:ok)
      expect(template.favorites.where(user: user).count).to eq(1)
    end

    it "does not allow favoriting a private template of another user" do
      template = create(:floor_plan_template, user: other_user, is_public: false)
      sign_in user

      expect { post favorite_floor_plan_template_path(template) }.not_to change(FloorPlanTemplateFavorite, :count)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /floor_plan_templates/:id/favorite" do
    it "removes the favorite" do
      template = create(:floor_plan_template, user: other_user, is_public: true)
      template.favorites.create!(user: user)
      sign_in user

      delete favorite_floor_plan_template_path(template)

      expect(response).to have_http_status(:no_content)
      expect(template.favorites.where(user: user)).to be_empty
    end
  end

  describe "favorited flag in the public list" do
    it "marks the templates the user has favorited" do
      fav = create(:floor_plan_template, user: other_user, is_public: true, name: "お気に入りX")
      create(:floor_plan_template, user: other_user, is_public: true, name: "未登録Y")
      fav.favorites.create!(user: user)
      sign_in user

      get public_floor_plan_templates_path

      body = CGI.unescapeHTML(response.body)
      expect(body).to include("お気に入りX")
      expect(body).to match(/"favorited":true/)
      expect(body).to match(/"favorited":false/)
    end
  end

  describe "GET /floor_plan_templates/favorites" do
    it "lists only the templates the user has favorited" do
      fav = create(:floor_plan_template, user: other_user, is_public: true, name: "お気に入りP")
      create(:floor_plan_template, user: other_user, is_public: true, name: "未登録Q")
      fav.favorites.create!(user: user)
      sign_in user

      get favorites_floor_plan_templates_path

      body = CGI.unescapeHTML(response.body)
      expect(response).to have_http_status(:ok)
      expect(body).to include("お気に入りP")
      expect(body).not_to include("未登録Q")
    end
  end
end
