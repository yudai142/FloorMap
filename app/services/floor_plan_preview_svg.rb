class FloorPlanPreviewSvg
  WIDTH = 1000
  HEIGHT = 700
  SEAT_COLOR = "#4ade80".freeze
  SEAT_STROKE = "#065f46".freeze

  def initialize(template)
    @template = template
  end

  def render
    elements = shapes.filter_map { |shape| shape_svg(shape) } + seats.map { |seat| seat_svg(seat) }

    %(<svg xmlns="http://www.w3.org/2000/svg" width="#{WIDTH}" height="#{HEIGHT}" viewBox="0 0 #{WIDTH} #{HEIGHT}">) +
      %(<rect width="#{WIDTH}" height="#{HEIGHT}" fill="#ffffff"/>) +
      elements.join +
      "</svg>"
  end

  private

  def shapes
    Array(@template.floor_plan_data).map { |shape| shape.to_h.with_indifferent_access }
  end

  def seats
    @template.template_seats.order(:id)
  end

  def shape_svg(shape)
    case shape[:type]
    when "rectangle"
      %(<rect x="#{num(shape[:x])}" y="#{num(shape[:y])}" width="#{num(shape[:width])}" height="#{num(shape[:height])}" fill="#{attr(shape[:fill] || "none")}" stroke="#{attr(shape[:color] || "#ef4444")}" stroke-width="2"/>)
    when "line"
      %(<line x1="#{num(shape[:x1])}" y1="#{num(shape[:y1])}" x2="#{num(shape[:x2])}" y2="#{num(shape[:y2])}" stroke="#{attr(shape[:color] || "#3b82f6")}" stroke-width="2"/>)
    when "circle"
      %(<circle cx="#{num(shape[:cx])}" cy="#{num(shape[:cy])}" r="#{num(shape[:r])}" fill="#{attr(shape[:fill] || "none")}" stroke="#{attr(shape[:color] || "#8b5cf6")}" stroke-width="2"/>)
    when "arrow"
      arrow_svg(shape)
    when "text"
      %(<text x="#{num(shape[:x])}" y="#{num(shape[:y])}" font-size="14" fill="#{attr(shape[:color] || "#1e293b")}">#{ERB::Util.html_escape(shape[:text].to_s)}</text>)
    when "polygon"
      points = polygon_points(shape)
      return nil if points.empty?

      %(<polygon points="#{points}" fill="#{attr(shape[:fill] || "none")}" stroke="#{attr(shape[:color] || "#06b6d4")}" stroke-width="2"/>)
    end
  end

  def arrow_svg(shape)
    color = attr(shape[:color] || "#ec4899")
    x1, y1, x2, y2 = %i[x1 y1 x2 y2].map { |key| shape[key].to_f }
    angle = Math.atan2(y2 - y1, x2 - x1)
    head = 15
    head_points = [ angle - Math::PI / 6, angle + Math::PI / 6 ].map do |a|
      "#{num(x2 - head * Math.cos(a))},#{num(y2 - head * Math.sin(a))}"
    end

    %(<line x1="#{num(x1)}" y1="#{num(y1)}" x2="#{num(x2)}" y2="#{num(y2)}" stroke="#{color}" stroke-width="2"/>) +
      %(<polygon points="#{num(x2)},#{num(y2)} #{head_points.join(" ")}" fill="#{color}"/>)
  end

  def polygon_points(shape)
    points = Array(shape[:pointsArray]).map { |point| "#{num(point[:x])},#{num(point[:y])}" }
    points.join(" ")
  end

  def seat_svg(seat)
    %(<g transform="translate(#{num(seat.position_x)}, #{num(seat.position_y)})">) +
      %(<circle r="12" fill="#{SEAT_COLOR}" stroke="#{SEAT_STROKE}" stroke-width="2"/>) +
      %(<text x="16" y="4" font-size="12" fill="#000" font-weight="bold">S#{seat.id}</text>) +
      "</g>"
  end

  def num(value)
    value.to_f.to_s
  end

  def attr(value)
    ERB::Util.html_escape(value.to_s)
  end
end
