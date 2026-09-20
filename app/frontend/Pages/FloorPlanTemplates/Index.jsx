import React from 'react'
import { usePage } from '@inertiajs/react'
import Layout from '../../components/Layout'

export default function FloorPlanTemplatesIndex({ my_templates, public_templates }) {
  const { auth } = usePage().props

  return (
    <Layout auth={auth}>
      <div className="space-y-8">
        <h1 className="text-3xl font-bold text-gray-900">上面図テンプレート</h1>

        {/* 自分のテンプレート */}
        <section>
          <h2 className="text-2xl font-semibold text-gray-800 mb-4">マイテンプレート</h2>
          {my_templates.length > 0 ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {my_templates.map((template) => (
                <div
                  key={template.id}
                  className="bg-white rounded-lg shadow hover:shadow-lg transition p-6 border-l-4 border-blue-600"
                >
                  <h3 className="text-xl font-semibold text-gray-900 mb-2">{template.name}</h3>
                  <p className="text-gray-600 text-sm mb-4 line-clamp-3">{template.description || '説明なし'}</p>
                  <div className="flex items-center justify-between text-sm text-gray-500 mb-4">
                    <span>使用回数: {template.usage_count}</span>
                    <span className={`px-3 py-1 rounded text-white text-xs font-medium ${
                      template.is_public ? 'bg-green-600' : 'bg-gray-600'
                    }`}>
                      {template.is_public ? '公開' : 'プライベート'}
                    </span>
                  </div>
                  <div className="flex gap-2">
                    <a
                      href={`/floor_plan_templates/${template.id}`}
                      className="flex-1 text-center px-3 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition text-sm"
                    >
                      詳細
                    </a>
                    <a
                      href={`/floor_plan_templates/${template.id}/edit`}
                      className="flex-1 text-center px-3 py-2 bg-yellow-600 text-white rounded hover:bg-yellow-700 transition text-sm"
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
                      className="flex-1"
                    >
                      <button
                        type="submit"
                        className="w-full px-3 py-2 bg-red-600 text-white rounded hover:bg-red-700 transition text-sm"
                      >
                        削除
                      </button>
                    </form>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-gray-500">テンプレートはまだ作成されていません</p>
          )}
        </section>

        {/* 公開テンプレート */}
        <section>
          <h2 className="text-2xl font-semibold text-gray-800 mb-4">公開テンプレート</h2>
          {public_templates.length > 0 ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {public_templates.map((template) => (
                <div
                  key={template.id}
                  className="bg-white rounded-lg shadow hover:shadow-lg transition p-6 border-l-4 border-green-600"
                >
                  <h3 className="text-xl font-semibold text-gray-900 mb-2">{template.name}</h3>
                  <p className="text-gray-600 text-sm mb-2">{template.description || '説明なし'}</p>
                  <p className="text-gray-500 text-xs mb-4">作成者: {template.user.username}</p>
                  <div className="flex items-center justify-between text-sm text-gray-500 mb-4">
                    <span>使用回数: {template.usage_count}</span>
                  </div>
                  <a
                    href={`/floor_plan_templates/${template.id}`}
                    className="w-full text-center px-3 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition text-sm block"
                  >
                    このテンプレートを使用
                  </a>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-gray-500">公開テンプレートはありません</p>
          )}
        </section>

        {/* テンプレート新規作成ボタン */}
        <div className="flex justify-center">
          <a
            href="/floor_plan_templates/new"
            className="px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition font-semibold"
          >
            新規テンプレート作成
          </a>
        </div>
      </div>
    </Layout>
  )
}
