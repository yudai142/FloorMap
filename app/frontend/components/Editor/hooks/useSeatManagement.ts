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
      // ローカルで座席を追加（保存ボタン時にサーバーに送信される）
      const tempId = Math.min(...seats.map(s => s.id), 0) - 1
      const newSeat = {
        id: tempId,
        label: `S${seats.length + 1}`,
        x,
        y,
        occupied: false,
        occupant_name: '不明',
        seat_type: 'regular'
      }
      mergeSeat(newSeat)
      return newSeat
    },
    [seats, mergeSeat]
  )

  const deleteSeat = useCallback(
    async (seatId: number) => {
      // ローカルで座席を削除（保存ボタン時にサーバーに反映される）
      removeSeat(seatId)
    },
    [removeSeat]
  )

  const moveSeat = useCallback(
    async (seatId: number, x: number, y: number) => {
      // ローカルで座席を移動（保存ボタン時にサーバーに反映される）
      const seat = seats.find(s => s.id === seatId)
      if (seat) {
        mergeSeat({ ...seat, x, y })
      }
    },
    [seats, mergeSeat]
  )

  return {
    createSeat,
    deleteSeat,
    moveSeat,
  }
}
