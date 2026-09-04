import consumer from "./consumer"

export const subscribeToRoom = (roomId, onUpdate) => {
  consumer.subscriptions.create(
    { channel: "RoomsChannel", room_id: roomId },
    {
      received(data) {
        if (data.type === "seat_updated" || data.type === "seat_removed") {
          onUpdate(data)
        }
      }
    }
  )
}
