import React from 'react'

export default function Home({ auth }) {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      {/* メインコンテンツ */}
      <div className="max-w-4xl mx-auto px-4 py-12">
        {/* ヒーローセクション */}
        <div className="text-center mb-12">
          <h1 className="text-5xl font-bold text-gray-900 mb-4">🗺️ FloorMap</h1>
          <p className="text-xl text-gray-700 mb-3">
            「今どこにいるの？」が一目瞭然。<br />
            勉強会・もくもく会・グループ集まりの座席管理がカンタンに
          </p>
          <p className="text-sm text-gray-600">
            スマホでURLを開くだけで、全員の席がリアルタイムで共有できます
          </p>
        </div>

        {/* デモリンク */}
        <div className="bg-white rounded-lg shadow-lg p-8 mb-12">
          <div className="text-center">
            <p className="text-sm text-gray-600 mb-2">実際に試してみる</p>
            <a
              href="https://floormap.onrender.com/rooms/d80d848c8b6f"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-block bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-2 px-6 rounded-lg transition"
            >
              デモページを見る →
            </a>
          </div>
        </div>

        {/* こんな場面で使えます */}
        <div className="bg-white rounded-lg shadow-lg p-8 mb-12">
          <h2 className="text-2xl font-bold text-gray-900 mb-6">こんな時に活躍します</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="border-l-4 border-blue-500 pl-4">
              <h3 className="font-semibold text-gray-900 mb-2">📚 勉強会・セミナー</h3>
              <p className="text-gray-700 text-sm">
                参加者が入室する前に、みんなの席がわかる。Slackで「どこ？」と聞く手間が無くなります
              </p>
            </div>
            <div className="border-l-4 border-blue-500 pl-4">
              <h3 className="font-semibold text-gray-900 mb-2">👥 もくもく会・サークル</h3>
              <p className="text-gray-700 text-sm">
                毎回同じカフェやコワーキングスペースを使う集まりも、席をすぐ登録・共有できます
              </p>
            </div>
            <div className="border-l-4 border-blue-500 pl-4">
              <h3 className="font-semibold text-gray-900 mb-2">🤝 社内・チーム集まり</h3>
              <p className="text-gray-700 text-sm">
                会議室や共用スペースの利用状況をビジュアルで共有。誰がどこにいるかすぐわかります
              </p>
            </div>
          </div>
        </div>

        {/* 主な機能 */}
        <div className="bg-gradient-to-r from-blue-50 to-indigo-50 rounded-lg p-8 mb-12">
          <h2 className="text-2xl font-bold text-gray-900 mb-6">FloorMap でできること</h2>
          <ul className="space-y-3">
            <li className="flex items-start">
              <span className="inline-block w-6 h-6 bg-blue-500 text-white rounded-full mr-4 flex items-center justify-center flex-shrink-0 mt-0.5">✓</span>
              <div>
                <p className="font-semibold text-gray-900">座席配置図をWebで作成・管理</p>
                <p className="text-gray-700 text-sm">カフェ、会議室、イベント会場...どんなスペースでも描画できます。壁や柱を線で描き、座席を配置するだけ</p>
              </div>
            </li>
            <li className="flex items-start">
              <span className="inline-block w-6 h-6 bg-blue-500 text-white rounded-full mr-4 flex items-center justify-center flex-shrink-0 mt-0.5">✓</span>
              <div>
                <p className="font-semibold text-gray-900">URLで簡単共有</p>
                <p className="text-gray-700 text-sm">作った配置図のURLをコピーして、メール・Slack・LINEで送信。受け取った人がURLを開くだけで、全員の席がリアルタイムで見えます</p>
              </div>
            </li>
            <li className="flex items-start">
              <span className="inline-block w-6 h-6 bg-blue-500 text-white rounded-full mr-4 flex items-center justify-center flex-shrink-0 mt-0.5">✓</span>
              <div>
                <p className="font-semibold text-gray-900">ワンクリック着席・離席</p>
                <p className="text-gray-700 text-sm">座席をタップして名前を入力するだけで着席。移動したい時・帰る時は再度タップで離席。複数人の状態がリアルタイム同期されます</p>
              </div>
            </li>
            <li className="flex items-start">
              <span className="inline-block w-6 h-6 bg-blue-500 text-white rounded-full mr-4 flex items-center justify-center flex-shrink-0 mt-0.5">✓</span>
              <div>
                <p className="font-semibold text-gray-900">モバイル対応</p>
                <p className="text-gray-700 text-sm">アプリのインストール不要。スマホ・タブレットからそのままブラウザでアクセス。入室前にどこに誰がいるかサッと確認できます</p>
              </div>
            </li>
          </ul>
        </div>

        {/* 使い始める */}
        <div className="bg-white rounded-lg shadow-lg p-8">
          <h2 className="text-2xl font-bold text-gray-900 mb-6 text-center">さあ、始めましょう</h2>

          {auth?.is_authenticated ? (
            <div className="space-y-4">
              <div className="bg-green-50 border border-green-200 rounded-lg p-4 text-center">
                <p className="text-green-800">
                  <span className="font-semibold">{auth.user?.username || auth.user?.email}</span>
                  でログイン中です
                </p>
              </div>
              <a
                href="/rooms"
                className="block bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 px-6 rounded-lg text-center transition"
              >
                ルーム管理へ →
              </a>
            </div>
          ) : (
            <div className="max-w-sm mx-auto space-y-3">
              <p className="text-center text-gray-700 mb-4">
                アカウントを作成して、自分のスペースの配置図を作りましょう
              </p>
              <a
                href="/users/sign_up"
                className="block bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 px-6 rounded-lg text-center transition"
              >
                アカウント作成（無料）
              </a>
              <a
                href="/users/sign_in"
                className="block bg-gray-200 hover:bg-gray-300 text-gray-900 font-semibold py-3 px-6 rounded-lg text-center transition"
              >
                ログイン
              </a>
            </div>
          )}
        </div>

        {/* フッター */}
        <div className="mt-12 pt-8 border-t border-gray-300 text-center text-sm text-gray-600">
          <p>シンプルで使いやすい。インストール不要。すぐに始められます。</p>
        </div>
      </div>
    </div>
  )
}
