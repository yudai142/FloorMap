require "rails_helper"

RSpec.describe ApplicationPolicy do
  subject { described_class }

  let(:user) { create(:user) }

  permissions :index?, :show? do
    it "grants access" do
      expect(ApplicationPolicy.new(user, User.new)).to permit_action(:index?)
    end
  end
end
