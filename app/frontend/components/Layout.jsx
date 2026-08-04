import React from 'react'

export default function Layout({ children, auth }) {
  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex items-center">
              <h1 className="text-2xl font-bold text-blue-600">FloorMap</h1>
            </div>

            <div className="flex items-center space-x-4">
              {auth?.is_authenticated ? (
                <div className="flex items-center space-x-4">
                  <span className="text-sm text-gray-700">{auth.user?.email}</span>
                  <a href="/users/sign_out" className="text-gray-700 hover:text-gray-900">
                    ログアウト
                  </a>
                </div>
              ) : (
                <div className="flex items-center space-x-4">
                  <a href="/users/sign_in" className="text-gray-700 hover:text-gray-900">
                    ログイン
                  </a>
                  <a href="/users/sign_up" className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700">
                    サインアップ
                  </a>
                </div>
              )}
            </div>
          </div>
        </div>
      </nav>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {children}
      </main>
    </div>
  )
}
