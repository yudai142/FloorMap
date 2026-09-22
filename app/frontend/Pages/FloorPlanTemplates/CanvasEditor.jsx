import React, { useState, useEffect } from 'react'
import { usePage } from '@inertiajs/react'
import Layout from '../../components/Layout'

export default function FloorPlanTemplatesCanvasEditor({ template }) {
  const { auth } = usePage().props
  const [drawings, setDrawings] = useState([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    if (template?.floor_plan_data && Array.isArray(template.floor_plan_data)) {
      setDrawings(template.floor_plan_data)
    }
  }, [template])

  const handleSave = async () => {
    setLoading(true)
    setError('')

    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
      const response = await fetch(`/floor_plan_templates/${template.id}/save_floor_plan`, {
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
        window.location.href = '/floor_plan_templates'
      } else {
        setError('テンプレート保存に失敗しました')
      }
    } catch (err) {
      setError('エラーが発生しました: ' + err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <Layout auth={auth}>
      <div className="flex flex-col h-full">
        <div className="bg-white border-b p-4 flex justify-between items-center">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">{template.name}</h1>
            <p className="text-gray-600 text-sm mt-1">{template.description}</p>
          </div>
          <div className="flex gap-3">
            <button
              onClick={handleSave}
              disabled={loading}
              className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition font-semibold disabled:bg-gray-400"
            >
              {loading ? '保存中...' : '保存'}
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

        <div className="flex-1 bg-gray-100 p-4">
          <div className="bg-white rounded-lg shadow-lg p-6 h-full">
            <div className="border-2 border-dashed border-gray-300 rounded-lg p-8 h-full flex items-center justify-center bg-gray-50">
              <div className="text-center">
                <p className="text-gray-600 text-lg mb-2">上面図エディター</p>
                <p className="text-gray-500">このセクションでは、キャンバス上に壁・パーティション・座席を配置できます。</p>
                <p className="text-gray-500 text-sm mt-2">（詳細な実装は rooms/canvas_editor と連携）</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layout>
  )
}
