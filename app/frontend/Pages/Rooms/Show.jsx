import React, { useState, useEffect } from 'react'
import { usePage } from '@inertiajs/react'

export default function RoomShow() {
  const { room, seats, current_user, current_session, auth } = usePage().props
  const [sessions, setSessions] = useState([])
  const [autoCheckoutEnabled, setAutoCheckoutEnabled] = useState(false)
  const [autoCheckoutTime, setAutoCheckoutTime] = useState('')

  // データロード
  const fetchSessions = async () => {
    try {
      const response = await fetch(`/rooms/${room.share_token}/canvas_data.json`)
      if (!response.ok) {
        return
      }
      const data = await response.json()
      setSessions(data.sessions || [])
    } catch (error) {
      // Silent fail
    }
  }

  useEffect(() => {
    fetchSessions()
    // 3秒ごとにセッション情報を更新
    const interval = setInterval(fetchSessions, 3000)
    return () => clearInterval(interval)
  }, [room.id])

  // 初期化時に props から設定を復元
  useEffect(() => {
    if (current_session) {
      setAutoCheckoutEnabled(current_session.user_auto_checkout_enabled || false)
      if (current_session.user_auto_checkout_time) {
        // ISO形式に変換
        const dateTime = new Date(current_session.user_auto_checkout_time)
        const isoString = dateTime.toISOString().slice(0, 16)
        setAutoCheckoutTime(isoString)
      }
    }
  }, [current_session])

  // チェックボックスの状態が変わったら即座に保存
  const handleCheckboxChange = async (checked) => {
    setAutoCheckoutEnabled(checked)
    try {
      const response = await fetch(`/rooms/${room.share_token}/update_auto_checkout_settings`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content,
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          auto_checkout_settings: {
            auto_checkout_enabled: checked,
            auto_checkout_time: autoCheckoutTime || null
          }
        })
      })

      if (!response.ok) {
        const error = await response.json()
        console.error('Failed to save auto checkout enabled setting:', error)
        const errorMsg = error.errors ? error.errors.join(', ') : error.message
        alert(`エラー: ${errorMsg}`)
        setAutoCheckoutEnabled(!checked)
      }
    } catch (error) {
      console.error('Failed to save auto checkout enabled setting:', error)
      setAutoCheckoutEnabled(!checked)
    }
  }

  // 確定ボタンで日時を保存
  const handleSaveCheckoutTime = async () => {
    try {
      const response = await fetch(`/rooms/${room.share_token}/update_auto_checkout_settings`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content,
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          auto_checkout_settings: {
            auto_checkout_enabled: autoCheckoutEnabled,
            auto_checkout_time: autoCheckoutTime
          }
        })
      })

      if (response.ok) {
        alert('離席日時を保存しました')
      } else {
        alert('離席日時の保存に失敗しました')
      }
    } catch (error) {
      console.error('Failed to save auto checkout time:', error)
      alert('離席日時の保存に失敗しました')
    }
  }

  const handleCheckIn = async (seatId) => {
    try {
      let checkoutTimer = 60

      // 自動離席が有効な場合、日時から分数を計算
      if (autoCheckoutEnabled && autoCheckoutTime) {
        const checkoutTime = new Date(autoCheckoutTime)
        const now = new Date()
        checkoutTimer = Math.round((checkoutTime - now) / 60000) // 分に変換

        if (checkoutTimer <= 0) {
          alert('離席日時は現在時刻より後に設定してください')
          return
        }
      }

      const response = await fetch('/sessions/check_in.json', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content,
          'Accept': 'application/json'
        },
        body: JSON.stringify({ seat_id: seatId, checkout_timer_minutes: checkoutTimer })
      })

      if (response.ok) {
        await fetchSessions()
        if (autoCheckoutEnabled && autoCheckoutTime) {
          const timeStr = new Date(autoCheckoutTime).toLocaleString('ja-JP')
          alert(`${timeStr} に自動離席します`)
        }
      } else {
        const error = await response.json()
        alert(error.message || 'チェックインに失敗しました')
      }
    } catch (error) {
      console.error('チェックインエラー:', error)
      alert('チェックインに失敗しました')
    }
  }

  const handleCheckOut = async (sessionId) => {
    try {
      const response = await fetch(`/sessions/check_out.json?session_id=${sessionId}`, {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content,
          'Accept': 'application/json'
        }
      })

      if (response.ok) {
        await fetchSessions()
      } else {
        alert('チェックアウトに失敗しました')
      }
    } catch (error) {
      console.error('チェックアウトエラー:', error)
      alert('チェックアウトに失敗しました')
    }
  }

  const canManage = current_user && (current_user.id === room.user_id || current_user.role === 'admin')

  return (
    <div className="room-detail-page">
      {/* ナビゲーション */}
      <div className="navbar-header">
        <a href="/rooms" className="back-link">← ルーム一覧に戻る</a>
        <h1 className="room-title">{room.name}</h1>
        {canManage && (
          <div className="action-buttons">
            <a href={`/rooms/${room.share_token}/canvas_editor`} className="btn-primary">
              座席配置図を編集
            </a>
          </div>
        )}
      </div>

      <div className="room-container">
        {/* 左パネル：座席配置図 */}
        <div className="left-panel">
          <div className="panel-header">
            <h2>座席配置図</h2>
            <div className="legend">
              <span className="legend-item">
                <span className="dot occupied"></span> 使用中 ({room.occupied_count || 0})
              </span>
              <span className="legend-item">
                <span className="dot available"></span> 空き ({(room.seats_count || 0) - (room.occupied_count || 0)})
              </span>
              <span className="occupancy">稼働率: {room.occupancy_rate || 0}%</span>
            </div>
          </div>

          <svg
            id="room-canvas"
            className="room-canvas"
            width={room.width || 1000}
            height={room.height || 700}
            style={{ border: '1px solid #e2e8f0', backgroundColor: 'white' }}
          >
            {/* グリッド背景 */}
            <defs>
              <pattern id="smallGrid" width="10" height="10" patternUnits="userSpaceOnUse">
                <path d="M 10 0 L 0 0 0 10" fill="none" stroke="#e2e8f0" strokeWidth="0.5" />
              </pattern>
            </defs>
            <rect width={room.width || 1000} height={room.height || 700} fill="url(#smallGrid)" />

            {/* 上面図（図形） */}
            {room.floor_plan_data && room.floor_plan_data.map((shape, idx) => {
              if (shape.type === 'rectangle') {
                return (
                  <rect
                    key={`shape-${idx}`}
                    x={shape.x}
                    y={shape.y}
                    width={shape.width}
                    height={shape.height}
                    fill={shape.fill || 'none'}
                    stroke={shape.color || '#64748b'}
                    strokeWidth={shape.lineWidth || 2}
                  />
                )
              } else if (shape.type === 'line') {
                return (
                  <line
                    key={`shape-${idx}`}
                    x1={shape.x1}
                    y1={shape.y1}
                    x2={shape.x2}
                    y2={shape.y2}
                    stroke={shape.color || '#64748b'}
                    strokeWidth={shape.lineWidth || 2}
                  />
                )
              } else if (shape.type === 'circle') {
                return (
                  <circle
                    key={`shape-${idx}`}
                    cx={shape.cx}
                    cy={shape.cy}
                    r={shape.r}
                    fill={shape.fill || 'none'}
                    stroke={shape.color || '#64748b'}
                    strokeWidth={shape.lineWidth || 2}
                  />
                )
              } else if (shape.type === 'arrow') {
                const headlen = 15
                const angle = Math.atan2(shape.y2 - shape.y1, shape.x2 - shape.x1)
                const color = shape.color || '#64748b'
                return (
                  <g key={`shape-${idx}`}>
                    <line
                      x1={shape.x1}
                      y1={shape.y1}
                      x2={shape.x2}
                      y2={shape.y2}
                      stroke={color}
                      strokeWidth={shape.lineWidth || 2}
                    />
                    <polygon
                      points={`${shape.x2},${shape.y2} ${shape.x2 - headlen * Math.cos(angle - Math.PI / 6)},${shape.y2 - headlen * Math.sin(angle - Math.PI / 6)} ${shape.x2 - headlen * Math.cos(angle + Math.PI / 6)},${shape.y2 - headlen * Math.sin(angle + Math.PI / 6)}`}
                      fill={color}
                    />
                  </g>
                )
              } else if (shape.type === 'text') {
                return (
                  <text
                    key={`shape-${idx}`}
                    x={shape.x}
                    y={shape.y}
                    fontSize="14"
                    fill={shape.color || '#1e293b'}
                  >
                    {shape.text}
                  </text>
                )
              } else if (shape.type === 'polygon') {
                return (
                  <polygon
                    key={`shape-${idx}`}
                    points={shape.points}
                    fill={shape.fill || 'none'}
                    stroke={shape.color || '#06b6d4'}
                    strokeWidth={shape.lineWidth || 2}
                  />
                )
              }
              return null
            })}

            {/* 座席 */}
            {seats && seats.map((seat) => {
              const session = sessions.find(s => s.seat_id === seat.id && s.status === 'active')
              const isOccupied = seat.occupied || !!session
              return (
                <g key={`seat-${seat.id}`} transform={`translate(${seat.x}, ${seat.y})`}>
                  <circle
                    r="12"
                    fill={isOccupied ? '#f87171' : '#4ade80'}
                    stroke="#065f46"
                    strokeWidth="2"
                    style={{ cursor: 'pointer' }}
                    onClick={() => session ? handleCheckOut(session.id) : handleCheckIn(seat.id)}
                  />
                  <text
                    x="16"
                    y="4"
                    fontSize="12"
                    fill="#000"
                    fontWeight="bold"
                    style={{ pointerEvents: 'none' }}
                  >
                    {seat.label}
                  </text>
                </g>
              )
            })}
          </svg>
        </div>

        {/* 右パネル：座席一覧 */}
        <div className="right-panel">
          {/* 自動離席設定パネル - 着席中のみ表示 */}
          {current_session && (
          <div className="auto-checkout-panel">
            <div className="panel-header">
              <h3>自動離席設定</h3>
            </div>
            <div className="auto-checkout-content">
              <label className="auto-checkout-checkbox">
                <input
                  type="checkbox"
                  checked={autoCheckoutEnabled}
                  onChange={(e) => handleCheckboxChange(e.target.checked)}
                />
                <span>自動離席を有効にする</span>
              </label>
              {autoCheckoutEnabled && (
                <div className="auto-checkout-input-group">
                  <label htmlFor="checkout-time">離席日時:</label>
                  <input
                    id="checkout-time"
                    type="datetime-local"
                    value={autoCheckoutTime}
                    onChange={(e) => setAutoCheckoutTime(e.target.value)}
                  />
                  <button
                    onClick={handleSaveCheckoutTime}
                    className="btn-confirm-checkout"
                  >
                    確定
                  </button>
                </div>
              )}
            </div>
          </div>
          )}

          <div className="panel-header">
            <h2>座席ステータス一覧</h2>
          </div>

          <div className="seats-table-container">
            {seats && seats.length > 0 ? (
              <div className="seats-grid">
                {seats.map((seat) => {
                  const session = sessions.find(s => s.seat_id === seat.id && s.status === 'active')
                  return (
                    <div key={seat.id} className="seat-item">
                      <div className="seat-info">
                        <span className={`seat-status ${session ? 'occupied' : 'available'}`}>
                          {seat.seat_identifier}
                        </span>
                        {session && (
                          <span className="occupant-name">
                            {session.user?.username || session.visitor?.display_name || '不明'}
                          </span>
                        )}
                      </div>

                      {session ? (
                        <button
                          onClick={() => handleCheckOut(session.id)}
                          className="btn-checkout"
                          disabled={
                            current_user &&
                            current_user.id !== session.user_id &&
                            current_user.role !== 'admin'
                          }
                        >
                          離席
                        </button>
                      ) : (
                        <button
                          onClick={() => handleCheckIn(seat.id)}
                          className="btn-checkin"
                        >
                          着席
                        </button>
                      )}
                    </div>
                  )
                })}
              </div>
            ) : (
              <div className="empty-state">
                <p>座席が登録されていません</p>
              </div>
            )}
          </div>
        </div>
      </div>

      <style>{`
        .room-detail-page {
          background-color: #f8fafc;
          min-height: 100vh;
        }

        .navbar-header {
          background-color: white;
          border-bottom: 1px solid #e2e8f0;
          padding: 16px 64px;
          display: flex;
          align-items: center;
          gap: 24px;
        }

        .back-link {
          color: #3b82f6;
          text-decoration: none;
          font-weight: 500;
          white-space: nowrap;
        }

        .back-link:hover {
          color: #2563eb;
        }

        .room-title {
          font-size: 24px;
          font-weight: bold;
          color: #0f172a;
          margin: 0;
          flex: 1;
        }

        .action-buttons {
          display: flex;
          gap: 12px;
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
          display: inline-block;
          transition: background-color 0.2s;
        }

        .btn-primary:hover {
          background-color: #2563eb;
        }

        .room-container {
          display: grid;
          grid-template-columns: 1fr 400px;
          gap: 24px;
          max-width: 1600px;
          margin: 0 auto;
          padding: 32px 64px;
        }

        .left-panel,
        .right-panel {
          background-color: white;
          border-radius: 12px;
          padding: 20px;
          box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        }

        .panel-header {
          margin-bottom: 20px;
          padding-bottom: 16px;
          border-bottom: 1px solid #e2e8f0;
        }

        .panel-header h2 {
          font-size: 18px;
          font-weight: 600;
          color: #0f172a;
          margin: 0 0 12px 0;
        }

        .legend {
          display: flex;
          gap: 16px;
          font-size: 14px;
          color: #475569;
          flex-wrap: wrap;
        }

        .legend-item {
          display: flex;
          align-items: center;
          gap: 6px;
        }

        .dot {
          display: inline-block;
          width: 12px;
          height: 12px;
          border-radius: 50%;
        }

        .dot.occupied {
          background-color: #ef4444;
        }

        .dot.available {
          background-color: #4ade80;
        }

        .occupancy {
          font-weight: 600;
          color: #0f172a;
        }

        .room-canvas {
          width: 100%;
          height: auto;
          border: 1px solid #e2e8f0;
          border-radius: 8px;
          background-color: #fafbfc;
        }

        .seats-table-container {
          max-height: 600px;
          overflow-y: auto;
        }

        .seats-grid {
          display: grid;
          grid-template-columns: 1fr;
          gap: 12px;
        }

        .seat-item {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding: 12px;
          border: 1px solid #e2e8f0;
          border-radius: 8px;
          background-color: #f8fafc;
        }

        .seat-info {
          display: flex;
          flex-direction: column;
          gap: 4px;
        }

        .seat-status {
          font-weight: 600;
          font-size: 14px;
        }

        .seat-status.occupied {
          color: #ef4444;
        }

        .seat-status.available {
          color: #4ade80;
        }

        .occupant-name {
          font-size: 12px;
          color: #64748b;
        }

        .btn-checkin,
        .btn-checkout {
          padding: 6px 12px;
          border: none;
          border-radius: 6px;
          cursor: pointer;
          font-size: 12px;
          font-weight: 600;
          transition: all 0.2s;
        }

        .btn-checkin {
          background-color: #4ade80;
          color: white;
        }

        .btn-checkin:hover {
          background-color: #22c55e;
        }

        .btn-checkout {
          background-color: #ef4444;
          color: white;
        }

        .btn-checkout:hover {
          background-color: #dc2626;
        }

        .btn-checkout:disabled {
          background-color: #cbd5e1;
          cursor: not-allowed;
        }

        .empty-state {
          text-align: center;
          padding: 40px 20px;
          color: #64748b;
        }

        .auto-checkout-panel {
          background-color: #f0fdf4;
          border: 1px solid #bbf7d0;
          border-radius: 8px;
          padding: 16px;
          margin-bottom: 20px;
        }

        .auto-checkout-panel .panel-header {
          margin-bottom: 12px;
          padding-bottom: 8px;
          border-bottom: 1px solid #bbf7d0;
        }

        .auto-checkout-panel h3 {
          margin: 0;
          font-size: 16px;
          font-weight: 600;
          color: #166534;
        }

        .auto-checkout-content {
          display: flex;
          flex-direction: column;
          gap: 12px;
        }

        .auto-checkout-checkbox {
          display: flex;
          align-items: center;
          gap: 8px;
          cursor: pointer;
          font-size: 14px;
          color: #166534;
        }

        .auto-checkout-checkbox input[type="checkbox"] {
          width: 18px;
          height: 18px;
          cursor: pointer;
          accent-color: #22c55e;
        }

        .auto-checkout-input-group {
          display: flex;
          flex-direction: column;
          gap: 6px;
        }

        .auto-checkout-input-group label {
          font-size: 12px;
          font-weight: 600;
          color: #166534;
        }

        .auto-checkout-input-group input[type="datetime-local"] {
          padding: 8px 12px;
          border: 1px solid #bbf7d0;
          border-radius: 6px;
          font-size: 14px;
          color: #166534;
        }

        .auto-checkout-input-group input[type="datetime-local"]:focus {
          outline: none;
          border-color: #22c55e;
          box-shadow: 0 0 0 3px rgba(34, 197, 94, 0.1);
        }

        .btn-confirm-checkout {
          padding: 8px 16px;
          background-color: #22c55e;
          color: white;
          border: none;
          border-radius: 6px;
          font-size: 14px;
          font-weight: 600;
          cursor: pointer;
          transition: background-color 0.2s;
          margin-top: 4px;
        }

        .btn-confirm-checkout:hover {
          background-color: #16a34a;
        }

        .btn-confirm-checkout:active {
          background-color: #15803d;
        }

        @media (max-width: 1024px) {
          .room-container {
            grid-template-columns: 1fr;
            padding: 20px 16px;
          }

          .navbar-header {
            padding: 16px;
            flex-direction: column;
            align-items: flex-start;
          }

          .right-panel {
            order: -1;
          }
        }
      `}</style>
    </div>
  )
}
