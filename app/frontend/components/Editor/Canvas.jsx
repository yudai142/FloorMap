import React, { useRef, useEffect, useState } from 'react'
import { useEditorStore } from '../../store/editorStore'
import { ZoomIn, ZoomOut, RotateCcw, LayoutGrid, Save, Undo2, Redo2 } from 'lucide-react'
import EditorToolbar from './EditorToolbar'
import './Canvas.css'

export default function Canvas({ room, initialShapes = [], initialSeats = [], onSave }) {
  const svgRef = useRef(null)
  const svgContainerRef = useRef(null)
  const scrollContainerRef = useRef(null)
  const [isSaving, setIsSaving] = useState(false)
  const [alert, setAlert] = useState(null)

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
    setShapes,
    setSeats,
    setZoom,
    setShowGrid,
    undo,
    redo,
    saveToHistory,
  } = useEditorStore()

  // Initialize canvas data
  useEffect(() => {
    if (initialShapes.length > 0) {
      setShapes(initialShapes)
    }
    if (initialSeats.length > 0) {
      setSeats(initialSeats)
    }
    if (initialShapes.length > 0 && initialSeats.length >= 0) {
      saveToHistory(initialSeats, initialShapes)
    }
  }, [initialShapes, initialSeats, setShapes, setSeats, saveToHistory])

  const getCsrfToken = () => {
    return document.querySelector('meta[name="csrf-token"]')?.content || ''
  }

  const handleZoomIn = () => {
    setZoom(Math.min(zoom + 0.1, 3))
  }

  const handleZoomOut = () => {
    setZoom(Math.max(zoom - 0.1, 0.1))
  }

  const handleZoomReset = () => {
    setZoom(1)
  }

  const handleSave = async () => {
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
  }

  const handleMouseDown = (e) => {
    if (!svgRef.current) return

    const rect = svgRef.current.getBoundingClientRect()
    const x = Math.round(e.clientX - rect.left)
    const y = Math.round(e.clientY - rect.top)

    console.log(`Tool: ${currentTool}, Position: (${x}, ${y})`)
    // 各ツール別の処理は フェーズ2 以降で実装
  }

  const handleMouseMove = (e) => {
    // フェーズ2 で実装
  }

  const handleMouseUp = (e) => {
    // フェーズ2 で実装
  }

  return (
    <div className="canvas-editor-container flex flex-col h-screen bg-base-100">
      {/* Alert */}
      {alert && (
        <div className={`alert alert-${alert.type === 'error' ? 'error' : 'success'} mx-4 mt-4`}>
          <div>{alert.message}</div>
          <button onClick={() => setAlert(null)} className="btn btn-sm btn-ghost">✕</button>
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
      <div
        ref={scrollContainerRef}
        className="canvas-scroll-container flex-1 overflow-auto bg-slate-100"
      >
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
              width: `${room?.width || 800}px`,
              height: `${room?.height || 600}px`,
              transform: `scale(${zoom})`,
              transformOrigin: 'top left',
              transition: 'transform 0.1s ease-out',
            }}
          >
            <svg
              ref={svgRef}
              width={room?.width || 800}
              height={room?.height || 600}
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
              {showGrid && (
                <rect
                  width={room?.width || 800}
                  height={room?.height || 600}
                  fill="url(#grid)"
                />
              )}

              {/* Shapes - フェーズ2 で実装 */}
              {shapes.map((shape) => (
                <g key={shape.id}>
                  {/* Shape rendering logic */}
                </g>
              ))}

              {/* Seats */}
              {seats.map((seat) => (
                <g key={seat.id} transform={`translate(${seat.x}, ${seat.y})`}>
                  <circle
                    r="12"
                    fill={seat.occupied ? '#f87171' : '#4ade80'}
                    stroke="#065f46"
                    strokeWidth="2"
                  />
                  <text
                    x="16"
                    y="4"
                    fontSize="12"
                    fill="#000"
                    className="pointer-events-none"
                  >
                    {seat.label}
                  </text>
                </g>
              ))}
            </svg>
          </div>
        </div>
      </div>

      {/* Status Bar */}
      <div className="canvas-status-bar bg-slate-50 border-t border-slate-200 px-4 py-2 text-sm text-slate-600">
        <span>{seats.length} 個の座席 • {shapes.length} 個の図形</span>
        {hasUnsavedChanges && <span className="ml-4 text-orange-600">● 未保存の変更</span>}
      </div>
    </div>
  )
}
