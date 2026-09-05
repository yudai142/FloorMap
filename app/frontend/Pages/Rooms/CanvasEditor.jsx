import React from 'react'
import { usePage } from '@inertiajs/react'
import Canvas from '../../components/Editor/Canvas'

export default function CanvasEditor({ room, shapes_data, seats, current_user }) {
  const { auth } = usePage().props

  const handleSave = async (shapes) => {
    // Save is handled in Canvas component
    // This callback can be extended for additional logic
    console.log('Canvas saved:', shapes)
  }

  return (
    <div className="h-screen flex flex-col bg-base-100">
      {/* Header */}
      <div className="bg-white border-b border-base-300 shadow-sm">
        <div className="max-w-full px-4 py-3">
          <div className="flex items-center gap-4">
            <a href="/rooms" className="text-sm font-medium text-blue-600 hover:text-blue-800">
              ← 戻る
            </a>
            <h1 className="text-2xl font-bold text-slate-900">{room.name}</h1>
            <span className="badge badge-lg">
              {room.width} × {room.height}px
            </span>
          </div>
          <p className="text-sm text-slate-600 mt-1">
            座席配置図エディタ - ツールを選択して、キャンバスをクリック・ドラッグして描画
          </p>
        </div>
      </div>

      {/* Canvas Component */}
      <Canvas
        room={room}
        initialShapes={shapes_data || []}
        initialSeats={seats || []}
        onSave={handleSave}
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
