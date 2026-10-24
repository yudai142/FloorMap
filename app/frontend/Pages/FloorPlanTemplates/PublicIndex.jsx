import React from 'react'
import TemplatePreview from '../../components/FloorPlanTemplates/TemplatePreview'

export default function FloorPlanTemplatesPublicIndex({ public_templates }) {
  return (
      <div className="space-y-8">
        <div className="flex items-center justify-between">
          <h1 className="text-3xl font-bold text-gray-900">公開テンプレート</h1>
          <a href="/floor_plan_templates" className="text-blue-600 hover:text-blue-800 font-medium">
            ← マイテンプレートへ
          </a>
        </div>

        <section>
          {public_templates.length > 0 ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {public_templates.map((template) => (
                <div
                  key={template.id}
                  className="bg-white rounded-lg shadow hover:shadow-lg transition p-6 border-l-4 border-green-600"
                >
                  <TemplatePreview url={template.preview_image_url} name={template.name} />
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
      </div>
    )
  }
