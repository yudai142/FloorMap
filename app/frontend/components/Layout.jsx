import React, { useEffect, useState } from 'react'

export default function Layout({ children, auth = {} }) {
  const [csrfToken, setCsrfToken] = useState('')

  useEffect(() => {
    const token = document.querySelector('meta[name="csrf-token"]')?.content || ''
    setCsrfToken(token)
  }, [])

  const handleLogout = (e) => {
    e.preventDefault()
    if (confirm('ログアウトしてもよろしいですか？')) {
      const form = document.createElement('form')
      form.method = 'POST'
      form.action = '/users/sign_out'

      const methodInput = document.createElement('input')
      methodInput.type = 'hidden'
      methodInput.name = '_method'
      methodInput.value = 'DELETE'
      form.appendChild(methodInput)

      if (csrfToken) {
        const tokenInput = document.createElement('input')
        tokenInput.type = 'hidden'
        tokenInput.name = 'authenticity_token'
        tokenInput.value = csrfToken
        form.appendChild(tokenInput)
      }

      document.body.appendChild(form)
      form.submit()
    }
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* ヘッダー */}
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex justify-between items-center">
          <h1 className="text-2xl font-bold text-blue-600">🗺️ FloorMap</h1>
          <div className="flex items-center space-x-4">
            {auth?.is_authenticated ? (
              <>
                <span className="text-gray-700 font-medium">{auth.user?.username || auth.user?.email}</span>
                <a
                  href="/users/edit"
                  className="px-3 py-2 bg-blue-600 text-white text-sm rounded hover:bg-blue-700 transition"
                >
                  名前変更
                </a>
                <button
                  onClick={handleLogout}
                  className="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700 transition"
                >
                  ログアウト
                </button>
              </>
            ) : (
              <>
                <a href="/users/sign_in" className="text-gray-700 hover:text-gray-900">
                  ログイン
                </a>
                <a href="/users/sign_up" className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">
                  サインアップ
                </a>
              </>
            )}
          </div>
        </div>
      </header>

      {/* メインコンテンツ */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {children}
      </main>
    </div>
  )
}
