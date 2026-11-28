import React from 'react'

const TABS = [
  { key: 'mine', label: 'マイテンプレート', href: '/floor_plan_templates' },
  { key: 'public', label: '公開テンプレート', href: '/floor_plan_templates/public' },
  { key: 'favorites', label: 'お気に入り', href: '/floor_plan_templates/favorites' },
]

export default function TemplateTabs({ active }) {
  return (
    <nav className="flex gap-6 border-b border-slate-200" aria-label="テンプレートの切り替え">
      {TABS.map((tab) => {
        const isActive = tab.key === active
        return (
          <a
            key={tab.key}
            href={tab.href}
            aria-current={isActive ? 'page' : undefined}
            className={`-mb-px border-b-2 px-1 pb-3 text-base font-semibold transition ${
              isActive
                ? 'border-indigo-600 text-indigo-700'
                : 'border-transparent text-slate-500 hover:text-slate-800 hover:border-slate-300'
            }`}
          >
            {tab.label}
          </a>
        )
      })}
    </nav>
  )
}
