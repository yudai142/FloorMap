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
          try {
            const error = await response.json()
            throw new Error(error.errors?.[0] || '座席の追加に失敗しました')
          } catch (e) {
            throw new Error('座席の追加に失敗しました')
          }
        }

        try {
          const responseText = await response.text()
          if (!responseText) {
            throw new Error('レスポンスが空です')
          }
          const data = JSON.parse(responseText)
          const newSeat = {
            id: data.id,
            label: data.seat_identifier,
            x: data.position_x || 0,
            y: data.position_y || 0,
            occupied: false,
            occupant_name: '不明',
            seat_type: data.seat_type
          }
          mergeSeat(newSeat)
          saveToHistory(seats, [])
          return newSeat
        } catch (e) {
          console.error('座席追加エラー:', e)
          throw new Error('座席の追加に失敗しました')
        }
      } catch (err) {
        console.error('座席作成中にエラー:', err)
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

        try {
          const updatedSeat = await response.json()
          mergeSeat(updatedSeat)
        } catch (e) {
          throw new Error('座席の移動に失敗しました')
        }
      } catch (err) {
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
