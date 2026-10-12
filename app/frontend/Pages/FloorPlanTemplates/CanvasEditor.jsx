import React from 'react'
import CanvasEditorPage from '../../components/Editor/CanvasEditorPage'

export default function FloorPlanTemplatesCanvasEditor({ template, shapes_data, current_user }) {
  return (
    <CanvasEditorPage
      entity={{
        id: template.id,
        name: template.name,
        width: 1000,
        height: 700,
        auto_checkout_enabled: false,
        auto_checkout_time: '',
      }}
      backHref="/floor_plan_templates"
      shapes={shapes_data}
      seats={[]}
      currentUser={current_user}
      persistence={{
        floorPlanUrl: `/floor_plan_templates/${template.id}/canvas_editor`,
        floorPlanBodyKey: 'floor_plan_template',
        settingsUrl: null,
        seatsUrl: null,
        saveMessage: '上面図を保存しました',
      }}
    />
  )
}
