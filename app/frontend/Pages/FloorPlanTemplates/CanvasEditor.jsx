import React from 'react'
import CanvasEditorPage from '../../components/Editor/CanvasEditorPage'

export default function FloorPlanTemplatesCanvasEditor({ template, shapes_data, seats, current_user }) {
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
      showAutoCheckout={false}
      shapes={shapes_data}
      seats={seats}
      currentUser={current_user}
      persistence={{
        floorPlanUrl: `/floor_plan_templates/${template.id}/canvas_editor`,
        floorPlanBodyKey: 'floor_plan_template',
        settingsUrl: null,
        seatsUrl: `/floor_plan_templates/${template.id}/seats`,
        previewUrl: `/floor_plan_templates/${template.id}/preview`,
        generatePreviewOnLoad: !template.preview_image_url,
        saveMessage: '座席配置図を保存しました',
      }}
    />
  )
}
