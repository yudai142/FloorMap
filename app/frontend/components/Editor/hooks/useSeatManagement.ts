import { useCallback } from 'react'
import { useEditorStore } from '../../../store/editorStore'
import type { Seat, Shape } from '../../../types/Canvas'

export const useSeatManagement = (roomId: number) => {
  const { addShape, mergeSeat, removeSeat, saveToHistory, seats } = useEditorStore()

  const getCsrfToken = useCallback(() => {
    return document.querySelector('meta[name="csrf-token"]')?.content || ''
  }, [])

  const createSeat = useCallback(
    async (x: number, y: number) => {
      const seatLabel = `S${seats.length + 1}`

      try {
        const response = await fetch(`/rooms/${roomId}/seats.json`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': getCsrfToken(),
          },
          body: JSON.stringify({
            seat: {
              position_x: x,
              position_y: y,
              seat_type: 'regular',
            },
          }),
        })

        if (!response.ok) {
          const error = await response.json()
          throw new Error(error.errors?.[0] || '座席の追加に失敗しました')
        }

        const newSeat = await response.json()
        mergeSeat(newSeat)
        saveToHistory(seats, [])
        return newSeat
      } catch (err) {
        console.error('Seat creation error:', err)
        throw err
      }
    },
    [roomId, seats, mergeSeat, saveToHistory, getCsrfToken]
  )

  const deleteSeat = useCallback(
    async (seatId: number) => {
      try {
        const response = await fetch(`/rooms/${roomId}/seats/${seatId}.json`, {
          method: 'DELETE',
          headers: {
            'X-CSRF-Token': getCsrfToken(),
          },
        })

        if (!response.ok) {
          throw new Error('座席の削除に失敗しました')
        }

        removeSeat(seatId)
        saveToHistory(seats, [])
      } catch (err) {
        console.error('Seat deletion error:', err)
        throw err
      }
    },
    [roomId, seats, removeSeat, saveToHistory, getCsrfToken]
  )

  const moveSeat = useCallback(
    async (seatId: number, x: number, y: number) => {
      try {
        const response = await fetch(`/rooms/${roomId}/seats/${seatId}/position.json`, {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': getCsrfToken(),
          },
          body: JSON.stringify({
            seat: {
              position_x: x,
              position_y: y,
            },
          }),
        })

        if (!response.ok) {
          throw new Error('座席の移動に失敗しました')
        }

        const updatedSeat = await response.json()
        mergeSeat(updatedSeat)
      } catch (err) {
        console.error('Seat move error:', err)
        throw err
      }
    },
    [roomId, mergeSeat, getCsrfToken]
  )

  return {
    createSeat,
    deleteSeat,
    moveSeat,
  }
}
