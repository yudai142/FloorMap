import React, { useState, useEffect, useRef } from 'react'
import { usePage } from '@inertiajs/react'

export default function FloorPlanTemplatesCanvasEditor({ template, is_new }) {
  const { auth } = usePage().props
  const canvasRef = useRef(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [currentMode, setCurrentMode] = useState('select')

  // Stimulus controller を初期化
  useEffect(() => {
    if (!canvasRef.current) return

    // グローバル変数を設定（seat-canvas controller が使用）
    window.currentEditMode = 'select'

    // canvas 要素に Stimulus controller を紐付け
    // Stimulus is automatically initialized on page load
    // Here we just need to ensure the canvas element exists and is properly configured
  }, [canvasRef])

  const setEditMode = (mode) => {
    window.currentEditMode = mode
    setCurrentMode(mode)

    // Canvas カーソルを変更
    const canvas = canvasRef.current
    if (canvas) {
      canvas.classList.remove('draw-mode', 'delete-mode')
      if (mode === 'draw') {
        canvas.classList.add('draw-mode')
      } else if (mode === 'delete') {
        canvas.classList.add('delete-mode')
      }
    }
  }

  const handleSave = async () => {
    setLoading(true)
    setError('')

    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
      const response = await fetch(`/floor_plan_templates/${template.id}/canvas_editor`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken,
        },
        body: JSON.stringify({
          floor_plan_template: {
            floor_plan_data: {}
          }
        })
      })

      if (response.ok || response.status === 302) {
        window.location.href = `/floor_plan_templates/${template.id}/details`
      } else {
        setError('上面図保存に失敗しました')
      }
    } catch (err) {
      setError('エラーが発生しました: ' + err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div>
      <style>{`
        .editor-container {
          background-color: #f8fafc;
          min-height: calc(100vh - 64px);
          padding: 32px 64px;
        }

        .editor-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 24px;
        }

        .editor-title {
          font-size: 28px;
          font-weight: bold;
          color: #0f172a;
        }

        .back-link {
          display: flex;
          align-items: center;
          gap: 4px;
          color: #64748b;
          text-decoration: none;
          font-size: 14px;
          font-weight: 500;
        }

        .back-link:hover {
          color: #334155;
        }

        .editor-toolbar {
          background: white;
          border: 1px solid #e2e8f0;
          border-radius: 8px;
          padding: 12px 16px;
          display: flex;
          gap: 8px;
          align-items: center;
          margin-bottom: 16px;
        }

        .toolbar-group {
          display: flex;
          gap: 8px;
          align-items: center;
        }

        .toolbar-divider {
          width: 1px;
          height: 24px;
          background-color: #e2e8f0;
        }

        .toolbar-button {
          background: white;
          border: 1px solid #e2e8f0;
          padding: 6px 12px;
          border-radius: 6px;
          cursor: pointer;
          font-weight: 500;
          font-size: 13px;
          color: #475569;
          display: flex;
          gap: 4px;
          align-items: center;
          transition: all 0.2s;
        }

        .toolbar-button:hover {
          background-color: #f8fafc;
          border-color: #cbd5e1;
        }

        .toolbar-button.active {
          background-color: #3b82f6;
          color: white;
          border-color: #3b82f6;
        }

        .canvas-wrapper {
          background: white;
          border: 1px solid #e2e8f0;
          border-radius: 16px;
          padding: 32px;
          min-height: calc(100vh - 280px);
          display: flex;
          align-items: center;
          justify-content: center;
        }

        canvas {
          border: 1px solid #cbd5e1;
          border-radius: 12px;
          background-color: #ffffff;
          width: 100%;
          height: 100%;
          display: block;
          cursor: default;
        }

        canvas.draw-mode {
          cursor: crosshair;
        }

        canvas.delete-mode {
          cursor: not-allowed;
        }
      `}</style>

      <div className="editor-container">
        <div className="editor-header">
          <div>
            <a href="/floor_plan_templates" className="back-link">← 戻る</a>
          </div>
          <h1 className="editor-title">上面図エディター</h1>
        </div>

        {error && (
          <div className="p-4 bg-red-100 text-red-700 rounded mb-4">
            {error}
          </div>
        )}

        {/* Editor Toolbar */}
        <div className="editor-toolbar">
          <div className="toolbar-group">
            <span style={{ fontSize: '12px', color: '#64748b', fontWeight: '600' }}>モード:</span>
            <button
              className={`toolbar-button ${currentMode === 'select' ? 'active' : ''}`}
              onClick={() => setEditMode('select')}
              title="選択モード (S)"
            >
              ✓ 選択
            </button>
            <button
              className={`toolbar-button ${currentMode === 'draw' ? 'active' : ''}`}
              onClick={() => setEditMode('draw')}
              title="描画モード (D)"
            >
              ✏️ 描画
            </button>
            <button
              className={`toolbar-button ${currentMode === 'delete' ? 'active' : ''}`}
              onClick={() => setEditMode('delete')}
              title="削除モード (Del)"
            >
              🗑️ 削除
            </button>
          </div>
          <div className="toolbar-divider"></div>
          <div style={{ flex: 1 }}></div>
          <div className="toolbar-group">
            <button
              className="toolbar-button"
              onClick={handleSave}
              disabled={loading}
              style={{
                backgroundColor: '#10b981',
                color: 'white',
                borderColor: '#10b981',
                opacity: loading ? 0.6 : 1
              }}
            >
              💾 {loading ? '保存中...' : '保存'}
            </button>
          </div>
        </div>

        <div className="canvas-wrapper">
          <canvas
            ref={canvasRef}
            id="floor-canvas"
            data-controller="seat-canvas"
            data-seat-canvas-target="canvas"
            data-seat-canvas-template-id-value={template.id}
            data-seat-canvas-context-value="editor"
            data-seat-canvas-current-user-id-value={auth?.user?.id || 0}
            data-seat-canvas-can-manage-value="true"
            style={{
              border: '1px solid #e2e8f0',
              borderRadius: '12px',
              backgroundColor: '#ffffff'
            }}
          ></canvas>
        </div>
      </div>
    </div>
  )
}
