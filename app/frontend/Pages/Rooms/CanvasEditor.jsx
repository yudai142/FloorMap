import React from 'react'
import CanvasEditorPage from '../../components/Editor/CanvasEditorPage'

export default function CanvasEditor({ room, shapes_data, seats, current_user }) {
  return (
    <CanvasEditorPage
      entity={room}
      backHref={`/rooms/${room.share_token}`}
      shapes={shapes_data}
      seats={seats}
      currentUser={current_user}
      persistence={{
        floorPlanUrl: `/rooms/${room.share_token}/floor_plan.json`,
        floorPlanBodyKey: 'room',
        settingsUrl: `/rooms/${room.share_token}`,
        seatsUrl: `/rooms/${room.share_token}/seats`,
        saveMessage: '座席配置図を保存しました',
      }}
    />
  )
}
