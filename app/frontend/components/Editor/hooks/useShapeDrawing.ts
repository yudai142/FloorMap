import { useCallback } from 'react'
import { useEditorStore } from '../../../store/editorStore'
import type { Shape } from '../../../types/Canvas'
import { snapLineToAxis } from '../utils/snapToGrid'

export const useShapeDrawing = () => {
  const { addShape, saveToHistory, shapes, seats, selectedColor } = useEditorStore()

  const generateId = useCallback((type: string) => {
    return `${type}-${Date.now()}`
  }, [])

  const addLine = useCallback(
    (x1: number, y1: number, x2: number, y2: number) => {
      const snapped = snapLineToAxis(x1, y1, x2, y2)
      const newLine: Shape = {
        id: generateId('line'),
        type: 'line',
        x1,
        y1,
        x2: snapped.x2,
        y2: snapped.y2,
        color: selectedColor,
      }
      addShape(newLine)
      saveToHistory(seats, [...shapes, newLine])
    },
    [generateId, selectedColor, addShape, saveToHistory, shapes, seats]
  )

  const addRectangle = useCallback(
    (x: number, y: number, width: number, height: number) => {
      const newRect: Shape = {
        id: generateId('rect'),
        type: 'rectangle',
        x: Math.min(x, x + width),
        y: Math.min(y, y + height),
        width: Math.abs(width),
        height: Math.abs(height),
        color: selectedColor,
      }
      addShape(newRect)
      saveToHistory(seats, [...shapes, newRect])
    },
    [generateId, selectedColor, addShape, saveToHistory, shapes, seats]
  )

  const addCircle = useCallback(
    (cx: number, cy: number, radius: number) => {
      const newCircle: Shape = {
        id: generateId('circle'),
        type: 'circle',
        cx,
        cy,
        r: radius,
        color: selectedColor,
      }
      addShape(newCircle)
      saveToHistory(seats, [...shapes, newCircle])
    },
    [generateId, selectedColor, addShape, saveToHistory, shapes, seats]
  )

  const addArrow = useCallback(
    (x1: number, y1: number, x2: number, y2: number) => {
      const snapped = snapLineToAxis(x1, y1, x2, y2)
      const newArrow: Shape = {
        id: generateId('arrow'),
        type: 'arrow',
        x1,
        y1,
        x2: snapped.x2,
        y2: snapped.y2,
        color: selectedColor,
      }
      addShape(newArrow)
      saveToHistory(seats, [...shapes, newArrow])
    },
    [generateId, selectedColor, addShape, saveToHistory, shapes, seats]
  )

  const addText = useCallback(
    (x: number, y: number, text: string) => {
      if (!text.trim()) return

      const newText: Shape = {
        id: generateId('text'),
        type: 'text',
        x,
        y,
        text,
        color: selectedColor,
      }
      addShape(newText)
      saveToHistory(seats, [...shapes, newText])
    },
    [generateId, selectedColor, addShape, saveToHistory, shapes, seats]
  )

  const addPolygon = useCallback(
    (points: Array<{ x: number; y: number }>) => {
      if (points.length < 3) return

      const pointsStr = points.map((p) => `${p.x},${p.y}`).join(' ')
      const newPolygon: Shape = {
        id: generateId('polygon'),
        type: 'polygon',
        points: pointsStr,
        pointsArray: points,
        color: selectedColor,
      }
      addShape(newPolygon)
      saveToHistory(seats, [...shapes, newPolygon])
    },
    [generateId, selectedColor, addShape, saveToHistory, shapes, seats]
  )

  return {
    addLine,
    addRectangle,
    addCircle,
    addArrow,
    addText,
    addPolygon,
  }
}
