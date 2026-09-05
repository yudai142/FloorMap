import React from 'react'
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
      <div className="flex gap-3 p-4 flex-wrap">
        {/* Tool Selection Group */}
        <div className="border-2 border-blue-300 rounded-lg p-3 bg-blue-50 shadow-sm">
          <div className="flex gap-1 flex-wrap">
            {tools.map((tool) => (
              <button
                key={tool.id}
                onClick={() => setCurrentTool(tool.id)}
                className={`btn btn-sm gap-1 font-medium transition-all text-slate-900 border-2 ${
                  currentTool === tool.id
                    ? tool.id === 'delete'
                      ? 'btn-error border-slate-900 shadow-lg'
                      : 'btn-info border-slate-900 shadow-lg'
                    : tool.id === 'delete'
                    ? 'btn-error btn-outline hover:btn-error'
                    : 'btn-outline hover:border-blue-400 hover:bg-blue-100 border-slate-300'
                }`}
                title={tool.label}
              >
                <span className="text-lg">{tool.emoji}</span>
                <span className="hidden sm:inline text-sm">{tool.label}</span>
              </button>
            ))}
          </div>
        </div>

        {/* History Controls Group */}
        <div className="border-2 border-orange-300 rounded-lg p-3 bg-orange-50 shadow-sm">
          <div className="flex gap-2 items-center">
            <span className="text-xs font-bold text-orange-700">編集:</span>
            <button
              onClick={onUndo}
              disabled={historyIndex <= 0}
              className="btn btn-sm btn-outline hover:btn-warning disabled:btn-ghost disabled:opacity-50 gap-1 font-medium transition-all"
              title="戻す (Ctrl+Z)"
            >
              <span className="text-lg">↶</span>
              <span className="hidden sm:inline">戻す</span>
            </button>
            <button
              onClick={onRedo}
              disabled={historyIndex >= historyLength - 1}
              className="btn btn-sm btn-outline hover:btn-warning disabled:btn-ghost disabled:opacity-50 gap-1 font-medium transition-all"
              title="やり直す (Ctrl+Y)"
            >
              <span className="text-lg">↷</span>
              <span className="hidden sm:inline">やり直す</span>
            </button>
          </div>
        </div>

        {/* Draw Mode Group */}
        {['line', 'rectangle', 'circle', 'arrow'].includes(currentTool) && (
          <div className="border-2 border-purple-300 rounded-lg p-3 bg-purple-50 shadow-sm">
            <div className="flex gap-2 items-center">
              <span className="text-xs font-bold text-purple-700">描画:</span>
              <button
                onClick={() => setDrawMode('click')}
                className={`btn btn-sm font-medium transition-all border-2 ${
                  drawMode === 'click'
                    ? 'btn-secondary shadow-md border-slate-900'
                    : 'btn-outline hover:border-purple-400 hover:bg-purple-100 border-slate-300'
                }`}
              >
                2点選択
              </button>
              <button
                onClick={() => setDrawMode('drag')}
                className={`btn btn-sm font-medium transition-all border-2 ${
                  drawMode === 'drag'
                    ? 'btn-secondary shadow-md border-slate-900'
                    : 'btn-outline hover:border-purple-400 hover:bg-purple-100 border-slate-300'
                }`}
              >
                ドラッグ
              </button>
            </div>
          </div>
        )}

        {/* Color Picker Group */}
        <div className="border-2 border-green-300 rounded-lg p-3 bg-green-50 shadow-sm">
          <div className="flex gap-2 items-center">
            <span className="text-xs font-bold text-green-700 hidden sm:inline">色:</span>
            <div className="flex gap-2">
              {colorPresets.map((preset) => (
                <button
                  key={preset.value}
                  onClick={() => setSelectedColor(preset.value)}
                  className={`w-8 h-8 rounded-lg border-3 transition-all cursor-pointer shadow-sm hover:scale-110 ${
                    selectedColor === preset.value
                      ? 'border-slate-900 ring-3 ring-offset-1 ring-green-400 scale-110'
                      : 'border-slate-400 hover:border-slate-600'
                  }`}
                  style={{ backgroundColor: preset.value }}
                  title={preset.name}
                />
              ))}
            </div>
          </div>
        </div>

        {/* Grid & Zoom Group */}
        <div className="border-2 border-cyan-300 rounded-lg p-3 bg-cyan-50 shadow-sm">
          <div className="flex gap-2 items-center flex-wrap">
            <button
              onClick={onToggleGrid}
              className={`btn btn-sm gap-1 font-medium transition-all border-2 text-slate-900 ${
                showGrid
                  ? 'btn-success shadow-md border-slate-900'
                  : 'btn-outline hover:border-cyan-400 hover:bg-cyan-100 border-slate-300'
              }`}
            >
              <span className="text-lg">⊞</span>
              <span className="hidden sm:inline">グリッド</span>
            </button>
            <span className="text-xs font-bold text-cyan-700 hidden sm:inline">ズーム:</span>
            <button
              onClick={onZoomOut}
              className="btn btn-xs btn-outline hover:btn-info font-bold transition-all"
            >
              −
            </button>
            <span className="text-sm font-bold w-12 text-center text-cyan-700 bg-white rounded px-1 py-0.5">
              {Math.round(zoom * 100)}%
            </span>
            <button
              onClick={onZoomIn}
              className="btn btn-xs btn-outline hover:btn-info font-bold transition-all"
            >
              +
            </button>
            <button
              onClick={onZoomReset}
              className="btn btn-xs btn-outline hover:btn-info font-bold transition-all"
            >
              リセット
            </button>
          </div>
        </div>

        <div className="flex-1"></div>

        {/* Save Button Group */}
        <button
          onClick={onSave}
          disabled={isSaving}
          className={`btn btn-lg gap-2 font-bold transition-all text-slate-900 bg-lime-400 border-2 border-lime-500 rounded-lg ${
            hasUnsavedChanges
              ? 'shadow-lg hover:shadow-xl'
              : 'hover:bg-lime-300'
          }`}
        >
            {isSaving ? (
              <>
                <span className="loading loading-spinner loading-sm"></span>
                保存中...
              </>
            ) : (
              <>
                <span className="text-2xl">💾</span>
                <span className="hidden sm:inline">保存</span>
              </>
            )}
        </button>

      </div>
    </div>
  )
}
