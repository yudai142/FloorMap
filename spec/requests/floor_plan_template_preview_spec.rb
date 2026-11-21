require "rails_helper"
require "tempfile"

RSpec.describe "FloorPlanTemplate preview image", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:template) { create(:floor_plan_template, user: user) }

  def png_upload
    file = Tempfile.new([ "preview", ".png" ], binmode: true)
    file.write("\x89PNG\r\n\x1a\n".b + "dummy".b)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, "image/png", original_filename: "preview.png")
  end

  describe "PATCH /floor_plan_templates/:id/preview" do
    it "attaches the uploaded PNG to the owner's template" do
      sign_in user

      patch preview_floor_plan_template_path(template), params: { preview_image: png_upload }

      expect(response).to have_http_status(:ok)
      expect(template.reload.preview_image).to be_attached
      expect(template.preview_image.content_type).to eq("image/png")
    end

    it "rejects a non-PNG file" do
      sign_in user
      text = Rack::Test::UploadedFile.new(StringIO.new("hello"), "text/plain", original_filename: "a.txt")

      patch preview_floor_plan_template_path(template), params: { preview_image: text }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(template.reload.preview_image).not_to be_attached
    end

    it "forbids replacing another user's template preview" do
      other = create(:floor_plan_template, user: other_user)
      sign_in user

      patch preview_floor_plan_template_path(other), params: { preview_image: png_upload }

      expect(response).to redirect_to(root_path)
      expect(other.reload.preview_image).not_to be_attached
    end
  end

  describe "GET /floor_plan_templates/:id/preview_svg" do
    let(:template) do
      create(:floor_plan_template, user: user, floor_plan_data: [
        { "type" => "rectangle", "x" => 10, "y" => 20, "width" => 100, "height" => 50, "color" => "#3b82f6" }
      ])
    end

    it "renders the current floor plan as SVG without a stored image" do
      sign_in user

      get preview_svg_floor_plan_template_path(template)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("image/svg+xml")
      expect(response.body).to include('<rect x="10.0" y="20.0" width="100.0" height="50.0"')
      expect(response.headers["Content-Security-Policy"]).to include("default-src 'none'")
    end

    it "hides a private template of another user" do
      other = create(:floor_plan_template, user: other_user, is_public: false)
      sign_in user

      get preview_svg_floor_plan_template_path(other)

      expect(response).to redirect_to(floor_plan_templates_path)
    end
  end

  describe "listing templates" do
    it "gives every template a live preview URL" do
      sign_in user
      template

      get floor_plan_templates_path

      expect(response.body).to include("preview_svg")
    end
  end
end
