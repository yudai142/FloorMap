import React from 'react'

export default function FloorPlanTemplatesChooseRoom({ template, rooms }) {
  return (
    <div className="space-y-6">
      <div>
        <a href={`/floor_plan_templates/${template.id}`} className="text-sm text-blue-600 hover:text-blue-800">
          ← テンプレートに戻る
        </a>
        <h1 className="text-3xl font-bold text-gray-900 mt-2">読み込むルームを選択</h1>
        <p className="text-gray-600 mt-1">テンプレート「{template.name}」を読み込むルームを選んでください</p>
      </div>

      {rooms.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {rooms.map((room) => (
            <a
              key={room.share_token}
              href={`/rooms/${room.share_token}/canvas_editor?template_id=${template.id}`}
              className="block bg-white rounded-lg shadow hover:shadow-lg transition p-6 border-l-4 border-indigo-600"
            >
              <h3 className="text-xl font-semibold text-gray-900 mb-2">{room.name}</h3>
              <p className="text-sm text-gray-600">座席数: {room.seat_count}</p>
              <p className="text-sm text-gray-500">更新: {room.updated_at}</p>
            </a>
          ))}
        </div>
      ) : (
        <p className="text-gray-500">ルームがありません</p>
      )}
    </div>
  )
}
