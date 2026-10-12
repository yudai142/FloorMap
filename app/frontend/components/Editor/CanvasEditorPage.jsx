import React, { useState } from 'react'
import Canvas from './Canvas'

export default function CanvasEditorPage({ entity, backHref, shapes, seats, currentUser, persistence }) {
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

          {/* 全員離席設定 */}
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
