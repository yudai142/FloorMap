import React, { useState } from 'react'
import { usePage } from '@inertiajs/react'
import Layout from '../../components/Layout'

export default function FloorPlanTemplatesNew() {
  const { auth } = usePage().props
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    is_public: false
  })
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }))
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setLoading(true)
    setError('')

    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
      const response = await fetch('/floor_plan_templates', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'X-CSRF-Token': csrfToken,
        },
        body: new URLSearchParams({
          'name': formData.name,
          'description': formData.description,
          'is_public': formData.is_public
        })
      })

      if (response.ok || response.status === 302) {
        // リダイレクト後、最新のテンプレートをキャンバスエディターで開く
        window.location.href = response.url || '/floor_plan_templates'
      } else {
        setError('テンプレート作成に失敗しました')
      }
    } catch (err) {
      setError('エラーが発生しました: ' + err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <Layout auth={auth}>
      <div className="max-w-2xl mx-auto">
        <h1 className="text-3xl font-bold text-gray-900 mb-6">新規テンプレート作成</h1>

        <div className="bg-white rounded-lg shadow-lg p-8">
          {error && (
            <div className="mb-6 p-4 bg-red-100 text-red-700 rounded">
              {error}
            </div>
          )}

          <p className="text-gray-600 mb-6">
            テンプレート名と説明を入力した後、上面図エディターで上面図を設計・保存できます。
          </p>

          <form onSubmit={handleSubmit} className="space-y-6">
            <div>
              <label htmlFor="name" className="block text-sm font-medium text-gray-700 mb-2">
                テンプレート名 <span className="text-red-600">*</span>
              </label>
              <input
                type="text"
                id="name"
                name="name"
                value={formData.name}
                onChange={handleChange}
                required
                placeholder="例: 会議室レイアウト A"
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>

            <div>
              <label htmlFor="description" className="block text-sm font-medium text-gray-700 mb-2">
                説明
              </label>
              <textarea
                id="description"
                name="description"
                value={formData.description}
                onChange={handleChange}
                rows="3"
                placeholder="このテンプレートの説明を入力してください"
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>

            <div className="flex items-center">
              <input
                type="checkbox"
                id="is_public"
                name="is_public"
                checked={formData.is_public}
                onChange={handleChange}
                className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
              />
              <label htmlFor="is_public" className="ml-3 block text-sm font-medium text-gray-700">
                公開テンプレート（他のユーザーが使用できます）
              </label>
            </div>

            <div className="border-t pt-6 flex gap-4">
              <button
                type="submit"
                disabled={loading}
                className="flex-1 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition font-semibold disabled:bg-gray-400"
              >
                {loading ? '作成中...' : '次へ（上面図エディター）'}
              </button>
              <a
                href="/floor_plan_templates"
                className="flex-1 text-center px-6 py-3 bg-gray-300 text-gray-700 rounded-lg hover:bg-gray-400 transition font-semibold"
              >
                キャンセル
              </a>
            </div>
          </form>
        </div>
      </div>
    </Layout>
  )
}
