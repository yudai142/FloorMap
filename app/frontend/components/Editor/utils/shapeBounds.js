export const SEAT_BOUNDS = { left: 12, top: 12, right: 60, bottom: 12 }

export function seatBounds(x, y) {
  return { minX: x - SEAT_BOUNDS.left, minY: y - SEAT_BOUNDS.top, maxX: x + SEAT_BOUNDS.right, maxY: y + SEAT_BOUNDS.bottom }
}

export function getShapeBounds(shape) {
  let points
  switch (shape.type) {
    case 'rectangle':
      points = [[shape.x, shape.y], [shape.x + shape.width, shape.y + shape.height]]
      break
    case 'line':
    case 'arrow':
      points = [[shape.x1, shape.y1], [shape.x2, shape.y2]]
      break
    case 'circle':
      points = [[shape.cx - shape.r, shape.cy - shape.r], [shape.cx + shape.r, shape.cy + shape.r]]
      break
    case 'text':
      points = [[shape.x, shape.y - 14], [shape.x + shape.text.length * 8, shape.y + 4]]
      break
    case 'polygon':
      points = (shape.pointsArray || []).map((p) => [p.x, p.y])
      break
    default:
      return null
  }
  if (points.length === 0) return null
  const xs = points.map((p) => p[0])
  const ys = points.map((p) => p[1])
  return { minX: Math.min(...xs), minY: Math.min(...ys), maxX: Math.max(...xs), maxY: Math.max(...ys) }
}

export function isBoundsInside(bounds, box) {
  return (
    bounds.minX >= box.x &&
    bounds.maxX <= box.x + box.width &&
    bounds.minY >= box.y &&
    bounds.maxY <= box.y + box.height
  )
}

export function offsetShape(shape, dx, dy) {
  switch (shape.type) {
    case 'rectangle':
      return { x: shape.x + dx, y: shape.y + dy }
    case 'line':
    case 'arrow':
      return { x1: shape.x1 + dx, y1: shape.y1 + dy, x2: shape.x2 + dx, y2: shape.y2 + dy }
    case 'circle':
      return { cx: shape.cx + dx, cy: shape.cy + dy }
    case 'text':
      return { x: shape.x + dx, y: shape.y + dy }
    case 'polygon': {
      const pointsArray = (shape.pointsArray || []).map((p) => ({ x: p.x + dx, y: p.y + dy }))
      return { pointsArray, points: pointsArray.map((p) => `${p.x},${p.y}`).join(' ') }
    }
    default:
      return {}
  }
}

const PLACEMENT_MARGIN = 10
const PLACEMENT_STEP = 20
const PLACEMENT_PADDING = 20

export function unionBounds(boundsList) {
  const present = boundsList.filter(Boolean)
  if (present.length === 0) return null
  return {
    minX: Math.min(...present.map((b) => b.minX)),
    minY: Math.min(...present.map((b) => b.minY)),
    maxX: Math.max(...present.map((b) => b.maxX)),
    maxY: Math.max(...present.map((b) => b.maxY)),
  }
}

function overlapsWithMargin(box, others) {
  return others.some(
    (o) =>
      box.minX < o.maxX + PLACEMENT_MARGIN &&
      box.maxX + PLACEMENT_MARGIN > o.minX &&
      box.minY < o.maxY + PLACEMENT_MARGIN &&
      box.maxY + PLACEMENT_MARGIN > o.minY
  )
}

// Returns the offset that puts the template in the first free spot (scanning from top-left),
// or, if none fits, to the right of the existing content with the canvas size to widen to.
export function findFreePlacement(occupied, template, canvas) {
  const width = template.maxX - template.minX
  const height = template.maxY - template.minY

  for (let y = 0; y + height <= canvas.height; y += PLACEMENT_STEP) {
    for (let x = 0; x + width <= canvas.width; x += PLACEMENT_STEP) {
      const offsetX = x - template.minX
      const offsetY = y - template.minY
      const box = {
        minX: template.minX + offsetX,
        minY: template.minY + offsetY,
        maxX: template.maxX + offsetX,
        maxY: template.maxY + offsetY,
      }
      if (!overlapsWithMargin(box, occupied)) {
        return { offsetX, offsetY, width: canvas.width, height: canvas.height }
      }
    }
  }

  const right = occupied.length > 0 ? Math.max(...occupied.map((o) => o.maxX)) + PLACEMENT_MARGIN : 0
  const offsetX = right - template.minX
  const offsetY = -template.minY
  return {
    offsetX,
    offsetY,
    width: Math.max(canvas.width, offsetX + template.maxX + PLACEMENT_PADDING),
    height: Math.max(canvas.height, offsetY + template.maxY + PLACEMENT_PADDING),
  }
}
