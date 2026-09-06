import consumer from "./consumer"

export function subscribeToRoom(roomId, callbacks = {}) {
  const subscription = consumer.subscriptions.create(
    { channel: "RoomsChannel", room_id: roomId },
    {
      connected() {
        console.log(`[ActionCable] Connected to room ${roomId}`)
        callbacks.onConnected?.()
      },

      disconnected() {
        console.log(`[ActionCable] Disconnected from room ${roomId}`)
        callbacks.onDisconnected?.()
      },

      received(data) {
        console.log(`[ActionCable] Received broadcast for room ${roomId}:`, data)

        switch (data.type) {
          case "seat_updated":
            callbacks.onSeatUpdated?.(data.seat)
            callbacks.onUpdate?.(data) // Legacy support
            break

          case "seat_removed":
            callbacks.onSeatRemoved?.(data.seat_id)
            callbacks.onUpdate?.(data) // Legacy support
            break

          case "floor_plan_updated":
            callbacks.onFloorPlanUpdated?.(data.floor_plan_data)
            callbacks.onUpdate?.(data) // Legacy support
            break

          default:
            console.warn(`[ActionCable] Unknown broadcast type: ${data.type}`)
        }
      },

      speak(message) {
        this.perform("speak", { message })
      }
    }
  )

  return subscription
}

export function unsubscribeFromRoom(subscription) {
  if (subscription) {
    subscription.unsubscribe()
    console.log("[ActionCable] Unsubscribed from room")
  }
}
