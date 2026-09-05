import { useCallback } from 'react'
import { useEditorStore } from '../../../store/editorStore'
import type { Shape } from '../../../types/Canvas'
import { snapLineToAxis } from '../utils/snapToGrid'

export const useShapePreview = () => {
  const { currentTool, selectedColor, setPreview } = useEditorStore()

  const updateLinePreview = useCallback(
    (x1: number, y1: number, x2: number, y2: number) => {
      const snapped = snapLineToAxis(x1, y1, x2, y2)
      setPreview({
        type: 'line',
        x1,
        y1,
        x2: snapped.x2,
        y2: snapped.y2,
      })
    },
    [setPreview]
  )

  const updateRectanglePreview = useCallback(
    (x: number, y: number, width: number, height: number) => {
      setPreview({
        type: 'rectangle',
        x: Math.min(x, x + width),
        y: Math.min(y, y + height),
        width: Math.abs(width),
        height: Math.abs(height),
      })
    },
    [setPreview]
  )

  const updateCirclePreview = useCallback(
    (cx: number, cy: number, radius: number) => {
      setPreview({
        type: 'circle',
        cx,
        cy,
        r: radius,
      })
    },
    [setPreview]
  )

  const updateArrowPreview = useCallback(
    (x1: number, y1: number, x2: number, y2: number) => {
      const snapped = snapLineToAxis(x1, y1, x2, y2)
      setPreview({
        type: 'arrow',
        x1,
        y1,
        x2: snapped.x2,
        y2: snapped.y2,
      })
    },
    [setPreview]
  )

  const clearPreview = useCallback(() => {
    setPreview(undefined)
  }, [setPreview])

  return {
    updateLinePreview,
    updateRectanglePreview,
    updateCirclePreview,
    updateArrowPreview,
    clearPreview,
  }
}
