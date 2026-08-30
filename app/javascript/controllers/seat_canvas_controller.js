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
    this.drawings = [] // ユーザーが描画した図形を保存

    // マウスイベント
    this.isDrawing = false
    this.drawingStart = null
    this.selectedSeat = null

    this.resizeCanvas()
    window.addEventListener("resize", () => this.resizeCanvas())

    this.setupEventListeners()
    this.loadCanvasData()
    this.setupActionCable()
  }

  setupEventListeners() {
    this.canvas.addEventListener("mousedown", (e) => this.handleMouseDown(e))
    this.canvas.addEventListener("mousemove", (e) => this.handleMouseMove(e))
    this.canvas.addEventListener("mouseup", (e) => this.handleMouseUp(e))
    this.canvas.addEventListener("mouseleave", () => this.handleMouseLeave())
  }

  handleMouseDown(e) {
    const rect = this.canvas.getBoundingClientRect()
    const x = e.clientX - rect.left
    const y = e.clientY - rect.top

    const mode = window.currentEditMode || 'select'

    if (mode === 'draw') {
      this.isDrawing = true
      this.drawingStart = { x, y }
    } else if (mode === 'delete') {
      this.deleteAtPoint(x, y)
    }
  }

  handleMouseMove(e) {
    if (!this.isDrawing) return

    const rect = this.canvas.getBoundingClientRect()
    const x = e.clientX - rect.left
    const y = e.clientY - rect.top

    this.draw()

    // 描画プレビューを表示
    const width = x - this.drawingStart.x
    const height = y - this.drawingStart.y

    this.ctx.strokeStyle = "#fbbf24"
    this.ctx.lineWidth = 2
    this.ctx.setLineDash([5, 5])
    this.ctx.strokeRect(this.drawingStart.x, this.drawingStart.y, width, height)
    this.ctx.setLineDash([])
  }

  handleMouseUp(e) {
    if (!this.isDrawing) return

    const rect = this.canvas.getBoundingClientRect()
    const x = e.clientX - rect.left
    const y = e.clientY - rect.top

    const width = x - this.drawingStart.x
    const height = y - this.drawingStart.y

    if (Math.abs(width) > 5 && Math.abs(height) > 5) {
      this.drawings.push({
        type: "rectangle",
        x: this.drawingStart.x,
        y: this.drawingStart.y,
        width: width,
        height: height,
        color: "#ef4444",
        lineWidth: 2
      })
    }

    this.isDrawing = false
    this.drawingStart = null
    this.draw()
  }

  handleMouseLeave() {
    this.isDrawing = false
    this.drawingStart = null
  }

  deleteAtPoint(x, y) {
    // 図形の削除
    this.drawings = this.drawings.filter(drawing => {
      if (!this.isPointInShape(x, y, drawing)) return true
      return false
    })

    this.draw()
  }

  isPointInShape(x, y, shape) {
    if (shape.type === "rectangle") {
      const minX = Math.min(shape.x, shape.x + shape.width)
      const maxX = Math.max(shape.x, shape.x + shape.width)
      const minY = Math.min(shape.y, shape.y + shape.height)
      const maxY = Math.max(shape.y, shape.y + shape.height)
      return x >= minX && x <= maxX && y >= minY && y <= maxY
    }
    return false
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

    // ユーザーが描画した図形を描画
    this.drawShapes()

    // 座席を描画
    this.drawSeats()
  }

  drawShapes() {
    this.drawings.forEach(drawing => {
      if (drawing.type === "rectangle") {
        this.ctx.strokeStyle = drawing.color
        this.ctx.lineWidth = drawing.lineWidth
        this.ctx.strokeRect(drawing.x, drawing.y, drawing.width, drawing.height)
      }
    })
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
