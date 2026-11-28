import React from 'react'

export function PageSizeSelect({ id, value, onChange, options = [6, 9, 12] }) {
  return (
    <div className="flex items-center gap-2 text-sm text-slate-600">
      <label htmlFor={id}>1ページの表示数</label>
      <select
        id={id}
        value={value}
        onChange={(e) => onChange(Number(e.target.value))}
        className="px-2 py-1 border border-slate-300 rounded"
      >
        {options.map((count) => (
          <option key={count} value={count}>
            {count}件
          </option>
        ))}
      </select>
    </div>
  )
}

export default function Pagination({ page, pageCount, onChange }) {
  if (pageCount <= 1) return null

  return (
    <nav className="flex items-center justify-center gap-2 mt-6" aria-label="ページ">
      <button
        type="button"
        onClick={() => onChange(Math.max(1, page - 1))}
        disabled={page === 1}
        className="px-3 py-1 border border-slate-300 rounded text-sm disabled:text-slate-300"
      >
        前へ
      </button>
      {Array.from({ length: pageCount }, (_, index) => index + 1).map((number) => (
        <button
          key={number}
          type="button"
          onClick={() => onChange(number)}
          aria-current={number === page ? 'page' : undefined}
          className={`px-3 py-1 rounded text-sm ${
            number === page ? 'bg-indigo-600 text-white' : 'border border-slate-300 hover:bg-slate-100'
          }`}
        >
          {number}
        </button>
      ))}
      <button
        type="button"
        onClick={() => onChange(Math.min(pageCount, page + 1))}
        disabled={page === pageCount}
        className="px-3 py-1 border border-slate-300 rounded text-sm disabled:text-slate-300"
      >
        次へ
      </button>
    </nav>
  )
}
