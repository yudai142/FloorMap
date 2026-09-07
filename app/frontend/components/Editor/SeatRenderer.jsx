import React, { useCallback } from 'react'

export default function SeatRenderer({ seat, onDelete }) {
  const handleContextMenu = useCallback(
    (e) => {
      e.preventDefault()
      onDelete(seat.id)
    },
    [seat.id, onDelete]
  )

  const x = seat.x ?? 0
  const y = seat.y ?? 0

  return (
    <g transform={`translate(${x}, ${y})`} onContextMenu={handleContextMenu} style={{ cursor: 'grab' }}>
      <circle
        r="12"
        fill={seat.occupied ? '#f87171' : '#4ade80'}
        stroke="#065f46"
        strokeWidth="2"
      />
      <text
        x="16"
        y="4"
        fontSize="12"
        fill="#000"
        className="pointer-events-none"
        fontWeight="bold"
      >
        {seat.occupied ? seat.occupant_name : seat.label}
      </text>
    </g>
  )
}
