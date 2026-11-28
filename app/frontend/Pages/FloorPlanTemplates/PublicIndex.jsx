import React, { useState } from 'react'
import TemplatePreview from '../../components/FloorPlanTemplates/TemplatePreview'
import FavoriteButton from '../../components/FloorPlanTemplates/FavoriteButton'
import TemplateTabs from '../../components/FloorPlanTemplates/TemplateTabs'
import Pagination, { PageSizeSelect } from '../../components/FloorPlanTemplates/Pagination'

export default function FloorPlanTemplatesPublicIndex({ public_templates, favorites_only = false }) {
  const [favoriteIds, setFavoriteIds] = useState(
    () => new Set(public_templates.filter((template) => template.favorited).map((template) => template.id))
  )
  const [perPage, setPerPage] = useState(12)
  const [page, setPage] = useState(1)

  const handleFavoriteChange = (templateId, favorited) => {
    setFavoriteIds((prev) => {
      const next = new Set(prev)
      if (favorited) {
        next.add(templateId)
      } else {
        next.delete(templateId)
      }
      return next
    })
  }

  const filteredTemplates = favorites_only
    ? public_templates.filter((template) => favoriteIds.has(template.id))
    : public_templates

  const pageCount = Math.max(1, Math.ceil(filteredTemplates.length / perPage))
  const currentPage = Math.min(page, pageCount)
  const visibleTemplates = filteredTemplates.slice((currentPage - 1) * perPage, currentPage * perPage)

  return (
      <div className="space-y-6">
        <h1 className="text-3xl font-bold text-gray-900">テンプレート</h1>
        <TemplateTabs active={favorites_only ? 'favorites' : 'public'} />

        <div className="flex flex-wrap items-center justify-between gap-4">
          <PageSizeSelect
            id="public-templates-per-page"
            value={perPage}
            options={[8, 12, 16]}
            onChange={(count) => {
              setPerPage(count)
              setPage(1)
            }}
          />
          <span className="text-sm text-gray-500">{filteredTemplates.length} 件</span>
        </div>

        <section>
          {visibleTemplates.length > 0 ? (
            <div className="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-4">
              {visibleTemplates.map((template) => (
                <div
                  key={template.id}
                  className="bg-white rounded-lg shadow hover:shadow-lg transition p-4 border-l-4 border-green-600"
                >
                  <TemplatePreview url={template.preview_image_url} name={template.name} heightClass="h-24" />
                  <h3 className="text-base font-semibold text-gray-900 mb-1 truncate">{template.name}</h3>
                  <p className="text-gray-600 text-xs mb-1 line-clamp-2">{template.description || '説明なし'}</p>
                  <p className="text-gray-500 text-xs mb-2">作成者: {template.user.username}</p>
                  <div className="mb-2">
                    <FavoriteButton
                      templateId={template.id}
                      initialFavorited={template.favorited}
                      onChange={handleFavoriteChange}
                    />
                  </div>
                  <div className="flex items-center justify-between text-xs text-gray-500 mb-2">
                    <span>使用回数: {template.usage_count}</span>
                  </div>
                  <a
                    href={`/floor_plan_templates/${template.id}`}
                    className="w-full text-center px-2 py-1.5 bg-blue-600 text-white rounded hover:bg-blue-700 transition text-xs block"
                  >
                    このテンプレートを使用
                  </a>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-gray-500">
              {favorites_only ? 'お気に入りのテンプレートはありません' : '公開テンプレートはありません'}
            </p>
          )}
        </section>

        <Pagination page={currentPage} pageCount={pageCount} onChange={setPage} />
      </div>
    )
  }
