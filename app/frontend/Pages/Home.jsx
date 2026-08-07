import React from 'react'

export default function Home({ auth }) {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
      <div className="max-w-2xl w-full bg-white rounded-lg shadow-xl p-8">
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-gray-900 mb-2">FloorMap</h1>
          <p className="text-xl text-gray-600">オフィス・施設の座席配置管理アプリケーション</p>
        </div>

        <div className="bg-gradient-to-r from-blue-50 to-indigo-50 rounded-lg p-6 mb-8">
          <h2 className="text-lg font-semibold text-gray-900 mb-3">主な機能</h2>
          <ul className="space-y-2 text-gray-700">
            <li className="flex items-center">
              <span className="inline-block w-2 h-2 bg-blue-500 rounded-full mr-3"></span>
              座席・ルームの配置図をWebで管理・共有
            </li>
            <li className="flex items-center">
              <span className="inline-block w-2 h-2 bg-blue-500 rounded-full mr-3"></span>
              ユーザーの着席・離席リアルタイム同期
            </li>
            <li className="flex items-center">
              <span className="inline-block w-2 h-2 bg-blue-500 rounded-full mr-3"></span>
              QRコードによるセルフチェックイン
            </li>
            <li className="flex items-center">
              <span className="inline-block w-2 h-2 bg-blue-500 rounded-full mr-3"></span>
              分析ダッシュボード（座席利用率・滞在時間など）
            </li>
          </ul>
        </div>

        {auth?.is_authenticated ? (
          <div className="space-y-4">
            <div className="bg-green-50 border border-green-200 rounded p-4 text-center">
              <p className="text-green-800">
                ログイン中: <span className="font-semibold">{auth.user?.email}</span>
              </p>
            </div>
            <button className="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 rounded-lg transition">
              ダッシュボードへ
            </button>
          </div>
        ) : (
          <div className="space-y-3">
            <a
              href="/users/sign_in"
              className="block bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 px-6 rounded-lg text-center transition"
            >
              ログイン
            </a>
            <a
              href="/users/sign_up"
              className="block bg-gray-200 hover:bg-gray-300 text-gray-900 font-semibold py-3 px-6 rounded-lg text-center transition"
            >
              アカウント作成
            </a>
          </div>
        )}

        <div className="mt-8 pt-8 border-t border-gray-200 text-center text-sm text-gray-600">
          <p>React + Vite + Tailwind CSS + Inertia.js で構築</p>
        </div>
      </div>
    </div>
  )
}
