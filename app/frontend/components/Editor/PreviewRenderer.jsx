import React from 'react'

export default function PreviewRenderer({ preview }) {
  if (!preview) return null

  const previewStyle = {
    stroke: '#cbd5e1',
    strokeWidth: 2,
    strokeDasharray: '5,5',
    fill: 'rgba(203, 213, 225, 0.1)',
  }

  if (preview.type === 'line') {
    return (
      <line
        x1={preview.x1}
        y1={preview.y1}
        x2={preview.x2}
        y2={preview.y2}
        stroke={previewStyle.stroke}
        strokeWidth={previewStyle.strokeWidth}
        strokeDasharray={previewStyle.strokeDasharray}
        pointerEvents="none"
      />
    )
  } else if (preview.type === 'rectangle') {
    return (
      <rect
        x={preview.x}
        y={preview.y}
        width={preview.width}
        height={preview.height}
        fill={previewStyle.fill}
        stroke={previewStyle.stroke}
        strokeWidth={previewStyle.strokeWidth}
        strokeDasharray={previewStyle.strokeDasharray}
        pointerEvents="none"
      />
    )
  } else if (preview.type === 'circle') {
    return (
      <circle
        cx={preview.cx}
        cy={preview.cy}
        r={preview.r}
        fill={previewStyle.fill}
        stroke={previewStyle.stroke}
        strokeWidth={previewStyle.strokeWidth}
        strokeDasharray={previewStyle.strokeDasharray}
        pointerEvents="none"
      />
    )
  } else if (preview.type === 'arrow') {
    return (
      <line
        x1={preview.x1}
        y1={preview.y1}
        x2={preview.x2}
        y2={preview.y2}
        stroke={previewStyle.stroke}
        strokeWidth={previewStyle.strokeWidth}
        strokeDasharray={previewStyle.strokeDasharray}
        pointerEvents="none"
      />
    )
  }

  return null
}
