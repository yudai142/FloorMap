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

export default function Canvas({ room = {}, initialShapes = [], initialSeats = [], onSave }) {
  const svgRef = useRef(null)
  const svgContainerRef = useRef(null)
  const scrollContainerRef = useRef(null)
  const [isSaving, setIsSaving] = useState(false)
  const [alert, setAlert] = useState(null)

  // Default canvas dimensions if not provided
  const canvasWidth = room?.width || 1000
  const canvasHeight = room?.height || 700

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
    if (initialShapes.length > 0 || initialSeats.length > 0) {
      setShapes(initialShapes)
      setSeats(initialSeats)
      saveToHistory(initialSeats, initialShapes)
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
      const response = await fetch(`/rooms/${room.id}/floor_plan.json`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': getCsrfToken(),
        },
        body: JSON.stringify({ room: { floor_plan_data: shapes } }),
      })

      if (!response.ok) {
        throw new Error('保存に失敗しました')
      }

      setAlert({ type: 'success', message: '上面図を保存しました' })
      setTimeout(() => setAlert(null), 2000)

      if (onSave) {
        onSave(shapes)
      }
    } catch (err) {
      setAlert({ type: 'error', message: err.message })
      console.error('Save error:', err)
    } finally {
      setIsSaving(false)
    }
  }, [room, shapes, getCsrfToken, onSave])

  const handleMouseDown = useCallback((e) => {
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
        const alreadySelected = selectedElements.some((el) => el.type === 'seat' && el.id === clickedSeat.id)
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
    } else if (currentTool === 'delete') {
      const clickedSeat = getSeatAtPoint(x, y)
      if (clickedSeat) {
        if (confirm(`座席 ${clickedSeat.label} を削除しますか?`)) {
          deleteSeat(clickedSeat.id).catch((err) => {
            setAlert({ type: 'error', message: err.message })
          })
        }
      } else {
        const clickedShape = getShapeAtPoint(x, y)
        if (clickedShape) {
          deleteShape(clickedShape.id)
        }
      }
    } else if (['line', 'rectangle', 'circle', 'arrow', 'polygon'].includes(currentTool)) {
      setDrawingStart({ x, y })
    } else if (currentTool === 'text') {
      setTextInput({ x, y, text: '' })
    }
  }, [getMousePosition, currentTool, getSeatAtPoint, getShapeAtPoint, createSeat, deleteSeat, deleteShape,
      setDragging, clearSelection, setDrawingStart, setTextInput])

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
      setSelectionBox({
        x: Math.min(selectionStart.x, x),
        y: Math.min(selectionStart.y, y),
        width: Math.abs(x - selectionStart.x),
        height: Math.abs(y - selectionStart.y),
      })
    } else if (drawingStart && currentTool === 'line' && drawMode === 'drag') {
      updateLinePreview(drawingStart.x, drawingStart.y, x, y)
    } else if (drawingStart && currentTool === 'rectangle' && drawMode === 'drag') {
      updateRectanglePreview(drawingStart.x, drawingStart.y, x - drawingStart.x, y - drawingStart.y)
    } else if (drawingStart && currentTool === 'circle' && drawMode === 'drag') {
      const radius = Math.sqrt(Math.pow(x - drawingStart.x, 2) + Math.pow(y - drawingStart.y, 2))
      updateCirclePreview(drawingStart.x, drawingStart.y, radius)
    } else if (drawingStart && currentTool === 'arrow' && drawMode === 'drag') {
      updateArrowPreview(drawingStart.x, drawingStart.y, x, y)
    }
  }, [getMousePosition, dragging, currentTool, drawingStart, drawMode, canvasWidth, canvasHeight, seats,
      mergeSeat, updateLinePreview, updateRectanglePreview, updateCirclePreview, updateArrowPreview])

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
  }, [getMousePosition, dragging, currentTool, drawingStart, drawMode, canvasWidth, canvasHeight, seats,
      moveSeat, setDragging, setDrawingStart, clearPreview, addLine, addRectangle, addCircle, addArrow])

  return (
    <div className="canvas-editor-container flex flex-col h-screen bg-base-100">
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
