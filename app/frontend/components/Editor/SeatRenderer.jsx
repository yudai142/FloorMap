import React, { useCallback } from 'react'

export default function SeatRenderer({ seat, onDelete }) {
  const handleContextMenu = useCallback(
    (e) => {
      e.preventDefault()
      if (confirm(`座席 ${seat.label} を削除しますか?`)) {
        onDelete(seat.id)
      }
    },
    [seat.id, seat.label, onDelete]
  )

  return (
    <g transform={`translate(${seat.x}, ${seat.y})`} onContextMenu={handleContextMenu} style={{ cursor: 'grab' }}>
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
        {seat.label}
      </text>
      {seat.occupied && (
        <text x="16" y="14" fontSize="9" fill="#666" className="pointer-events-none">
          {seat.occupant_name}
        </text>
      )}
    </g>
  )
}
