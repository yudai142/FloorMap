import React, { useState } from 'react'
import { usePage } from '@inertiajs/react'
import Canvas from '../../components/Editor/Canvas'

export default function CanvasEditor({ room, shapes_data, seats, current_user }) {
  const { auth } = usePage().props
  const [canvasSize, setCanvasSize] = useState({ width: room.width, height: room.height })
  const [autoCheckoutEnabled, setAutoCheckoutEnabled] = useState(room.auto_checkout_enabled || false)
  const [autoCheckoutTime, setAutoCheckoutTime] = useState(room.auto_checkout_time || '')

  const handleSave = async (shapes) => {
    // Save is handled in Canvas component
    // This callback can be extended for additional logic
    console.log('Canvas saved:', shapes)
  }

  const handleSaveCanvas = async (shapes) => {
    // Save room settings (size, auto checkout)
    const roomUpdates = {
      width: canvasSize.width,
      height: canvasSize.height,
      auto_checkout_enabled: autoCheckoutEnabled,
      auto_checkout_time: autoCheckoutTime
    }

    try {
      await fetch(`/rooms/${room.share_token}`, {
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
    handleSave(shapes)
  }

  return (
    <div className="h-screen flex flex-col bg-base-100">
      {/* Header */}
      <div className="bg-white border-b border-base-300 shadow-sm">
        <div className="max-w-full px-4 py-3">
          <div className="flex items-center gap-4">
            <a href={`/rooms/${room.share_token}`} className="text-sm font-medium text-blue-600 hover:text-blue-800">
              ← 戻る
            </a>
            <h1 className="text-2xl font-bold text-slate-900">{room.name}</h1>
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
                value={canvasSize.width || room.width || 1000}
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
                value={canvasSize.height || room.height || 700}
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
        room={{ ...room, width: canvasSize.width, height: canvasSize.height }}
        initialShapes={shapes_data || []}
        initialSeats={seats || []}
        onSave={handleSaveCanvas}
        canvasSize={canvasSize}
        onCanvasSizeChange={setCanvasSize}
      />

      {/* Footer */}
      <div className="bg-slate-50 border-t border-slate-200 px-4 py-2 text-xs text-slate-500 text-center">
        <p>
          ユーザー: {current_user?.email || 'Anonymous'} | React + Zustand Canvas Editor (Phase 1)
        </p>
      </div>
    </div>
  )
}
