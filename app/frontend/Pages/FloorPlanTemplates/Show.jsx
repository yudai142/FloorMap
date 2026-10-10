import React from 'react'
import { usePage } from '@inertiajs/react'

export default function FloorPlanTemplatesShow({ template }) {
  const { auth } = usePage().props
  const isOwner = auth?.user?.id === template.user.id

  const handleImport = () => {
    // テンプレートを使用して新しいルームを作成
    window.location.href = `/rooms/new?template_id=${template.id}`
  }

  return (
      <div className="max-w-2xl mx-auto space-y-6">
        <div className="bg-white rounded-lg shadow-lg p-8">
          <div className="mb-6">
            <h1 className="text-3xl font-bold text-gray-900">{template.name}</h1>
            <p className="text-gray-600 mt-2">作成者: {template.user.username}</p>
            <p className="text-gray-500 text-sm mt-1">
              作成日時: {new Date(template.created_at).toLocaleDateString('ja-JP')}
            </p>
          </div>

          <div className="mb-6 p-4 bg-gray-100 rounded">
            <p className="text-gray-700 whitespace-pre-wrap">{template.description || 'テンプレートの説明がありません'}</p>
          </div>

          <div className="grid grid-cols-2 gap-4 mb-6">
            <div className="bg-blue-50 p-4 rounded">
              <p className="text-sm text-gray-600">公開状態</p>
              <p className="text-lg font-semibold text-gray-900">
                {template.is_public ? '🌍 公開' : '🔒 プライベート'}
              </p>
            </div>
            <div className="bg-green-50 p-4 rounded">
              <p className="text-sm text-gray-600">使用回数</p>
              <p className="text-lg font-semibold text-gray-900">{template.usage_count} 回</p>
            </div>
          </div>

          <div className="border-t pt-6 space-y-4">
            {isOwner && (
              <>
                <a
                  href={`/floor_plan_templates/${template.id}/edit`}
                  className="w-full block text-center px-4 py-3 bg-yellow-600 text-white rounded-lg hover:bg-yellow-700 transition font-semibold"
                >
                  編集
                </a>
                <form
                  action={`/floor_plan_templates/${template.id}`}
                  method="DELETE"
                  onSubmit={(e) => {
                    if (!confirm('このテンプレートを削除してもよろしいですか？')) {
                      e.preventDefault()
                    }
                  }}
                >
                  <button
                    type="submit"
                    className="w-full px-4 py-3 bg-red-600 text-white rounded-lg hover:bg-red-700 transition font-semibold"
                  >
                    削除
                  </button>
                </form>
              </>
            )}
            <button
              onClick={handleImport}
              className="w-full px-4 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition font-semibold"
            >
              このテンプレートを使用して新規ルーム作成
            </button>
            <a
              href="/floor_plan_templates"
              className="w-full block text-center px-4 py-3 bg-gray-300 text-gray-700 rounded-lg hover:bg-gray-400 transition font-semibold"
            >
              一覧に戻る
            </a>
          </div>
        </div>
      </div>
    )
  }
