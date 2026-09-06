// Grid snapping utilities
export const GRID_SIZE = 10

export const snapToGrid = (value: number, gridSize: number = GRID_SIZE): number => {
  return Math.round(value / gridSize) * gridSize
}

// Line axis snapping - snap to horizontal or vertical if within threshold
export const snapLineToAxis = (
  x1: number,
  y1: number,
  x2: number,
  y2: number,
  threshold: number = 8
): { x2: number; y2: number } => {
  const deltaX = Math.abs(x2 - x1)
  const deltaY = Math.abs(y2 - y1)
  const maxDelta = Math.max(deltaX, deltaY)

  // If within threshold of horizontal/vertical, snap to it
  if (deltaX < threshold && deltaX < deltaY) {
    // Snap to vertical line
    return { x2: x1, y2 }
  } else if (deltaY < threshold && deltaY < deltaX) {
    // Snap to horizontal line
    return { x2, y2: y1 }
  } else if (maxDelta > 20) {
    // Angle-based snapping for longer lines
    const angle = Math.atan2(deltaY, deltaX) * (180 / Math.PI)
    if (angle > -15 && angle < 15) {
      return { x2, y2: y1 } // Horizontal
    } else if (angle > 75 || angle < -75) {
      return { x2: x1, y2 } // Vertical
    }
  }

  return { x2, y2 }
}

// Distance from point to line segment
export const distanceToLine = (px: number, py: number, x1: number, y1: number, x2: number, y2: number): number => {
  const A = px - x1
  const B = py - y1
  const C = x2 - x1
  const D = y2 - y1

  const dot = A * C + B * D
  const lenSq = C * C + D * D
  let param = -1

  if (lenSq !== 0) param = dot / lenSq

  let xx, yy

  if (param < 0) {
    xx = x1
    yy = y1
  } else if (param > 1) {
    xx = x2
    yy = y2
  } else {
    xx = x1 + param * C
    yy = y1 + param * D
  }

  const dx = px - xx
  const dy = py - yy
  return Math.sqrt(dx * dx + dy * dy)
}

// Check if point is inside polygon
export const isPointInPolygon = (x: number, y: number, points: Array<{ x: number; y: number }>): boolean => {
  let inside = false
  for (let i = 0, j = points.length - 1; i < points.length; j = i++) {
    const xi = points[i].x
    const yi = points[i].y
    const xj = points[j].x
    const yj = points[j].y

    const intersect = yi > y !== yj > y && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi
    if (intersect) inside = !inside
  }
  return inside
}
