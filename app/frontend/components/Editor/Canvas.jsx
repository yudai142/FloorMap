import React, { useRef, useEffect, useState, useCallback } from 'react'
import { useEditorStore } from '../../store/editorStore'
import EditorToolbar from './EditorToolbar'
import ShapeRenderer from './ShapeRenderer'
import SeatRenderer from './SeatRenderer'
import PreviewRenderer from './PreviewRenderer'
import { useSeatManagement } from './hooks/useSeatManagement'
import { useShapeDrawing } from './hooks/useShapeDrawing'
import { useShapePreview } from './hooks/useShapePreview'
import { snapToGrid, distanceToLine, isPointInPolygon } from './utils/snapToGrid'
import './Canvas.css'

export default function Canvas({ room = {}, initialShapes = [], initialSeats = [], onSave, canvasSize, onCanvasSizeChange }) {
  const svgRef = useRef(null)
  const svgContainerRef = useRef(null)
  const scrollContainerRef = useRef(null)
  const originalSeatsRef = useRef(initialSeats)
  const [isSaving, setIsSaving] = useState(false)
  const [alert, setAlert] = useState(null)
  const [selectionStart, setSelectionStart] = useState(null)
  const [polygonClosed, setPolygonClosed] = useState(true)
  const [isResizing, setIsResizing] = useState(null)
  const [dragStart, setDragStart] = useState({ x: 0, y: 0 })

  // Default canvas dimensions if not provided
  const canvasWidth = canvasSize?.width || room?.width || 1000
  const canvasHeight = canvasSize?.height || room?.height || 700

  // Zustand store
  const {
    shapes,
    seats,
    zoom,
    showGrid,
    selectedColor,
    currentTool,
    drawMode,
    history,
    historyIndex,
    hasUnsavedChanges,
    isDrawing,
    drawingStart,
    preview,
    dragging,
    selectionBox,
    polygonPoints,
    textInput,
    selectedElements,
    // Actions
    setShapes,
    setSeats,
    setZoom,
    setShowGrid,
    undo,
    redo,
    saveToHistory,
    addShape,
    deleteShape,
    updateShape,
    mergeSeat,
    removeSeat,
    setDrawingStart,
    setPreview,
    setDragging,
    setSelectionBox,
    setPolygonPoints,
    setTextInput,
    setSelectedElements,
    clearSelection,
  } = useEditorStore()

  // Custom hooks
  const { createSeat, deleteSeat, moveSeat } = useSeatManagement(room.id)
  const { addLine, addRectangle, addCircle, addArrow, addText, addPolygon } = useShapeDrawing()
  const { updateLinePreview, updateRectanglePreview, updateCirclePreview, updateArrowPreview, clearPreview } =
    useShapePreview()

  // Initialize canvas data
  useEffect(() => {
    if ((initialShapes && initialShapes.length > 0) || (initialSeats && initialSeats.length > 0)) {
      // Ensure each shape has a unique ID
      const shapesWithIds = initialShapes.map((shape) => ({
        ...shape,
        id: shape.id || `${shape.type}-${Date.now()}-${Math.random()}`,
      }))
      setShapes(shapesWithIds)
      setSeats(initialSeats)
      saveToHistory(initialSeats, shapesWithIds)
    }
  }, [initialShapes, initialSeats, setShapes, setSeats, saveToHistory])


  // Keyboard shortcuts
  useEffect(() => {
    const handleKeyDown = (e) => {
      // Ctrl+Z / Cmd+Z: Undo
      if ((e.ctrlKey || e.metaKey) && e.key === 'z' && !e.shiftKey) {
        e.preventDefault()
        undo()
      }
      // Ctrl+Shift+Z / Cmd+Shift+Z or Ctrl+Y / Cmd+Y: Redo
      if ((e.ctrlKey || e.metaKey) && (e.key === 'z' && e.shiftKey || e.key === 'y')) {
        e.preventDefault()
        redo()
      }
      // Delete: Delete selected elements
      if (e.key === 'Delete' || e.key === 'Backspace') {
        e.preventDefault()
        selectedElements.forEach((el) => {
          if (el.type === 'seat') {
            deleteSeat(el.id).catch((err) => {
              setAlert({ type: 'error', message: err.message })
            })
          } else if (el.type === 'shape') {
            deleteShape(el.id)
          }
        })
        clearSelection()
      }
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [undo, redo, selectedElements, deleteSeat, deleteShape, clearSelection, setAlert])

  const getCsrfToken = useCallback(() => {
    return document.querySelector('meta[name="csrf-token"]')?.content || ''
  }, [])

  const getMousePosition = useCallback((e) => {
    if (!svgRef.current) return { x: 0, y: 0 }
    const rect = svgRef.current.getBoundingClientRect()
    return {
      x: Math.round((e.clientX - rect.left) / zoom),
      y: Math.round((e.clientY - rect.top) / zoom),
    }
  }, [zoom])

  // Find seat at click position
  const getSeatAtPoint = useCallback((x, y) => {
    return seats.find((seat) => {
      const dx = x - seat.x
      const dy = y - seat.y
      return Math.sqrt(dx * dx + dy * dy) <= 15
    })
  }, [seats])

  // Find shape at click position
  const getShapeAtPoint = useCallback((x, y) => {
    for (let i = shapes.length - 1; i >= 0; i--) {
      const shape = shapes[i]
      const tolerance = 10

      if (shape.type === 'line' || shape.type === 'arrow') {
        const distance = distanceToLine(x, y, shape.x1, shape.y1, shape.x2, shape.y2)
        if (distance < tolerance) return shape
      } else if (shape.type === 'rectangle') {
        if (x >= shape.x && x <= shape.x + shape.width && y >= shape.y && y <= shape.y + shape.height) {
          return shape
        }
      } else if (shape.type === 'circle') {
        const distance = Math.sqrt(Math.pow(x - shape.cx, 2) + Math.pow(y - shape.cy, 2))
        if (distance <= shape.r + tolerance) return shape
      } else if (shape.type === 'text') {
        const textWidth = shape.text.length * 8
        const textHeight = 16
        if (x >= shape.x && x <= shape.x + textWidth && y >= shape.y - textHeight && y <= shape.y) {
          return shape
        }
      } else if (shape.type === 'polygon') {
        if (isPointInPolygon(x, y, shape.pointsArray)) return shape
      }
    }
    return null
  }, [shapes])

  const handleZoomIn = useCallback(() => {
    setZoom(Math.min(zoom + 0.1, 3))
  }, [zoom, setZoom])

  const handleZoomOut = useCallback(() => {
    setZoom(Math.max(zoom - 0.1, 0.1))
  }, [zoom, setZoom])

  const handleZoomReset = useCallback(() => {
    setZoom(1)
  }, [setZoom])

  const handleSave = useCallback(async () => {
    if (!room || !room.id) {
      setAlert({ type: 'error', message: 'ルームが選択されていません' })
      return
    }

    setIsSaving(true)
    try {
      // Filter out incomplete shapes before saving
      const validShapes = shapes.filter(shape => {
        if (shape.type === 'line' || shape.type === 'arrow') {
          return shape.x1 !== undefined && shape.y1 !== undefined && shape.x2 !== undefined && shape.y2 !== undefined
        } else if (shape.type === 'rectangle') {
          return shape.x !== undefined && shape.y !== undefined && shape.width !== undefined && shape.height !== undefined
        } else if (shape.type === 'circle') {
          return shape.cx !== undefined && shape.cy !== undefined && shape.r !== undefined
        } else if (shape.type === 'text') {
          return shape.x !== undefined && shape.y !== undefined && shape.text !== undefined
        } else if (shape.type === 'polygon') {
          return shape.pointsArray !== undefined && shape.pointsArray.length > 0
        }
        return true
      })

      // Save shapes (floor plan)
      const floorPlanResponse = await fetch(`/rooms/${room.share_token}/floor_plan.json`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': getCsrfToken(),
        },
        body: JSON.stringify({ room: { floor_plan_data: validShapes } }),
      })
      if (!floorPlanResponse.ok) {
        const errorText = await floorPlanResponse.text()
        console.error('Floor plan error response:', errorText)
        throw new Error('上面図の保存に失敗しました')
      }

      // Save seats (create, update, delete)
      // Detect deleted seats (original seats that are no longer in current seats)
      const currentSeatIds = new Set(seats.map(s => s.id).filter(id => id > 0))
      const deletedSeats = originalSeatsRef.current.filter(
        originalSeat => originalSeat.id > 0 && !currentSeatIds.has(originalSeat.id)
      )

      // Delete removed seats
      for (const deletedSeat of deletedSeats) {
        const deleteResponse = await fetch(`/rooms/${room.share_token}/seats/${deletedSeat.id}.json`, {
          method: 'DELETE',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': getCsrfToken(),
          },
        })

        if (!deleteResponse.ok) {
          throw new Error('座席の削除に失敗しました')
        }
      }

      // Send current seats state to server
      for (const seat of seats) {
        if (seat.id < 0) {
          // New seat - create it
          const createResponse = await fetch(`/rooms/${room.share_token}/seats.json`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'X-CSRF-Token': getCsrfToken(),
            },
            body: JSON.stringify({
              seat: {
                position_x: seat.x,
                position_y: seat.y,
                seat_type: seat.seat_type || 'regular',
              },
            }),
          })

          if (!createResponse.ok) {
            throw new Error('座席の保存に失敗しました')
          }

          // Update local seat with server-assigned ID
          try {
            const savedSeat = await createResponse.json()
            mergeSeat({
              id: savedSeat.id,
              label: savedSeat.seat_identifier,
              x: savedSeat.position_x,
              y: savedSeat.position_y,
              occupied: seat.occupied,
              occupant_name: seat.occupant_name,
              seat_type: savedSeat.seat_type
            })
          } catch (parseError) {
            // Continue anyway - server saved the seat
          }
        } else {
          // Existing seat - update position
          const updateResponse = await fetch(`/rooms/${room.share_token}/seats/${seat.id}/position.json`, {
            method: 'PATCH',
            headers: {
              'Content-Type': 'application/json',
              'X-CSRF-Token': getCsrfToken(),
            },
            body: JSON.stringify({
              seat: {
                position_x: seat.x,
                position_y: seat.y,
              },
            }),
          })

          if (!updateResponse.ok) {
            throw new Error('座席の保存に失敗しました')
          }
        }
      }

      // Update the original seats reference for next save
      originalSeatsRef.current = seats.filter(s => s.id > 0)

      setAlert({ type: 'success', message: '座席配置図を保存しました' })
      setTimeout(() => setAlert(null), 2000)

      if (onSave) {
        onSave(validShapes)
      }
    } catch (err) {
      setAlert({ type: 'error', message: err.message })
    } finally {
      setIsSaving(false)
    }
  }, [room, shapes, seats, getCsrfToken, onSave, mergeSeat])

  const handleMouseDown = useCallback((e) => {
    // Right-click: complete polygon
    if (e.button === 2 && currentTool === 'polygon' && polygonPoints && polygonPoints.length >= 3) {
      e.preventDefault()
      addPolygon(polygonPoints)
      setPolygonPoints([])
      setDrawingStart(null)
      return
    }

    // Prevent default right-click menu
    if (e.button === 2) {
      e.preventDefault()
      return
    }

    const { x, y } = getMousePosition(e)

    if (currentTool === 'seat') {
      const existingSeat = getSeatAtPoint(x, y)
      if (!existingSeat) {
        createSeat(x, y).catch((err) => {
          setAlert({ type: 'error', message: err.message })
        })
      }
    } else if (currentTool === 'select') {
      const clickedSeat = getSeatAtPoint(x, y)
      if (clickedSeat) {
        // Check if already selected
        const alreadySelected = selectedElements && selectedElements.some((el) => el.type === 'seat' && el.id === clickedSeat.id)
        if (!alreadySelected && !e.ctrlKey && !e.metaKey) {
          clearSelection()
        }
        setDragging({ id: clickedSeat.id, offsetX: x - clickedSeat.x, offsetY: y - clickedSeat.y })
      } else {
        // Start selection box drag if not clicking on a seat
        if (!e.ctrlKey && !e.metaKey) {
          clearSelection()
        }
        // Initialize selection start for drag selection
        setSelectionStart({ x, y })
      }
    } else if (currentTool === 'fill') {
      const clickedShape = getShapeAtPoint(x, y)
      if (clickedShape) {
        // Toggle fill on the shape
        const isFilled = clickedShape.fill && clickedShape.fill !== 'none'
        updateShape(clickedShape.id, {
          fill: isFilled ? 'none' : (clickedShape.color || '#e2e8f0')
        })
      }
    } else if (currentTool === 'delete') {
      const clickedSeat = getSeatAtPoint(x, y)
      if (clickedSeat) {
        deleteSeat(clickedSeat.id).catch((err) => {
          setAlert({ type: 'error', message: err.message })
        })
      } else {
        const clickedShape = getShapeAtPoint(x, y)
        if (clickedShape) {
          console.log('Deleting shape:', clickedShape.id, 'Type:', clickedShape.type)
          deleteShape(clickedShape.id)
        }
      }
    } else if (['line', 'rectangle', 'circle', 'arrow'].includes(currentTool)) {
      // Handle two-point selection mode
      if (drawMode === 'click') {
        if (!drawingStart) {
          // First click: set starting point
          setDrawingStart({ x, y })
        } else {
          // Second click: complete the shape
          if (currentTool === 'line') {
            addLine(drawingStart.x, drawingStart.y, x, y)
          } else if (currentTool === 'rectangle') {
            addRectangle(drawingStart.x, drawingStart.y, x - drawingStart.x, y - drawingStart.y)
          } else if (currentTool === 'circle') {
            const radius = Math.sqrt(Math.pow(x - drawingStart.x, 2) + Math.pow(y - drawingStart.y, 2))
            addCircle(drawingStart.x, drawingStart.y, radius)
          } else if (currentTool === 'arrow') {
            addArrow(drawingStart.x, drawingStart.y, x, y)
          }
          setDrawingStart(null)
          clearPreview()
        }
      } else if (drawMode === 'drag') {
        // Drag mode: just set starting point
        setDrawingStart({ x, y })
      }
    } else if (currentTool === 'polygon') {
      // Add point to polygon
      console.log('Adding polygon point:', { x, y }, 'Current points:', polygonPoints)
      const updatedPoints = [...(polygonPoints || []), { x, y }]
      console.log('Updated points:', updatedPoints)
      setPolygonPoints(updatedPoints)
      setDrawingStart({ x, y })
    } else if (currentTool === 'text') {
      // Show text input dialog
      const text = prompt('テキストを入力してください:')
      if (text && text.trim()) {
        addText(x, y, text)
      }
    }
  }, [currentTool, drawMode, getMousePosition, getSeatAtPoint, getShapeAtPoint, createSeat, deleteSeat, deleteShape, updateShape, moveSeat,
      addLine, addRectangle, addCircle, addArrow, addText, addPolygon, polygonPoints, drawingStart, polygonClosed])

  const handleMouseMove = useCallback((e) => {
    const { x, y } = getMousePosition(e)

    if (dragging && currentTool === 'select') {
      const newX = Math.max(0, Math.min(x - dragging.offsetX, canvasWidth))
      const newY = Math.max(0, Math.min(y - dragging.offsetY, canvasHeight))
      const seat = seats.find((s) => s.id === dragging.id)
      if (seat) {
        mergeSeat({ ...seat, x: snapToGrid(newX), y: snapToGrid(newY) })
      }
    } else if (selectionStart && currentTool === 'select' && !dragging) {
      // Update selection box during drag
      if (selectionStart.x !== undefined && selectionStart.y !== undefined) {
        setSelectionBox({
          x: Math.min(selectionStart.x, x),
          y: Math.min(selectionStart.y, y),
          width: Math.abs(x - selectionStart.x),
          height: Math.abs(y - selectionStart.y),
        })
      }
    } else if (currentTool === 'polygon' && polygonPoints && polygonPoints.length > 0) {
      // Update polygon preview (draw line from last point to current mouse)
      setDrawingStart({ x, y })
    } else if (drawingStart) {
      // Show previews in both drag and click modes (for preview display)
      if (currentTool === 'line') {
        updateLinePreview(drawingStart.x, drawingStart.y, x, y)
      } else if (currentTool === 'rectangle') {
        updateRectanglePreview(drawingStart.x, drawingStart.y, x - drawingStart.x, y - drawingStart.y)
      } else if (currentTool === 'circle') {
        const radius = Math.sqrt(Math.pow(x - drawingStart.x, 2) + Math.pow(y - drawingStart.y, 2))
        updateCirclePreview(drawingStart.x, drawingStart.y, radius)
      } else if (currentTool === 'arrow') {
        updateArrowPreview(drawingStart.x, drawingStart.y, x, y)
      }
    }
  }, [getMousePosition, dragging, currentTool, drawingStart, drawMode, canvasWidth, canvasHeight, seats, shapes,
      mergeSeat, updateLinePreview, updateRectanglePreview, updateCirclePreview, updateArrowPreview, setDrawingStart, polygonPoints,
      updateShape, snapToGrid])

  const handleMouseUp = useCallback((e) => {
    const { x, y } = getMousePosition(e)

    if (dragging && currentTool === 'select') {
      const newX = Math.max(0, Math.min(x - dragging.offsetX, canvasWidth))
      const newY = Math.max(0, Math.min(y - dragging.offsetY, canvasHeight))
      const seat = seats.find((s) => s.id === dragging.id)
      if (seat) {
        moveSeat(seat.id, snapToGrid(newX), snapToGrid(newY)).catch((err) => {
          setAlert({ type: 'error', message: err.message })
        })
      }
      setDragging(null)
    } else if (selectionStart && selectionBox && currentTool === 'select' && !dragging) {
      // Select all elements in selection box
      const newSelected = []

      seats.forEach((seat) => {
        if (
          seat.x >= selectionBox.x &&
          seat.x <= selectionBox.x + selectionBox.width &&
          seat.y >= selectionBox.y &&
          seat.y <= selectionBox.y + selectionBox.height
        ) {
          newSelected.push({ type: 'seat', id: seat.id })
        }
      })

      shapes.forEach((shape) => {
        let isSelected = false
        if (shape.type === 'line' || shape.type === 'arrow') {
          if (
            shape.x1 >= selectionBox.x &&
            shape.x1 <= selectionBox.x + selectionBox.width &&
            shape.y1 >= selectionBox.y &&
            shape.y1 <= selectionBox.y + selectionBox.height &&
            shape.x2 >= selectionBox.x &&
            shape.x2 <= selectionBox.x + selectionBox.width &&
            shape.y2 >= selectionBox.y &&
            shape.y2 <= selectionBox.y + selectionBox.height
          ) {
            isSelected = true
          }
        } else if (shape.type === 'rectangle') {
          if (
            shape.x >= selectionBox.x &&
            shape.x + shape.width <= selectionBox.x + selectionBox.width &&
            shape.y >= selectionBox.y &&
            shape.y + shape.height <= selectionBox.y + selectionBox.height
          ) {
            isSelected = true
          }
        } else if (shape.type === 'circle') {
          if (
            shape.cx - shape.r >= selectionBox.x &&
            shape.cx + shape.r <= selectionBox.x + selectionBox.width &&
            shape.cy - shape.r >= selectionBox.y &&
            shape.cy + shape.r <= selectionBox.y + selectionBox.height
          ) {
            isSelected = true
          }
        }
        if (isSelected) {
          newSelected.push({ type: 'shape', id: shape.id })
        }
      })

      setSelectedElements(newSelected)
      setSelectionStart(null)
      setSelectionBox(null)
    } else if (drawingStart && currentTool === 'line' && drawMode === 'drag') {
      addLine(drawingStart.x, drawingStart.y, x, y)
      setDrawingStart(null)
      clearPreview()
    } else if (drawingStart && currentTool === 'rectangle' && drawMode === 'drag') {
      addRectangle(drawingStart.x, drawingStart.y, x - drawingStart.x, y - drawingStart.y)
      setDrawingStart(null)
      clearPreview()
    } else if (drawingStart && currentTool === 'circle' && drawMode === 'drag') {
      const radius = Math.sqrt(Math.pow(x - drawingStart.x, 2) + Math.pow(y - drawingStart.y, 2))
      addCircle(drawingStart.x, drawingStart.y, radius)
      setDrawingStart(null)
      clearPreview()
    } else if (drawingStart && currentTool === 'arrow' && drawMode === 'drag') {
      addArrow(drawingStart.x, drawingStart.y, x, y)
      setDrawingStart(null)
      clearPreview()
    }
  }, [getMousePosition, dragging, currentTool, drawingStart, drawMode, canvasWidth, canvasHeight, seats, shapes,
      moveSeat, setDragging, setDrawingStart, clearPreview, addLine, addRectangle, addCircle, addArrow, setSelectedElements, setSelectionStart, setSelectionBox,
      updateShape, snapToGrid, mergeSeat, setAlert])

  const handleResizeMouseDown = (direction) => (e) => {
    e.preventDefault()
    setIsResizing(direction)
    setDragStart({ x: e.clientX, y: e.clientY })
  }

  // リサイズイベントのグローバル監視
  useEffect(() => {
    if (!isResizing || !onCanvasSizeChange) return

    const handleMouseMove = (e) => {
      const deltaX = e.clientX - dragStart.x
      const deltaY = e.clientY - dragStart.y

      if (isResizing === 'horizontal' || isResizing === 'both') {
        onCanvasSizeChange((prev) => ({
          ...prev,
          width: Math.max(100, prev.width + deltaX)
        }))
      }

      if (isResizing === 'vertical' || isResizing === 'both') {
        onCanvasSizeChange((prev) => ({
          ...prev,
          height: Math.max(100, prev.height + deltaY)
        }))
      }

      setDragStart({ x: e.clientX, y: e.clientY })
    }

    const handleMouseUp = () => {
      setIsResizing(null)
    }

    document.addEventListener('mousemove', handleMouseMove)
    document.addEventListener('mouseup', handleMouseUp)

    return () => {
      document.removeEventListener('mousemove', handleMouseMove)
      document.removeEventListener('mouseup', handleMouseUp)
    }
  }, [isResizing, dragStart, onCanvasSizeChange])

  return (
    <div className="canvas-editor-container flex flex-col h-screen bg-base-100">
      {/* Polygon Cancel/Confirm Button */}
      {currentTool === "polygon" && polygonPoints && polygonPoints.length > 0 && (
        <div className="bg-blue-100 border border-blue-300 rounded mx-4 mt-4 p-3 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <span className="text-sm text-blue-800">
              ポリゴンポイント: {polygonPoints.length} 個
            </span>
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                checked={polygonClosed}
                onChange={(e) => setPolygonClosed(e.target.checked)}
                className="checkbox checkbox-sm"
              />
              <span className="text-sm text-blue-800">始点と結ぶ</span>
            </label>
          </div>
          <div className="flex gap-2">
            <button
              onClick={() => {
                if (polygonPoints && polygonPoints.length >= 2) {
                  if (polygonClosed) {
                    // Create a closed polygon
                    const points = [...polygonPoints, polygonPoints[0]]
                    addPolygon(points)
                  } else {
                    // Create lines between consecutive points
                    for (let i = 0; i < polygonPoints.length - 1; i++) {
                      addLine(
                        polygonPoints[i].x,
                        polygonPoints[i].y,
                        polygonPoints[i + 1].x,
                        polygonPoints[i + 1].y
                      )
                    }
                  }
                  setPolygonPoints([])
                  setDrawingStart(null)
                  setAlert({ type: 'success', message: polygonClosed ? 'ポリゴンを作成しました' : '直線を作成しました' })
                } else {
                  setAlert({ type: 'error', message: 'ポリゴンは2個以上のポイントが必要です' })
                }
              }}
              disabled={!polygonPoints || polygonPoints.length < 2}
              className="btn btn-sm btn-success"
            >
              確定
            </button>
            <button
              onClick={() => {
                setPolygonPoints([])
                setDrawingStart(null)
                setAlert(null)
              }}
              className="btn btn-sm btn-outline btn-error"
            >
              キャンセル
            </button>
          </div>
        </div>
      )}

      {/* Alert */}
      {alert && (
        <div className={`alert alert-${alert.type === 'error' ? 'error' : 'success'} mx-4 mt-4`}>
          <div>{alert.message}</div>
          <button onClick={() => setAlert(null)} className="btn btn-sm btn-ghost">
            ✕
          </button>
        </div>
      )}

      {/* Main Controls */}
      <EditorToolbar
        currentTool={currentTool}
        zoom={zoom}
        showGrid={showGrid}
        onZoomIn={handleZoomIn}
        onZoomOut={handleZoomOut}
        onZoomReset={handleZoomReset}
        onToggleGrid={() => setShowGrid(!showGrid)}
        onUndo={undo}
        onRedo={redo}
        onSave={handleSave}
        isSaving={isSaving}
        hasUnsavedChanges={hasUnsavedChanges}
        historyIndex={historyIndex}
        historyLength={history.length}
      />

      {/* Canvas Area */}
      <div ref={scrollContainerRef} className="canvas-scroll-container flex-1 overflow-auto bg-slate-100">
        <div
          ref={svgContainerRef}
          className="canvas-container inline-block p-6"
          style={{
            minWidth: 'fit-content',
            minHeight: 'fit-content',
          }}
        >
          <div
            style={{
              position: 'relative',
              display: 'inline-block',
              borderRight: '3px solid #3b82f6',
              borderBottom: '3px solid #3b82f6'
            }}
          >
            <div
              style={{
                width: `${canvasWidth}px`,
                height: `${canvasHeight}px`,
                transform: `scale(${zoom})`,
                transformOrigin: 'top left',
                transition: 'transform 0.1s ease-out',
              }}
            >
            <svg
              ref={svgRef}
              width={canvasWidth}
              height={canvasHeight}
              className="canvas-svg border border-slate-300 rounded-lg bg-white block select-none cursor-crosshair"
              onMouseDown={handleMouseDown}
              onMouseMove={handleMouseMove}
              onMouseUp={handleMouseUp}
              onMouseLeave={handleMouseUp}
            >
              {/* Grid */}
              {showGrid && (
                <defs>
                  <pattern id="smallGrid" width="10" height="10" patternUnits="userSpaceOnUse">
                    <path d="M 10 0 L 0 0 0 10" fill="none" stroke="#e2e8f0" strokeWidth="0.5" />
                  </pattern>
                  <pattern id="grid" width="50" height="50" patternUnits="userSpaceOnUse">
                    <rect width="50" height="50" fill="url(#smallGrid)" />
                    <path d="M 50 0 L 0 0 0 50" fill="none" stroke="#cbd5e1" strokeWidth="1" />
                  </pattern>
                </defs>
              )}
              {showGrid && <rect width={canvasWidth} height={canvasHeight} fill="url(#grid)" />}

              {/* Shapes */}
              {shapes.map((shape) => (
                <ShapeRenderer
                  key={shape.id}
                  shape={shape}
                  isSelected={selectedElements.some((el) => el.type === 'shape' && el.id === shape.id)}
                />
              ))}

              {/* Preview */}
              {preview && <PreviewRenderer preview={preview} />}

              {/* Polygon Preview */}
              {currentTool === 'polygon' && polygonPoints && polygonPoints.length > 0 && (
                <g pointerEvents="none">
                  {/* Draw lines between points */}
                  {polygonPoints.map((point, idx) => {
                    const nextPoint = polygonPoints[idx + 1]
                    if (nextPoint) {
                      return (
                        <line
                          key={`polygon-line-${idx}`}
                          x1={point.x}
                          y1={point.y}
                          x2={nextPoint.x}
                          y2={nextPoint.y}
                          stroke="#06b6d4"
                          strokeWidth="2"
                          strokeDasharray="4,4"
                        />
                      )
                    }
                    return null
                  })}
                  {/* Draw circles at points */}
                  {polygonPoints.map((point, idx) => (
                    <circle
                      key={`polygon-point-${idx}`}
                      cx={point.x}
                      cy={point.y}
                      r="5"
                      fill="#06b6d4"
                      stroke="white"
                      strokeWidth="2"
                    />
                  ))}
                  {/* Draw line from last point to current mouse position */}
                  {drawingStart && polygonPoints.length > 0 && (
                    <line
                      x1={polygonPoints[polygonPoints.length - 1].x}
                      y1={polygonPoints[polygonPoints.length - 1].y}
                      x2={drawingStart.x}
                      y2={drawingStart.y}
                      stroke="#06b6d4"
                      strokeWidth="2"
                      strokeDasharray="4,4"
                      pointerEvents="none"
                    />
                  )}
                </g>
              )}

              {/* Selection Box */}
              {selectionBox && currentTool === 'select' && (
                <rect
                  x={selectionBox.x}
                  y={selectionBox.y}
                  width={selectionBox.width}
                  height={selectionBox.height}
                  fill="rgba(6, 182, 212, 0.1)"
                  stroke="#06b6d4"
                  strokeWidth="2"
                  strokeDasharray="5,5"
                  pointerEvents="none"
                />
              )}

              {/* Seats */}
              {seats.map((seat) => (
                <SeatRenderer key={seat.id} seat={seat} onDelete={deleteSeat} />
              ))}
            </svg>
            </div>

            {/* リサイズハンドル */}
            {/* 右端のリサイズハンドル */}
            <div
              onMouseDown={handleResizeMouseDown('horizontal')}
              style={{
                position: 'absolute',
                right: '0',
                top: '0',
                width: '8px',
                height: '100%',
                cursor: 'ew-resize',
                backgroundColor: '#3b82f6',
                opacity: isResizing === 'horizontal' ? 1 : 0.5,
                transition: 'opacity 0.2s'
              }}
            />

            {/* 下のリサイズハンドル */}
            <div
              onMouseDown={handleResizeMouseDown('vertical')}
              style={{
                position: 'absolute',
                bottom: '0',
                left: '0',
                width: '100%',
                height: '8px',
                cursor: 'ns-resize',
                backgroundColor: '#3b82f6',
                opacity: isResizing === 'vertical' ? 1 : 0.5,
                transition: 'opacity 0.2s'
              }}
            />

            {/* 右下角のリサイズハンドル */}
            <div
              onMouseDown={handleResizeMouseDown('both')}
              style={{
                position: 'absolute',
                bottom: '0',
                right: '0',
                width: '16px',
                height: '16px',
                cursor: 'nwse-resize',
                backgroundColor: '#3b82f6',
                opacity: isResizing === 'both' ? 1 : 0.5,
                transition: 'opacity 0.2s'
              }}
            />
          </div>
        </div>
      </div>

      {/* Status Bar */}
      <div className="canvas-status-bar bg-slate-50 border-t border-slate-200 px-4 py-2 text-sm text-slate-600">
        <span>
          {seats.length} 個の座席 • {shapes.length} 個の図形
        </span>
        {hasUnsavedChanges && <span className="ml-4 text-orange-600">● 未保存の変更</span>}
      </div>
    </div>
  )
}
