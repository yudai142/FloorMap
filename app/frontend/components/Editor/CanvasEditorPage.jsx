import React, { useState } from 'react'
import Canvas from './Canvas'
import { useEditorStore } from '../../store/editorStore'
import { findFreePlacement, getShapeBounds, offsetShape, seatBounds, unionBounds } from './utils/shapeBounds'

export default function CanvasEditorPage({ entity, backHref, shapes, seats, currentUser, persistence, showAutoCheckout = true, templates, initialTemplateId }) {
  const [selectedTemplateId, setSelectedTemplateId] = useState(initialTemplateId ? String(initialTemplateId) : '')
  const [importError, setImportError] = useState('')

  const importTemplate = async () => {
    setImportError('')
    try {
      const response = await fetch(`/floor_plan_templates/${selectedTemplateId}/content`, {
        headers: { Accept: 'application/json' },
      })
      if (!response.ok) {
        setImportError('テンプレートを読み込めませんでした')
        return
      }
      const content = await response.json()
      const state = useEditorStore.getState()
      const stamp = Date.now()

      const templateBounds = unionBounds([
        ...(content.floor_plan_data || []).map((shape) => getShapeBounds(shape)),
        ...(content.seats || []).map((seat) => seatBounds(seat.position_x, seat.position_y)),
      ])
      const occupiedBounds = [
        ...state.shapes.map((shape) => getShapeBounds(shape)),
        ...state.seats.map((seat) => seatBounds(seat.x, seat.y)),
      ].filter(Boolean)
      const placement = templateBounds
        ? findFreePlacement(occupiedBounds, templateBounds, canvasSize)
        : { offsetX: 0, offsetY: 0, width: canvasSize.width, height: canvasSize.height }
      if (placement.width !== canvasSize.width || placement.height !== canvasSize.height) {
        setCanvasSize({ ...canvasSize, width: placement.width, height: placement.height })
      }
      const { offsetX, offsetY } = placement

      const addedShapes = (content.floor_plan_data || []).map((shape, index) => ({
        ...shape,
        ...offsetShape(shape, offsetX, offsetY),
        id: `tpl-${stamp}-${index}`,
      }))

      const usedLabels = new Set(state.seats.map((seat) => seat.label))
      let nextNumber = Math.max(0, ...state.seats.map((seat) => parseInt(String(seat.label).replace(/\D/g, ''), 10) || 0)) + 1
      const nextLabel = () => {
        while (usedLabels.has(`S${nextNumber}`)) nextNumber++
        const label = `S${nextNumber}`
        usedLabels.add(label)
        nextNumber++
        return label
      }

      const addedSeats = []
      let nextSeatId = Math.min(0, ...state.seats.map((seat) => seat.id)) - 1
      for (const seat of content.seats || []) {
        addedSeats.push({
          id: nextSeatId--,
          label: nextLabel(),
          x: seat.position_x + offsetX,
          y: seat.position_y + offsetY,
          occupied: false,
          occupant_name: '不明',
          seat_type: seat.seat_type,
        })
      }

      const allShapes = [...state.shapes, ...addedShapes]
      const allSeats = [...state.seats, ...addedSeats]
      state.setShapes(allShapes)
      state.setSeats(allSeats)
      state.setSelectedElements([
        ...addedShapes.map((shape) => ({ type: 'shape', id: shape.id })),
        ...addedSeats.map((seat) => ({ type: 'seat', id: seat.id })),
      ])
      state.setCurrentTool('select')
      state.saveToHistory(allSeats, allShapes)
      useEditorStore.setState({ hasUnsavedChanges: true })
    } catch (err) {
      setImportError('テンプレートを読み込めませんでした')
    }
  }
  const [canvasSize, setCanvasSize] = useState({ width: entity.width, height: entity.height })
  const [autoCheckoutEnabled, setAutoCheckoutEnabled] = useState(entity.auto_checkout_enabled || false)
  const [autoCheckoutTime, setAutoCheckoutTime] = useState(entity.auto_checkout_time || '')

  const handleSaveCanvas = async () => {
    if (!persistence.settingsUrl) return

    const roomUpdates = {
      width: canvasSize.width,
      height: canvasSize.height,
      auto_checkout_enabled: autoCheckoutEnabled,
      auto_checkout_time: autoCheckoutTime
    }

    try {
      await fetch(persistence.settingsUrl, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
        },
        body: JSON.stringify({
          room: roomUpdates
        })
      })
    } catch (error) {
      console.error('Error updating room settings:', error)
    }
  }

  return (
    <div className="h-screen flex flex-col bg-base-100">
      {/* Header */}
      <div className="bg-white border-b border-base-300 shadow-sm">
        <div className="max-w-full px-4 py-3">
          <div className="flex items-center gap-4">
            <a href={backHref} className="text-sm font-medium text-blue-600 hover:text-blue-800">
              ← 戻る
            </a>
            <h1 className="text-2xl font-bold text-slate-900">{entity.name}</h1>
            <span className="badge badge-lg">
              {canvasSize.width} × {canvasSize.height}px
            </span>
          </div>
          <div className="flex items-center gap-4 mt-2">
            <div className="flex items-center gap-2">
              <label className="text-sm text-slate-600">幅:</label>
              <input
                type="number"
                min="100"
                value={canvasSize.width || entity.width || 1000}
                onChange={(e) => {
                  const val = parseInt(e.target.value) || 100
                  setCanvasSize({ ...canvasSize, width: val })
                }}
                className="w-20 px-2 py-1 border border-slate-300 rounded text-sm"
              />
              <span className="text-sm text-slate-600">px</span>
            </div>
            <div className="flex items-center gap-2">
              <label className="text-sm text-slate-600">高さ:</label>
              <input
                type="number"
                min="100"
                value={canvasSize.height || entity.height || 700}
                onChange={(e) => {
                  const val = parseInt(e.target.value) || 100
                  setCanvasSize({ ...canvasSize, height: val })
                }}
                className="w-20 px-2 py-1 border border-slate-300 rounded text-sm"
              />
              <span className="text-sm text-slate-600">px</span>
            </div>
          </div>

          {showAutoCheckout && (
          <div className="flex items-center gap-4 mt-3 p-3 bg-blue-50 rounded border border-blue-200">
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                checked={autoCheckoutEnabled}
                onChange={(e) => setAutoCheckoutEnabled(e.target.checked)}
                className="w-4 h-4"
              />
              <span className="text-sm font-medium text-slate-700">全員離席設定を有効にする</span>
            </label>
            {autoCheckoutEnabled && (
              <div className="flex items-center gap-2">
                <label htmlFor="auto-checkout-time" className="text-sm text-slate-600">
                  離席時刻:
                </label>
                <input
                  id="auto-checkout-time"
                  type="time"
                  value={autoCheckoutTime}
                  onChange={(e) => setAutoCheckoutTime(e.target.value)}
                  className="px-2 py-1 border border-slate-300 rounded text-sm"
                />
              </div>
            )}
          </div>
          )}

          {templates && (
            <div className="flex items-center gap-2 mt-3">
              <label className="text-sm text-slate-600">テンプレート:</label>
              <select
                value={selectedTemplateId}
                onChange={(e) => setSelectedTemplateId(e.target.value)}
                className="px-2 py-1 border border-slate-300 rounded text-sm"
              >
                <option value="">選択してください</option>
                {templates.map((template) => (
                  <option key={template.id} value={template.id}>
                    {template.name}
                  </option>
                ))}
              </select>
              <button
                type="button"
                onClick={importTemplate}
                disabled={!selectedTemplateId}
                className="px-3 py-1 bg-blue-600 text-white rounded text-sm hover:bg-blue-700 disabled:bg-gray-400"
              >
                読み込む
              </button>
              {importError && <span className="text-sm text-red-600">{importError}</span>}
            </div>
          )}

          <p className="text-sm text-slate-600 mt-1">
            座席配置図エディタ - ツールを選択して、キャンバスをクリック・ドラッグして描画
          </p>
        </div>
      </div>

      {/* Canvas Component */}
      <Canvas
        room={{ ...entity, width: canvasSize.width, height: canvasSize.height }}
        initialShapes={shapes || []}
        initialSeats={seats || []}
        onSave={handleSaveCanvas}
        canvasSize={canvasSize}
        onCanvasSizeChange={setCanvasSize}
        persistence={persistence}
      />

      {/* Footer */}
      <div className="bg-slate-50 border-t border-slate-200 px-4 py-2 text-xs text-slate-500 text-center">
        <p>
          ユーザー: {currentUser?.email || 'Anonymous'} | React + Zustand Canvas Editor (Phase 1)
        </p>
      </div>
    </div>
  )
}
