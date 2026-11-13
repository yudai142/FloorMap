class FloorPlanPreviewSvg
  WIDTH = 1000
  HEIGHT = 700
  PADDING = 20
  MIN_SIZE = 40
  SEAT_COLOR = "#4ade80".freeze
  SEAT_STROKE = "#065f46".freeze

  def initialize(template)
    @template = template
  end

  def render
    elements = shapes.filter_map { |shape| shape_svg(shape) } + seats.map { |seat| seat_svg(seat) }
    box = content_box

    %(<svg xmlns="http://www.w3.org/2000/svg" width="#{num(box[:width])}" height="#{num(box[:height])}" viewBox="#{num(box[:x])} #{num(box[:y])} #{num(box[:width])} #{num(box[:height])}">) +
      %(<rect x="#{num(box[:x])}" y="#{num(box[:y])}" width="#{num(box[:width])}" height="#{num(box[:height])}" fill="#ffffff"/>) +
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

  def content_box
    points = shapes.flat_map { |shape| shape_points(shape) } + seats.flat_map { |seat| seat_points(seat) }
    return { x: 0, y: 0, width: WIDTH, height: HEIGHT } if points.empty?

    xs = points.map(&:first)
    ys = points.map(&:last)
    width = [ xs.max - xs.min, MIN_SIZE ].max + 2 * PADDING
    height = [ ys.max - ys.min, MIN_SIZE ].max + 2 * PADDING

    { x: xs.min - PADDING, y: ys.min - PADDING, width: width, height: height }
  end

  def shape_points(shape)
    case shape[:type]
    when "rectangle"
      x, y = shape[:x].to_f, shape[:y].to_f
      [ [ x, y ], [ x + shape[:width].to_f, y + shape[:height].to_f ] ]
    when "line", "arrow"
      [ [ shape[:x1].to_f, shape[:y1].to_f ], [ shape[:x2].to_f, shape[:y2].to_f ] ]
    when "circle"
      cx, cy, r = shape[:cx].to_f, shape[:cy].to_f, shape[:r].to_f
      [ [ cx - r, cy - r ], [ cx + r, cy + r ] ]
    when "text"
      x, y = shape[:x].to_f, shape[:y].to_f
      [ [ x, y - 14 ], [ x + shape[:text].to_s.length * 8, y + 4 ] ]
    when "polygon"
      Array(shape[:pointsArray]).map { |point| [ point[:x].to_f, point[:y].to_f ] }
    else
      []
    end
  end

  def seat_points(seat)
    x, y = seat.position_x.to_f, seat.position_y.to_f
    [ [ x - 12, y - 12 ], [ x + 60, y + 12 ] ]
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
