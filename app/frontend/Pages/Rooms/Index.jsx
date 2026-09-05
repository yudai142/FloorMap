import React, { useState, useMemo } from 'react'
import { usePage } from '@inertiajs/react'
import { Link } from '@inertiajs/react'

export default function RoomsIndex() {
  const { rooms, current_user, auth } = usePage().props
  const [searchQuery, setSearchQuery] = useState('')
  const [sortBy, setSortBy] = useState('created_at')
  const [sortDirection, setSortDirection] = useState('desc')

  // フィルタリング & ソート
  const filteredRooms = useMemo(() => {
    let result = rooms || []

    // 検索フィルタ
    if (searchQuery) {
      const query = searchQuery.toLowerCase()
      result = result.filter(room =>
        room.name.toLowerCase().includes(query) ||
        (room.description && room.description.toLowerCase().includes(query))
      )
    }

    // ソート
    result = result.sort((a, b) => {
      let aVal = a[sortBy]
      let bVal = b[sortBy]

      if (typeof aVal === 'string') {
        aVal = aVal.toLowerCase()
        bVal = bVal.toLowerCase()
      }

      if (aVal < bVal) return sortDirection === 'asc' ? -1 : 1
      if (aVal > bVal) return sortDirection === 'asc' ? 1 : -1
      return 0
    })

    return result
  }, [rooms, searchQuery, sortBy, sortDirection])

  const handleSortChange = (column) => {
    if (sortBy === column) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc')
    } else {
      setSortBy(column)
      setSortDirection('desc')
    }
  }

  return (
    <div className="rooms-page">
      {/* ナビゲーションバー */}
      <nav className="navbar">
        <div className="navbar-content">
          <h1 className="navbar-logo">🗺️ FloorMap</h1>
          <div className="navbar-right">
            <span className="user-email">{current_user?.email}</span>
            <form action="/users/sign_out" method="POST" style={{ display: 'inline' }}>
              <input type="hidden" name="_method" value="DELETE" />
              <input type="hidden" name="authenticity_token" value={document.querySelector('meta[name="csrf-token"]')?.content || ''} />
              <button type="submit" className="btn-logout">ログアウト</button>
            </form>
          </div>
        </div>
      </nav>

      {/* メインコンテンツ */}
      <div className="rooms-container">
        {/* ヘッダー */}
        <div className="rooms-header">
          <div>
            <h2 className="rooms-title">ルーム一覧</h2>
            <p className="rooms-subtitle">座席配置図を管理するルームを選択または作成します</p>
          </div>
          <a href="/rooms/new" className="btn-primary">
            + 新しいルーム
          </a>
        </div>

        {/* 検索 & フィルタ */}
        <div className="search-bar">
          <input
            type="text"
            placeholder="ルーム名または説明で検索..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="search-input"
          />
          <div className="sort-controls">
            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value)}
              className="sort-select"
            >
              <option value="name">ルーム名</option>
              <option value="created_at">作成日</option>
            </select>
            <button
              onClick={() => setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc')}
              className="sort-btn"
              title={sortDirection === 'asc' ? '昇順' : '降順'}
            >
              {sortDirection === 'asc' ? '↑' : '↓'}
            </button>
          </div>
        </div>

        {/* ルーム一覧 */}
        <div className="rooms-grid">
          {filteredRooms.length > 0 ? (
            filteredRooms.map((room) => (
              <a
                key={room.id}
                href={`/rooms/${room.id}`}
                className="room-card"
              >
                <div className="room-card-header">
                  <h3 className="room-name">{room.name}</h3>
                  <span className="room-badge">
                    {room.seats_count || 0} 座席
                  </span>
                </div>
                <p className="room-description">
                  {room.description || '説明なし'}
                </p>
                <div className="room-footer">
                  <span className="room-meta">
                    作成: {new Date(room.created_at).toLocaleDateString('ja-JP')}
                  </span>
                  <span className="room-occupancy">
                    稼働率: {room.occupancy_rate || 0}%
                  </span>
                </div>
              </a>
            ))
          ) : (
            <div className="empty-state">
              <p className="empty-message">
                {searchQuery ? '検索に一致するルームがありません' : 'ルームがまだ作成されていません'}
              </p>
              <a href="/rooms/new" className="btn-primary">
                最初のルームを作成
              </a>
            </div>
          )}
        </div>
      </div>

      <style>{`
        .rooms-page {
          background-color: #f8fafc;
          min-height: 100vh;
        }

        .navbar {
          background-color: white;
          box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
          padding: 0 64px;
        }

        .navbar-content {
          display: flex;
          justify-content: space-between;
          align-items: center;
          height: 64px;
          max-width: 1400px;
          margin: 0 auto;
        }

        .navbar-logo {
          font-size: 24px;
          font-weight: bold;
          color: #2563eb;
          margin: 0;
        }

        .navbar-right {
          display: flex;
          align-items: center;
          gap: 16px;
        }

        .user-email {
          font-size: 14px;
          color: #475569;
        }

        .btn-logout {
          background: none;
          border: none;
          color: #475569;
          text-decoration: none;
          font-weight: 500;
          cursor: pointer;
          transition: color 0.2s;
        }

        .btn-logout:hover {
          color: #0f172a;
        }

        .rooms-container {
          max-width: 1400px;
          margin: 0 auto;
          padding: 32px 64px;
        }

        .rooms-header {
          display: flex;
          justify-content: space-between;
          align-items: flex-start;
          margin-bottom: 32px;
          gap: 16px;
        }

        .rooms-title {
          font-size: 28px;
          font-weight: bold;
          color: #0f172a;
          margin: 0;
        }

        .rooms-subtitle {
          font-size: 14px;
          color: #475569;
          margin: 4px 0 0 0;
        }

        .btn-primary {
          background-color: #3b82f6;
          color: white;
          border: none;
          padding: 10px 20px;
          border-radius: 8px;
          cursor: pointer;
          font-weight: 600;
          text-decoration: none;
          display: inline-flex;
          align-items: center;
          gap: 8px;
          transition: background-color 0.2s;
        }

        .btn-primary:hover {
          background-color: #2563eb;
        }

        .search-bar {
          display: flex;
          gap: 12px;
          margin-bottom: 24px;
          flex-wrap: wrap;
        }

        .search-input {
          flex: 1;
          min-width: 200px;
          padding: 10px 16px;
          border: 1px solid #e2e8f0;
          border-radius: 8px;
          font-size: 14px;
        }

        .search-input:focus {
          outline: none;
          border-color: #3b82f6;
          box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
        }

        .sort-controls {
          display: flex;
          gap: 8px;
        }

        .sort-select {
          padding: 10px 12px;
          border: 1px solid #e2e8f0;
          border-radius: 8px;
          font-size: 14px;
          cursor: pointer;
        }

        .sort-btn {
          padding: 10px 16px;
          border: 1px solid #e2e8f0;
          border-radius: 8px;
          background-color: white;
          cursor: pointer;
          font-weight: 600;
          transition: background-color 0.2s;
        }

        .sort-btn:hover {
          background-color: #f1f5f9;
        }

        .rooms-grid {
          display: grid;
          grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
          gap: 20px;
        }

        .room-card {
          background-color: white;
          border-radius: 12px;
          padding: 20px;
          text-decoration: none;
          color: inherit;
          box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
          transition: all 0.2s;
          display: flex;
          flex-direction: column;
          gap: 12px;
        }

        .room-card:hover {
          box-shadow: 0 10px 24px rgba(0, 0, 0, 0.15);
          transform: translateY(-4px);
        }

        .room-card-header {
          display: flex;
          justify-content: space-between;
          align-items: flex-start;
          gap: 12px;
        }

        .room-name {
          font-size: 18px;
          font-weight: 600;
          color: #0f172a;
          margin: 0;
          flex: 1;
        }

        .room-badge {
          background-color: #dbeafe;
          color: #1e40af;
          padding: 4px 12px;
          border-radius: 20px;
          font-size: 12px;
          font-weight: 600;
          white-space: nowrap;
        }

        .room-description {
          font-size: 14px;
          color: #475569;
          margin: 0;
          line-height: 1.5;
          display: -webkit-box;
          -webkit-line-clamp: 2;
          -webkit-box-orient: vertical;
          overflow: hidden;
        }

        .room-footer {
          display: flex;
          justify-content: space-between;
          align-items: center;
          font-size: 12px;
          color: #64748b;
          margin-top: auto;
          padding-top: 12px;
          border-top: 1px solid #e2e8f0;
        }

        .room-meta,
        .room-occupancy {
          display: flex;
          align-items: center;
          gap: 4px;
        }

        .empty-state {
          grid-column: 1 / -1;
          text-align: center;
          padding: 60px 20px;
        }

        .empty-message {
          font-size: 16px;
          color: #475569;
          margin: 0 0 20px 0;
        }

        @media (max-width: 768px) {
          .rooms-container {
            padding: 20px 16px;
          }

          .rooms-header {
            flex-direction: column;
            align-items: stretch;
          }

          .btn-primary {
            width: 100%;
            justify-content: center;
          }

          .search-bar {
            flex-direction: column;
          }

          .search-input {
            width: 100%;
          }

          .rooms-grid {
            grid-template-columns: 1fr;
          }

          .navbar-content {
            padding: 0 16px;
          }
        }
      `}</style>
    </div>
  )
}
