import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    roomId: String,
    canvasData: Object,
    gridSize: { type: Number, default: 40 },
    snapToGrid: { type: Boolean, default: true }
  }

  connect() {
    this.canvas = this.canvasTarget
    this.ctx = this.canvas.getContext("2d")
    this.draggingSeat = null
    this.dragOffset = { x: 0, y: 0 }
    this.shapes = [] // 図形（壁・パーティション等）

    this.canvas.width = this.canvas.offsetWidth
    this.canvas.height = this.canvas.offsetHeight

    this.loadCanvasData()
    this.setupEventListeners()
    this.setupActionCable()
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

  setupEventListeners() {
    this.canvas.addEventListener("mousedown", e => this.handleCanvasMouseDown(e))
    this.canvas.addEventListener("mousemove", e => this.handleMouseMove(e))
    this.canvas.addEventListener("mouseup", e => this.handleCanvasMouseUp(e))
    this.canvas.addEventListener("mouseleave", e => this.handleMouseLeave(e))
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
    this.ctx.fillStyle = "#ffffff"
    this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height)

    this.drawGrid()
    this.drawShapes()
    this.drawSeats()
  }

  drawGrid() {
    const gridSize = this.gridSizeValue
    this.ctx.strokeStyle = "rgba(0, 0, 0, 0.1)"
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

  drawShapes() {
    if (!this.shapes || this.shapes.length === 0) return

    this.shapes.forEach(shape => {
      switch (shape.type) {
        case "rectangle":
          this.drawRectangle(shape)
          break
        case "circle":
          this.drawCircle(shape)
          break
        case "line":
          this.drawLine(shape)
          break
      }
    })
  }

  drawRectangle(shape) {
    this.ctx.strokeStyle = shape.color || "#ef4444"
    this.ctx.lineWidth = shape.lineWidth || 2
    this.ctx.strokeRect(shape.x, shape.y, shape.width, shape.height)
  }

  drawCircle(shape) {
    this.ctx.strokeStyle = shape.color || "#ef4444"
    this.ctx.lineWidth = shape.lineWidth || 2
    this.ctx.beginPath()
    this.ctx.arc(shape.x + shape.radius / 2, shape.y + shape.radius / 2, shape.radius, 0, Math.PI * 2)
    this.ctx.stroke()
  }

  drawLine(shape) {
    this.ctx.strokeStyle = shape.color || "#ef4444"
    this.ctx.lineWidth = shape.lineWidth || 2
    this.ctx.beginPath()
    this.ctx.moveTo(shape.x1, shape.y1)
    this.ctx.lineTo(shape.x2, shape.y2)
    this.ctx.stroke()
  }

  drawSeats() {
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

  handleCanvasMouseDown(e) {
    const rect = this.canvas.getBoundingClientRect()
    const mouseX = e.clientX - rect.left
    const mouseY = e.clientY - rect.top

    const editMode = window.currentEditMode || 'select'

    switch (editMode) {
      case 'select':
        this.handleSeatDragStart(mouseX, mouseY)
        break
      case 'draw':
        this.startDrawing(mouseX, mouseY)
        break
      case 'delete':
        this.deleteAtPoint(mouseX, mouseY)
        break
    }
  }

  handleSeatDragStart(mouseX, mouseY) {
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

  startDrawing(x, y) {
    this.isDrawing = true
    this.drawingStart = { x, y }
    this.canvas.style.cursor = "crosshair"
  }

  deleteAtPoint(x, y) {
    const seat = this.getSeatAtPoint(x, y)
    if (seat && confirm(`座席 ${seat.seat_identifier} を削除しますか？`)) {
      this.deleteSeat(seat)
      return
    }

    const shape = this.shapes.find(s => this.isPointInShape(x, y, s))
    if (shape) {
      this.shapes = this.shapes.filter(s => s !== shape)
      this.draw()
    }
  }

  isPointInShape(x, y, shape) {
    switch (shape.type) {
      case "rectangle":
        return x >= shape.x && x <= shape.x + shape.width && y >= shape.y && y <= shape.y + shape.height
      case "circle":
        const dist = Math.sqrt(Math.pow(x - (shape.x + shape.radius / 2), 2) + Math.pow(y - (shape.y + shape.radius / 2), 2))
        return dist <= shape.radius + 5
      default:
        return false
    }
  }

  deleteSeat(seat) {
    const roomId = this.roomIdValue
    const seatId = seat.id

    fetch(`/rooms/${roomId}/seats/${seatId}`, {
      method: "DELETE",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      }
    })
      .then(() => {
        this.seats = this.seats.filter(s => s.id !== seatId)
        this.draw()
        console.log("Seat deleted:", seatId)
      })
      .catch(error => console.error("Seat deletion failed:", error))
  }

  handleMouseMove(e) {
    const rect = this.canvas.getBoundingClientRect()
    const mouseX = e.clientX - rect.left
    const mouseY = e.clientY - rect.top

    const editMode = window.currentEditMode || 'select'

    if (editMode === 'select') {
      const seat = this.getSeatAtPoint(mouseX, mouseY)
      this.canvas.style.cursor = seat ? "grab" : "default"

      if (this.draggingSeat) {
        this.draw()
      }
    } else if (editMode === 'draw' && this.isDrawing) {
      this.draw()
      // 描画プレビュー
      this.ctx.strokeStyle = "#fbbf24"
      this.ctx.lineWidth = 2
      this.ctx.setLineDash([5, 5])
      this.ctx.strokeRect(
        this.drawingStart.x,
        this.drawingStart.y,
        mouseX - this.drawingStart.x,
        mouseY - this.drawingStart.y
      )
      this.ctx.setLineDash([])
    }
  }

  handleCanvasMouseUp(e) {
    if (this.draggingSeat) {
      const rect = this.canvas.getBoundingClientRect()
      const mouseX = e.clientX - rect.left
      const mouseY = e.clientY - rect.top

      let finalX = mouseX
      let finalY = mouseY

      if (this.snapToGridValue) {
        finalX = Math.round(mouseX / this.gridSizeValue) * this.gridSizeValue
        finalY = Math.round(mouseY / this.gridSizeValue) * this.gridSizeValue
      }

      this.updateSeatPosition(this.draggingSeat, finalX, finalY)
      this.draggingSeat = null
      this.canvas.style.cursor = "default"
    } else if (this.isDrawing) {
      const rect = this.canvas.getBoundingClientRect()
      const mouseX = e.clientX - rect.left
      const mouseY = e.clientY - rect.top

      const width = mouseX - this.drawingStart.x
      const height = mouseY - this.drawingStart.y

      if (Math.abs(width) > 5 && Math.abs(height) > 5) {
        this.addRectangle(this.drawingStart.x, this.drawingStart.y, width, height, "#ef4444", 2)
      }

      this.isDrawing = false
      this.drawingStart = null
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

  // 図形描画メソッド（外部から呼び出し可能）
  addRectangle(x, y, width, height, color = "#ef4444", lineWidth = 2) {
    this.shapes.push({ type: "rectangle", x, y, width, height, color, lineWidth })
    this.draw()
  }

  addCircle(x, y, radius, color = "#ef4444", lineWidth = 2) {
    this.shapes.push({ type: "circle", x, y, radius, color, lineWidth })
    this.draw()
  }

  addLine(x1, y1, x2, y2, color = "#ef4444", lineWidth = 2) {
    this.shapes.push({ type: "line", x1, y1, x2, y2, color, lineWidth })
    this.draw()
  }

  clearShapes() {
    this.shapes = []
    this.draw()
  }
}
