import React from 'react'
import { ZoomIn, ZoomOut, RotateCcw, LayoutGrid, Save, Undo2, Redo2 } from 'lucide-react'
import { useEditorStore } from '../../store/editorStore'
import './EditorToolbar.css'

export default function EditorToolbar({
  currentTool,
  zoom,
  showGrid,
  onZoomIn,
  onZoomOut,
  onZoomReset,
  onToggleGrid,
  onUndo,
  onRedo,
  onSave,
  isSaving,
  hasUnsavedChanges,
  historyIndex,
  historyLength,
}) {
  const { setCurrentTool, drawMode, setDrawMode, selectedColor, setSelectedColor } = useEditorStore()

  const tools = [
    { id: 'select', label: '選択', emoji: '✓' },
    { id: 'seat', label: '座席', emoji: '🪑' },
    { id: 'line', label: '直線', emoji: '—' },
    { id: 'rectangle', label: '四角形', emoji: '▭' },
    { id: 'circle', label: '円', emoji: '●' },
    { id: 'arrow', label: '矢印', emoji: '→' },
    { id: 'text', label: 'テキスト', emoji: 'T' },
    { id: 'polygon', label: 'ポリゴン', emoji: '▲' },
    { id: 'delete', label: '削除', emoji: '🗑️' },
  ]

  const colorPresets = [
    { name: '青', value: '#3b82f6' },
    { name: '赤', value: '#ef4444' },
    { name: '緑', value: '#22c55e' },
    { name: '黄', value: '#eab308' },
    { name: '紫', value: '#a855f7' },
    { name: 'オレンジ', value: '#f97316' },
    { name: '黒', value: '#1f2937' },
    { name: 'グレー', value: '#6b7280' },
  ]

  return (
    <div className="editor-toolbar bg-base-100 border-b border-base-300 shadow-sm">
      {/* Tool Selection */}
      <div className="flex gap-2 p-4 flex-wrap">
        <div className="flex gap-1 flex-wrap">
          {tools.map((tool) => (
            <button
              key={tool.id}
              onClick={() => setCurrentTool(tool.id)}
              className={`btn btn-sm gap-1 ${
                currentTool === tool.id
                  ? 'btn-primary'
                  : tool.id === 'delete'
                  ? 'btn-error btn-outline'
                  : 'btn-ghost'
              }`}
              title={tool.label}
            >
              <span>{tool.emoji}</span>
              <span className="hidden sm:inline">{tool.label}</span>
            </button>
          ))}
        </div>

        <div className="divider divider-horizontal my-0"></div>

        {/* History Controls */}
        <div className="flex gap-1">
          <button
            onClick={onUndo}
            disabled={historyIndex <= 0}
            className="btn btn-sm btn-ghost gap-1"
            title="戻す (Ctrl+Z)"
          >
            <Undo2 className="w-4 h-4" />
            <span className="hidden sm:inline">戻す</span>
          </button>
          <button
            onClick={onRedo}
            disabled={historyIndex >= historyLength - 1}
            className="btn btn-sm btn-ghost gap-1"
            title="やり直す (Ctrl+Y)"
          >
            <Redo2 className="w-4 h-4" />
            <span className="hidden sm:inline">やり直す</span>
          </button>
        </div>

        <div className="divider divider-horizontal my-0"></div>

        {/* Draw Mode (for drawing tools) */}
        {['line', 'rectangle', 'circle', 'arrow'].includes(currentTool) && (
          <>
            <div className="flex gap-1">
              <span className="text-sm font-medium flex items-center">描画方法:</span>
              <button
                onClick={() => setDrawMode('click')}
                className={`btn btn-sm ${drawMode === 'click' ? 'btn-secondary' : 'btn-ghost'}`}
              >
                2点選択
              </button>
              <button
                onClick={() => setDrawMode('drag')}
                className={`btn btn-sm ${drawMode === 'drag' ? 'btn-secondary' : 'btn-ghost'}`}
              >
                ドラッグ
              </button>
            </div>
            <div className="divider divider-horizontal my-0"></div>
          </>
        )}

        {/* Color Picker */}
        <div className="flex gap-1 items-center">
          <span className="text-sm font-medium hidden sm:inline">色:</span>
          <div className="flex gap-1">
            {colorPresets.map((preset) => (
              <button
                key={preset.value}
                onClick={() => setSelectedColor(preset.value)}
                className={`w-6 h-6 rounded border-2 transition-all ${
                  selectedColor === preset.value
                    ? 'border-slate-800 ring-2 ring-slate-300'
                    : 'border-slate-300 hover:border-slate-500'
                }`}
                style={{ backgroundColor: preset.value }}
                title={preset.name}
              />
            ))}
          </div>
        </div>

        <div className="divider divider-horizontal my-0"></div>

        {/* Grid & Zoom Controls */}
        <div className="flex gap-1">
          <button
            onClick={onToggleGrid}
            className={`btn btn-sm gap-1 ${showGrid ? 'btn-secondary' : 'btn-ghost'}`}
          >
            <LayoutGrid className="w-4 h-4" />
            <span className="hidden sm:inline">グリッド</span>
          </button>
        </div>

        <div className="flex gap-1 items-center">
          <span className="text-sm font-medium hidden sm:inline">ズーム:</span>
          <button
            onClick={onZoomOut}
            className="btn btn-xs btn-ghost"
          >
            −
          </button>
          <span className="text-sm font-medium w-12 text-center">
            {Math.round(zoom * 100)}%
          </span>
          <button
            onClick={onZoomIn}
            className="btn btn-xs btn-ghost"
          >
            +
          </button>
          <button
            onClick={onZoomReset}
            className="btn btn-xs btn-ghost"
          >
            リセット
          </button>
        </div>

        <div className="flex-1"></div>

        {/* Save Button */}
        <button
          onClick={onSave}
          disabled={isSaving}
          className={`btn btn-lg gap-2 ${
            hasUnsavedChanges ? 'btn-primary' : 'btn-ghost'
          }`}
        >
          {isSaving ? (
            <>
              <span className="loading loading-spinner loading-sm"></span>
              保存中...
            </>
          ) : (
            <>
              <Save className="w-5 h-5" />
              <span className="hidden sm:inline">保存</span>
            </>
          )}
        </button>
      </div>
    </div>
  )
}
