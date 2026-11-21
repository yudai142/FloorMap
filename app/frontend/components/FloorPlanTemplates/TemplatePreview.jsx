import React from 'react'

export default function TemplatePreview({ url, name }) {
  if (!url) {
    return (
      <div className="w-full h-40 bg-slate-100 rounded mb-4 flex items-center justify-center text-sm text-gray-400">
        プレビューなし
      </div>
    )
  }
  return <img src={url} alt={`${name}の上面図`} className="w-full h-40 object-contain bg-slate-50 rounded mb-4" />
}
