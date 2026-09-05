import React from 'react'

export default function ShapeRenderer({ shape, isSelected }) {
  const selectedStyle = isSelected
    ? {
        stroke: '#06b6d4',
        strokeWidth: 2,
        strokeDasharray: '4,4',
        fill: 'rgba(6, 182, 212, 0.1)',
      }
    : {}

  if (shape.type === 'line') {
    return (
      <line
        x1={shape.x1}
        y1={shape.y1}
        x2={shape.x2}
        y2={shape.y2}
        stroke={shape.color || '#3b82f6'}
        strokeWidth="2"
        pointerEvents="none"
      />
    )
  } else if (shape.type === 'rectangle') {
    return (
      <rect
        x={shape.x}
        y={shape.y}
        width={shape.width}
        height={shape.height}
        fill="none"
        stroke={shape.color || '#ef4444'}
        strokeWidth="2"
        pointerEvents="none"
        {...selectedStyle}
      />
    )
  } else if (shape.type === 'circle') {
    return (
      <circle
        cx={shape.cx}
        cy={shape.cy}
        r={shape.r}
        fill="none"
        stroke={shape.color || '#8b5cf6'}
        strokeWidth="2"
        pointerEvents="none"
        {...selectedStyle}
      />
    )
  } else if (shape.type === 'arrow') {
    const headlen = 15
    const angle = Math.atan2(shape.y2 - shape.y1, shape.x2 - shape.x1)
    const color = shape.color || '#ec4899'
    return (
      <g pointerEvents="none">
        <line x1={shape.x1} y1={shape.y1} x2={shape.x2} y2={shape.y2} stroke={color} strokeWidth="2" />
        <polygon
          points={`${shape.x2},${shape.y2} ${shape.x2 - headlen * Math.cos(angle - Math.PI / 6)},${shape.y2 - headlen * Math.sin(angle - Math.PI / 6)} ${shape.x2 - headlen * Math.cos(angle + Math.PI / 6)},${shape.y2 - headlen * Math.sin(angle + Math.PI / 6)}`}
          fill={color}
        />
      </g>
    )
  } else if (shape.type === 'text') {
    return (
      <text
        x={shape.x}
        y={shape.y}
        fontSize="14"
        fill={shape.color || '#1e293b'}
        pointerEvents="none"
      >
        {shape.text}
      </text>
    )
  } else if (shape.type === 'polygon') {
    return (
      <polygon
        points={shape.points}
        fill="none"
        stroke={shape.color || '#06b6d4'}
        strokeWidth="2"
        pointerEvents="none"
        {...selectedStyle}
      />
    )
  }

  return null
}
