import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    roomId: String,
    canvasData: Object
  }

  connect() {
    this.canvas = this.canvasTarget
    this.ctx = this.canvas.getContext("2d")
    this.draggingSeat = null
    this.dragOffset = { x: 0, y: 0 }

    this.canvas.width = this.canvas.offsetWidth
    this.canvas.height = this.canvas.offsetHeight

    this.loadCanvasData()
    this.setupEventListeners()
    this.drawSeats()
  }

  loadCanvasData() {
    fetch(`/rooms/${this.roomIdValue}/canvas_data`)
      .then(response => response.json())
      .then(data => {
        this.seats = data.seats || []
        this.room = data.room || {}
        this.drawSeats()
      })
      .catch(error => console.error("Canvas data loading failed:", error))
  }

  setupEventListeners() {
    this.canvas.addEventListener("mousedown", e => this.handleMouseDown(e))
    this.canvas.addEventListener("mousemove", e => this.handleMouseMove(e))
    this.canvas.addEventListener("mouseup", e => this.handleMouseUp(e))
    this.canvas.addEventListener("mouseleave", e => this.handleMouseLeave(e))
  }

  drawSeats() {
    this.ctx.fillStyle = "#1e293b"
    this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height)

    if (!this.seats || this.seats.length === 0) return

    const padding = 40
    const gridWidth = this.canvas.width - padding * 2
    const gridHeight = this.canvas.height - padding * 2

    const rowCount = Math.max(...this.seats.map(s => s.row_number || 0)) + 1
    const colCount = Math.max(...this.seats.map(s => s.column_number || 0))

    const seatWidth = Math.min(80, gridWidth / (colCount + 1))
    const seatHeight = Math.min(80, gridHeight / rowCount)
    const spacing = 16

    this.seats.forEach(seat => {
      const row = seat.row_number || 0
      const col = seat.column_number || 0

      const x = padding + col * (seatWidth + spacing)
      const y = padding + row * (seatHeight + spacing)

      this.drawSeat(x, y, seatWidth, seatHeight, seat)
    })
  }

  drawSeat(x, y, width, height, seat) {
    const isOccupied = seat.session !== null
    const isHovered = this.draggingSeat?.id === seat.id

    this.ctx.strokeStyle = isOccupied ? "#3b82f6" : "#10b981"
    this.ctx.fillStyle = isOccupied ? "rgba(59, 130, 246, 0.2)" : "rgba(16, 185, 129, 0.1)"
    this.ctx.lineWidth = 2

    this.ctx.fillRect(x, y, width, height)
    this.ctx.strokeRect(x, y, width, height)

    if (isHovered) {
      this.ctx.strokeStyle = "#fbbf24"
      this.ctx.lineWidth = 3
      this.ctx.strokeRect(x - 2, y - 2, width + 4, height + 4)
    }

    this.ctx.fillStyle = "rgba(255, 255, 255, 0.6)"
    this.ctx.font = "12px bold sans-serif"
    this.ctx.textAlign = "center"
    this.ctx.textBaseline = "middle"
    this.ctx.fillText(seat.seat_identifier || `${String.fromCharCode(65 + seat.row_number)}${seat.column_number}`, x + width / 2, y + height / 2 - 10)

    const dotColor = isOccupied ? "#3b82f6" : "#94a3b8"
    this.ctx.fillStyle = dotColor
    this.ctx.beginPath()
    this.ctx.arc(x + width / 2, y + height / 2 + 15, 6, 0, Math.PI * 2)
    this.ctx.fill()

    seat._screenPos = { x, y, width, height }
  }

  handleMouseDown(e) {
    const rect = this.canvas.getBoundingClientRect()
    const mouseX = e.clientX - rect.left
    const mouseY = e.clientY - rect.top

    const seat = this.getSeatAtPoint(mouseX, mouseY)
    if (seat) {
      this.draggingSeat = seat
      this.dragOffset = {
        x: mouseX - seat._screenPos.x,
        y: mouseY - seat._screenPos.y
      }
      this.canvas.style.cursor = "grabbing"
    }
  }

  handleMouseMove(e) {
    const rect = this.canvas.getBoundingClientRect()
    const mouseX = e.clientX - rect.left
    const mouseY = e.clientY - rect.top

    const seat = this.getSeatAtPoint(mouseX, mouseY)
    this.canvas.style.cursor = seat ? "grab" : "default"

    if (this.draggingSeat) {
      this.drawSeats()
    }
  }

  handleMouseUp(e) {
    if (this.draggingSeat) {
      const rect = this.canvas.getBoundingClientRect()
      const mouseX = e.clientX - rect.left
      const mouseY = e.clientY - rect.top

      this.updateSeatPosition(this.draggingSeat, mouseX, mouseY)
      this.draggingSeat = null
      this.canvas.style.cursor = "default"
    }
  }

  handleMouseLeave(e) {
    this.draggingSeat = null
    this.canvas.style.cursor = "default"
  }

  getSeatAtPoint(x, y) {
    return this.seats.find(seat => {
      if (!seat._screenPos) return false
      const pos = seat._screenPos
      return x >= pos.x && x <= pos.x + pos.width && y >= pos.y && y <= pos.y + pos.height
    })
  }

  updateSeatPosition(seat, x, y) {
    const roomId = this.roomIdValue
    const seatId = seat.id

    fetch(`/rooms/${roomId}/seats/${seatId}/position`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        seat: {
          position_x: x,
          position_y: y
        }
      })
    })
      .then(response => response.json())
      .then(data => {
        console.log("Seat position updated:", data)
        this.loadCanvasData()
      })
      .catch(error => console.error("Position update failed:", error))
  }
}
