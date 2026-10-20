require "rails_helper"

RSpec.describe FloorPlanPreviewSvg do
  let(:user) { create(:user) }

  it "draws rectangles, lines, and polygons from the floor plan data" do
    template = create(:floor_plan_template, user: user, floor_plan_data: [
      { "type" => "rectangle", "x" => 10, "y" => 20, "width" => 100, "height" => 50, "color" => "#3b82f6" },
      { "type" => "line", "x1" => 0, "y1" => 0, "x2" => 50, "y2" => 60, "color" => "#ef4444" },
      { "type" => "polygon", "pointsArray" => [ { "x" => 0, "y" => 0 }, { "x" => 30, "y" => 0 }, { "x" => 15, "y" => 30 } ], "color" => "#22c55e" }
    ])

    svg = described_class.new(template).render

    expect(svg).to include('<rect x="10.0" y="20.0" width="100.0" height="50.0"')
    expect(svg).to include('<line x1="0.0" y1="0.0" x2="50.0" y2="60.0"')
    expect(svg).to include('<polygon points="0.0,0.0 30.0,0.0 15.0,30.0"')
  end

  it "draws seats at their positions" do
    template = create(:floor_plan_template, user: user)
    create(:floor_plan_template_seat, floor_plan_template: template, position_x: 120, position_y: 80)

    svg = described_class.new(template.reload).render

    expect(svg).to include('transform="translate(120.0, 80.0)"')
  end

  it "escapes user-provided text" do
    template = create(:floor_plan_template, user: user, floor_plan_data: [
      { "type" => "text", "x" => 5, "y" => 5, "text" => "<script>alert(1)</script>", "color" => "#000" }
    ])

    svg = described_class.new(template).render

    expect(svg).not_to include("<script>")
    expect(svg).to include("&lt;script&gt;alert(1)&lt;/script&gt;")
  end
end
