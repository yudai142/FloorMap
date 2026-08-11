import consumer from "./consumer"

export const subscribeToRoom = (roomId, onSeatUpdate) => {
  consumer.subscriptions.create(
    { channel: "RoomsChannel", room_id: roomId },
    {
      received(data) {
        if (data.type === "seat_updated") {
          onSeatUpdate(data.seat)
        }
      }
    }
  )
}
