import React, { useState } from 'react'
import TemplatePreview from '../../components/FloorPlanTemplates/TemplatePreview'
import TemplateTabs from '../../components/FloorPlanTemplates/TemplateTabs'
import Pagination, { PageSizeSelect } from '../../components/FloorPlanTemplates/Pagination'

export default function FloorPlanTemplatesIndex({ my_templates }) {
  const [perPage, setPerPage] = useState(12)
  const [page, setPage] = useState(1)

  const pageCount = Math.max(1, Math.ceil(my_templates.length / perPage))
  const currentPage = Math.min(page, pageCount)
  const visibleTemplates = my_templates.slice((currentPage - 1) * perPage, currentPage * perPage)

  return (
      <div className="space-y-6">
        <h1 className="text-3xl font-bold text-gray-900">テンプレート</h1>
        <TemplateTabs active="mine" />

        <div className="flex items-center justify-between">
          <PageSizeSelect
            id="my-templates-per-page"
            value={perPage}
            options={[8, 12, 16]}
            onChange={(count) => {
              setPerPage(count)
              setPage(1)
            }}
          />
          <span className="text-sm text-gray-500">{my_templates.length} 件</span>
        </div>

        <section>
          {visibleTemplates.length > 0 ? (
            <div className="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-4">
              {visibleTemplates.map((template) => (
                <div
                  key={template.id}
                  className="bg-white rounded-lg shadow hover:shadow-lg transition p-4 border-l-4 border-blue-600"
                >
                  <TemplatePreview url={template.preview_image_url} name={template.name} heightClass="h-24" />
                  <h3 className="text-base font-semibold text-gray-900 mb-1 truncate">{template.name}</h3>
                  <p className="text-gray-600 text-xs mb-2 line-clamp-2">{template.description || '説明なし'}</p>
                  <div className="flex items-center justify-between text-xs text-gray-500 mb-3">
                    <span>使用回数: {template.usage_count}</span>
                    <span className={`px-2 py-0.5 rounded text-white text-xs font-medium ${
                      template.is_public ? 'bg-green-600' : 'bg-gray-600'
                    }`}>
                      {template.is_public ? '公開' : 'プライベート'}
                    </span>
                  </div>
                  <div className="flex gap-1">
                    <a
                      href={`/floor_plan_templates/${template.id}`}
                      className="flex-1 text-center px-2 py-1.5 bg-blue-600 text-white rounded hover:bg-blue-700 transition text-xs"
                    >
                      詳細
                    </a>
                    <a
                      href={`/floor_plan_templates/${template.id}/details`}
                      className="flex-1 text-center px-2 py-1.5 bg-gray-600 text-white rounded hover:bg-gray-700 transition text-xs"
                    >
                      公開設定
                    </a>
                    <a
                      href={`/floor_plan_templates/${template.id}/edit`}
                      className="flex-1 text-center px-2 py-1.5 bg-yellow-600 text-white rounded hover:bg-yellow-700 transition text-xs"
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
                        className="w-full px-2 py-1.5 bg-red-600 text-white rounded hover:bg-red-700 transition text-xs"
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

        <Pagination page={currentPage} pageCount={pageCount} onChange={setPage} />

        <div className="flex justify-center">
          <a
            href="/floor_plan_templates/new"
            className="px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition font-semibold"
          >
            新規テンプレート作成
          </a>
        </div>
      </div>
    )
  }
