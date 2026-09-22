import React, { useState, useEffect, useRef } from 'react'
import { usePage } from '@inertiajs/react'
import Layout from '../../components/Layout'

export default function FloorPlanTemplatesCanvasEditor({ template, is_new }) {
  const { auth } = usePage().props
  const canvasRef = useRef(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [mode, setMode] = useState('draw')
  const [drawings, setDrawings] = useState([])
  const [isDrawing, setIsDrawing] = useState(false)
  const [startPos, setStartPos] = useState(null)

  useEffect(() => {
    if (template?.floor_plan_data && Array.isArray(template.floor_plan_data)) {
      setDrawings(template.floor_plan_data)
    } else if (template?.floor_plan_data && typeof template.floor_plan_data === 'object') {
      // floor_plan_data がオブジェクトの場合、空配列を使用
      setDrawings([])
    }
  }, [template])

  // Canvas の初期化と描画
  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return

    const ctx = canvas.getContext('2d')
    const rect = canvas.getBoundingClientRect()

    // Canvas サイズを設定
    canvas.width = rect.width
    canvas.height = rect.height

    // Canvas をクリア
    ctx.fillStyle = '#ffffff'
    ctx.fillRect(0, 0, canvas.width, canvas.height)

    // 既存の drawing を描画
    if (drawings && Array.isArray(drawings)) {
      drawings.forEach(drawing => {
        drawRectangle(ctx, drawing)
      })
    }
  }, [drawings])

  const drawRectangle = (ctx, drawing) => {
    if (!drawing.x || !drawing.y || !drawing.width || !drawing.height) return

    ctx.strokeStyle = '#3b82f6'
    ctx.lineWidth = 2
    ctx.fillStyle = 'rgba(59, 130, 246, 0.1)'

    ctx.fillRect(drawing.x, drawing.y, drawing.width, drawing.height)
    ctx.strokeRect(drawing.x, drawing.y, drawing.width, drawing.height)
  }

  const handleMouseDown = (e) => {
    if (mode === 'select') return

    const rect = canvasRef.current.getBoundingClientRect()
    const x = e.clientX - rect.left
    const y = e.clientY - rect.top

    setIsDrawing(true)
    setStartPos({ x, y })
  }

  const handleMouseMove = (e) => {
    if (!isDrawing || !startPos) return

    const rect = canvasRef.current.getBoundingClientRect()
    const x = e.clientX - rect.left
    const y = e.clientY - rect.top

    // Canvas を再描画
    const canvas = canvasRef.current
    const ctx = canvas.getContext('2d')

    ctx.fillStyle = '#ffffff'
    ctx.fillRect(0, 0, canvas.width, canvas.height)
    ctx.strokeStyle = '#666'
    ctx.lineWidth = 1

    // グリッドを描画（オプション）
    for (let i = 0; i < canvas.width; i += 40) {
      ctx.beginPath()
      ctx.moveTo(i, 0)
      ctx.lineTo(i, canvas.height)
      ctx.strokeStyle = '#f0f0f0'
      ctx.stroke()
    }
    for (let i = 0; i < canvas.height; i += 40) {
      ctx.beginPath()
      ctx.moveTo(0, i)
      ctx.lineTo(canvas.width, i)
      ctx.strokeStyle = '#f0f0f0'
      ctx.stroke()
    }

    // 既存の drawing を描画
    drawings.forEach(drawing => {
      drawRectangle(ctx, drawing)
    })

    // 現在のドラッグを描画
    const width = x - startPos.x
    const height = y - startPos.y

    ctx.fillStyle = 'rgba(59, 130, 246, 0.1)'
    ctx.strokeStyle = '#3b82f6'
    ctx.lineWidth = 2
    ctx.fillRect(startPos.x, startPos.y, width, height)
    ctx.strokeRect(startPos.x, startPos.y, width, height)
  }

  const handleMouseUp = (e) => {
    if (!isDrawing || !startPos) {
      setIsDrawing(false)
      return
    }

    const rect = canvasRef.current.getBoundingClientRect()
    const x = e.clientX - rect.left
    const y = e.clientY - rect.top

    const width = x - startPos.x
    const height = y - startPos.y

    // 最小サイズチェック
    if (Math.abs(width) > 10 && Math.abs(height) > 10) {
      const newDrawing = {
        x: Math.min(startPos.x, x),
        y: Math.min(startPos.y, y),
        width: Math.abs(width),
        height: Math.abs(height)
      }

      setDrawings([...drawings, newDrawing])
    }

    setIsDrawing(false)
    setStartPos(null)
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
            floor_plan_data: drawings
          }
        })
      })

      if (response.ok || response.status === 302) {
        // 上面図保存後、詳細フォームへリダイレクト
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

  const setEditMode = (newMode) => {
    setMode(newMode)
    if (canvasRef.current) {
      if (newMode === 'draw') {
        canvasRef.current.style.cursor = 'crosshair'
      } else {
        canvasRef.current.style.cursor = 'default'
      }
    }
  }

  return (
    <Layout auth={auth}>
      <div className="flex flex-col h-screen bg-gray-100">
        {/* ヘッダー */}
        <div className="bg-white border-b p-4 flex justify-between items-center">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">上面図エディター</h1>
            <p className="text-gray-600 text-sm mt-1">{template.name || '新規テンプレート'}</p>
          </div>
          <div className="flex gap-3">
            <button
              onClick={handleSave}
              disabled={loading}
              className="px-6 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition font-semibold disabled:bg-gray-400"
            >
              {loading ? '保存中...' : '💾 保存'}
            </button>
            <a
              href="/floor_plan_templates"
              className="px-6 py-2 bg-gray-300 text-gray-700 rounded-lg hover:bg-gray-400 transition font-semibold"
            >
              キャンセル
            </a>
          </div>
        </div>

        {error && (
          <div className="p-4 bg-red-100 text-red-700">
            {error}
          </div>
        )}

        {/* ツールバー */}
        <div className="bg-white border-b p-3 flex gap-2 items-center mx-4 mt-4 rounded-lg">
          <div className="flex gap-2">
            <button
              onClick={() => setEditMode('select')}
              className={`px-4 py-2 rounded ${mode === 'select' ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-700'}`}
            >
              ✓ 選択
            </button>
            <button
              onClick={() => setEditMode('draw')}
              className={`px-4 py-2 rounded ${mode === 'draw' ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-700'}`}
            >
              ✏️ 描画
            </button>
          </div>
          <div className="flex-1"></div>
          <span className="text-sm text-gray-600">
            {drawings.length} 個のパターン
          </span>
        </div>

        {/* Canvas */}
        <div className="flex-1 p-4 overflow-auto">
          <div className="bg-white rounded-lg shadow-lg p-4 h-full">
            <canvas
              ref={canvasRef}
              onMouseDown={handleMouseDown}
              onMouseMove={handleMouseMove}
              onMouseUp={handleMouseUp}
              onMouseLeave={handleMouseUp}
              className="w-full h-full border border-gray-300 rounded"
              style={{ display: 'block', background: 'white' }}
            />
          </div>
        </div>
      </div>
    </Layout>
  )
}
