import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    roomId: String,
    gridSize: { type: Number, default: 40 }
  }

  connect() {
    this.canvas = this.canvasTarget
    this.ctx = this.canvas.getContext("2d")
    this.seats = []
    this.room = {}

    this.resizeCanvas()
    window.addEventListener("resize", () => this.resizeCanvas())

    this.loadCanvasData()
    this.setupActionCable()
  }

  resizeCanvas() {
    const rect = this.canvas.parentElement.getBoundingClientRect()
    this.canvas.width = Math.max(800, rect.width - 64)
    this.canvas.height = Math.max(600, window.innerHeight - 300)
    this.draw()
  }

  loadCanvasData() {
    fetch(`/rooms/${this.roomIdValue}/canvas_data`)
      .then(response => response.json())
      .then(data => {
        this.seats = data.seats || []
        this.room = data.room || {}
        this.draw()
      })
      .catch(error => console.error("Canvas data loading failed:", error))
  }

  setupActionCable() {
    import("channels/rooms_channel").then(module => {
      module.subscribeToRoom(this.roomIdValue, (updatedSeat) => {
        this.updateSeatFromBroadcast(updatedSeat)
      })
    })
  }

  updateSeatFromBroadcast(updatedSeat) {
    const seatIndex = this.seats.findIndex(s => s.id === updatedSeat.id)
    if (seatIndex !== -1) {
      this.seats[seatIndex] = updatedSeat
      this.draw()
    }
  }

  draw() {
    // 背景を白で塗りつぶし
    this.ctx.fillStyle = "#ffffff"
    this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height)

    // グリッドを描画
    this.drawGrid()

    // 座席を描画
    this.drawSeats()
  }

  drawGrid() {
    const gridSize = this.gridSizeValue
    this.ctx.strokeStyle = "rgba(0, 0, 0, 0.05)"
    this.ctx.lineWidth = 1

    for (let x = 0; x < this.canvas.width; x += gridSize) {
      this.ctx.beginPath()
      this.ctx.moveTo(x, 0)
      this.ctx.lineTo(x, this.canvas.height)
      this.ctx.stroke()
    }

    for (let y = 0; y < this.canvas.height; y += gridSize) {
      this.ctx.beginPath()
      this.ctx.moveTo(0, y)
      this.ctx.lineTo(this.canvas.width, y)
      this.ctx.stroke()
    }
  }

  drawSeats() {
    if (!this.seats || this.seats.length === 0) return

    const padding = 40
    const gridWidth = this.canvas.width - padding * 2
    const gridHeight = this.canvas.height - padding * 2

    const rowCount = Math.max(...this.seats.map(s => s.row_number || 0)) + 1
    const colCount = Math.max(...this.seats.map(s => s.column_number || 0)) + 1

    const seatWidth = Math.min(80, gridWidth / colCount)
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

    // 座席を描画
    this.ctx.strokeStyle = isOccupied ? "#3b82f6" : "#10b981"
    this.ctx.fillStyle = isOccupied ? "rgba(59, 130, 246, 0.2)" : "rgba(16, 185, 129, 0.1)"
    this.ctx.lineWidth = 2

    this.ctx.fillRect(x, y, width, height)
    this.ctx.strokeRect(x, y, width, height)

    // 座席番号を描画
    this.ctx.fillStyle = "rgba(0, 0, 0, 0.7)"
    this.ctx.font = "12px bold sans-serif"
    this.ctx.textAlign = "center"
    this.ctx.textBaseline = "middle"
    this.ctx.fillText(seat.seat_identifier || `${String.fromCharCode(65 + seat.row_number)}${seat.column_number}`, x + width / 2, y + height / 2 - 10)

    // ステータスドットを描画
    const dotColor = isOccupied ? "#3b82f6" : "#94a3b8"
    this.ctx.fillStyle = dotColor
    this.ctx.beginPath()
    this.ctx.arc(x + width / 2, y + height / 2 + 15, 6, 0, Math.PI * 2)
    this.ctx.fill()
  }
}
