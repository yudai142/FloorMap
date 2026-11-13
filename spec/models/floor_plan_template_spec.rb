require "rails_helper"

RSpec.describe FloorPlanTemplate, type: :model do
  let(:user) { create(:user) }

  describe "associations" do
    it "belongs to user" do
      template = build(:floor_plan_template, user: user)
      expect(template).to respond_to(:user)
    end
  end

  describe "validations" do
    it "validates presence of name" do
      template = build(:floor_plan_template, user: user, name: nil)
      expect(template).not_to be_valid
    end

    it "validates presence of floor_plan_data" do
      template = build(:floor_plan_template, user: user, floor_plan_data: nil)
      expect(template).not_to be_valid
    end

    it "validates floor_plan_data is valid JSON" do
      template = build(:floor_plan_template, user: user, floor_plan_data: "invalid")
      expect(template).not_to be_valid
    end

    it "accepts array floor_plan_data" do
      template = build(:floor_plan_template, user: user, floor_plan_data: [])
      expect(template).to be_valid
    end

    it "accepts hash floor_plan_data" do
      template = build(:floor_plan_template, user: user, floor_plan_data: {})
      expect(template).to be_valid
    end
  end

  describe "scopes" do
    before do
      create(:floor_plan_template, user: user, is_public: true)
      create(:floor_plan_template, user: user, is_public: false)
    end

    it ".public_templates returns only public templates" do
      public_count = FloorPlanTemplate.public_templates.count
      expect(public_count).to eq(1)
    end

    it ".by_user returns templates by specific user" do
      other_user = create(:user)
      create(:floor_plan_template, user: other_user)

      count = FloorPlanTemplate.by_user(user).count
      expect(count).to eq(2)
    end

    it ".recent returns templates ordered by created_at desc" do
      templates = FloorPlanTemplate.recent
      expect(templates.first.created_at).to be >= templates.last.created_at
    end
  end

  describe "#public?" do
    it "returns true when is_public is true" do
      template = build(:floor_plan_template, user: user, is_public: true)
      expect(template.public?).to be true
    end

    it "returns false when is_public is false" do
      template = build(:floor_plan_template, user: user, is_public: false)
      expect(template.public?).to be false
    end
  end

  describe "#increment_usage!" do
    it "increments usage_count" do
      template = create(:floor_plan_template, user: user, usage_count: 0)
      template.increment_usage!
      expect(template.reload.usage_count).to eq(1)
    end
  end
end
