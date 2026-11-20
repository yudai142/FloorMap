import React, { useState } from 'react'

export default function FavoriteButton({ templateId, initialFavorited, onChange }) {
  const [favorited, setFavorited] = useState(Boolean(initialFavorited))
  const [busy, setBusy] = useState(false)

  const toggle = async () => {
    setBusy(true)
    try {
      const response = await fetch(`/floor_plan_templates/${templateId}/favorite`, {
        method: favorited ? 'DELETE' : 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content || '',
          Accept: 'application/json',
        },
      })
      if (response.ok) {
        setFavorited(!favorited)
        onChange?.(templateId, !favorited)
      }
    } finally {
      setBusy(false)
    }
  }

  return (
    <button
      type="button"
      onClick={toggle}
      disabled={busy}
      aria-pressed={favorited}
      className={`px-3 py-2 rounded text-sm font-medium border transition disabled:opacity-60 ${
        favorited
          ? 'bg-amber-100 border-amber-400 text-amber-800 hover:bg-amber-200'
          : 'bg-white border-slate-300 text-slate-700 hover:bg-slate-50'
      }`}
    >
      {favorited ? '★ お気に入り済み' : '☆ お気に入りに追加'}
    </button>
  )
}
