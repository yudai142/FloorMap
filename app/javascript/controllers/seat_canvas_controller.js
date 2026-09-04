import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    roomId: String,
    gridSize: { type: Number, default: 40 },
    context: { type: String, default: "view" },
    currentUserId: { type: Number, default: 0 },
    canManage: { type: Boolean, default: false }
  }

  connect() {
    this.canvas = this.canvasTarget
    this.ctx = this.canvas.getContext("2d")
    this.seats = []
    this.room = {}
    this.drawings = []
    this.seatRects = []

    this.isDrawing = false
    this.drawingStart = null
    this.selectedSeat = null
    this.draggedSeat = null
    this.dragOffset = null

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

    if (this.contextValue === "editor") {
      if (mode === 'seat') {
        const seat = this.getSeatAtPoint(x, y)
        if (!seat) {
          this.createSeat(x, y)
        }
      } else if (mode === 'select') {
        const seat = this.getSeatAtPoint(x, y)
        if (seat) {
          this.draggedSeat = seat
          this.dragOffset = { x: x - (seat.position_x || x), y: y - (seat.position_y || y) }
        }
      } else if (mode === 'draw') {
        this.isDrawing = true
        this.drawingStart = { x, y }
      } else if (mode === 'delete') {
        const seat = this.getSeatAtPoint(x, y)
        if (seat) {
          this.deleteSeat(seat)
        } else {
          this.deleteDrawingAtPoint(x, y)
        }
      }
    } else if (this.contextValue === "view") {
      const seat = this.getSeatAtPoint(x, y)
      if (seat) {
        this.handleSeatClick(seat)
      }
    }
  }

  handleMouseMove(e) {
    const rect = this.canvas.getBoundingClientRect()
    const x = e.clientX - rect.left
    const y = e.clientY - rect.top
    const mode = window.currentEditMode || 'select'

    if (this.contextValue === "editor" && this.draggedSeat && mode === 'select') {
      this.draw()
      const draftX = x - this.dragOffset.x
      const draftY = y - this.dragOffset.y
      this.ctx.strokeStyle = "#fbbf24"
      this.ctx.lineWidth = 2
      this.ctx.setLineDash([5, 5])
      const seatWidth = 60
      const seatHeight = 60
      this.ctx.strokeRect(draftX, draftY, seatWidth, seatHeight)
      this.ctx.setLineDash([])
      return
    }

    if (!this.isDrawing || mode !== 'draw') return

    this.draw()
    const width = x - this.drawingStart.x
    const height = y - this.drawingStart.y
    this.ctx.strokeStyle = "#fbbf24"
    this.ctx.lineWidth = 2
    this.ctx.setLineDash([5, 5])
    this.ctx.strokeRect(this.drawingStart.x, this.drawingStart.y, width, height)
    this.ctx.setLineDash([])
  }

  handleMouseUp(e) {
    const rect = this.canvas.getBoundingClientRect()
    const x = e.clientX - rect.left
    const y = e.clientY - rect.top

    if (this.draggedSeat) {
      const newX = x - this.dragOffset.x
      const newY = y - this.dragOffset.y
      this.moveSeat(this.draggedSeat, newX, newY)
      this.draggedSeat = null
      this.dragOffset = null
      return
    }

    if (!this.isDrawing) return

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
    this.draggedSeat = null
  }

  handleSeatClick(seat) {
    if (!seat.session) {
      this.checkIn(seat)
    } else if (seat.session.user_id === this.currentUserIdValue || this.canManageValue) {
      this.checkOut(seat)
    }
  }

  getSeatAtPoint(x, y) {
    for (const rect of this.seatRects) {
      if (x >= rect.x && x <= rect.x + rect.width &&
          y >= rect.y && y <= rect.y + rect.height) {
        return rect.seat
      }
    }
    return null
  }

  mergeSeat(seat) {
    const index = this.seats.findIndex(s => s.id === seat.id)
    if (index !== -1) {
      this.seats[index] = seat
    } else {
      this.seats.push(seat)
    }
    this.draw()
  }

  removeSeatById(seatId) {
    this.seats = this.seats.filter(s => s.id !== seatId)
    this.draw()
  }

  createSeat(x, y) {
    const formData = new FormData()
    formData.append("seat[position_x]", x)
    formData.append("seat[position_y]", y)
    formData.append("seat[seat_type]", "regular")

    fetch(`/rooms/${this.roomIdValue}/seats.json`, {
      method: "POST",
      headers: { "X-CSRF-Token": this.csrfToken() },
      body: formData
    })
      .then(res => res.json())
      .then(seat => {
        if (seat.id) {
          this.mergeSeat(seat)
        } else if (seat.errors) {
          alert(`座席作成失敗: ${Object.values(seat.errors).join(", ")}`)
        }
      })
      .catch(err => console.error("Seat creation failed:", err))
  }

  moveSeat(seat, x, y) {
    fetch(`/rooms/${this.roomIdValue}/seats/${seat.id}/position.json`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken()
      },
      body: JSON.stringify({ seat: { position_x: x, position_y: y } })
    })
      .then(res => res.json())
      .then(updatedSeat => {
        if (updatedSeat.id) {
          this.mergeSeat(updatedSeat)
        }
      })
      .catch(err => console.error("Seat move failed:", err))
  }

  deleteSeat(seat) {
    if (!confirm(`座席 ${seat.seat_identifier} を削除しますか?`)) return

    fetch(`/rooms/${this.roomIdValue}/seats/${seat.id}.json`, {
      method: "DELETE",
      headers: { "X-CSRF-Token": this.csrfToken() }
    })
      .then(res => {
        if (res.ok) {
          this.removeSeatById(seat.id)
        }
      })
      .catch(err => console.error("Seat deletion failed:", err))
  }

  deleteDrawingAtPoint(x, y) {
    this.drawings = this.drawings.filter(drawing => {
      if (!this.isPointInShape(x, y, drawing)) return true
      return false
    })
    this.draw()
  }

  checkIn(seat) {
    const formData = new FormData()
    formData.append("seat_id", seat.id)

    fetch("/sessions/check_in.json", {
      method: "POST",
      headers: { "X-CSRF-Token": this.csrfToken() },
      body: formData
    })
      .then(res => res.json())
      .then(updatedSeat => {
        if (updatedSeat.id) {
          this.mergeSeat(updatedSeat)
        }
      })
      .catch(err => console.error("Check-in failed:", err))
  }

  checkOut(seat) {
    const session = seat.session
    if (!session) return

    const params = new URLSearchParams()
    params.append("session_id", session.id)

    fetch(`/sessions/check_out.json?${params}`, {
      method: "DELETE",
      headers: { "X-CSRF-Token": this.csrfToken() }
    })
      .then(res => res.json())
      .then(updatedSeat => {
        if (updatedSeat.id) {
          this.mergeSeat(updatedSeat)
        }
      })
      .catch(err => console.error("Check-out failed:", err))
  }

  save() {
    if (this.contextValue !== "editor") return

    fetch(`/rooms/${this.roomIdValue}/floor_plan.json`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken()
      },
      body: JSON.stringify({ room: { floor_plan_data: this.drawings } })
    })
      .then(res => res.json())
      .then(data => {
        if (data.floor_plan_data !== undefined) {
          alert("床面図を保存しました")
        }
      })
      .catch(err => console.error("Floor plan save failed:", err))
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

  csrfToken() {
    return document.querySelector('meta[name="csrf-token"]').content
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
        this.drawings = data.floor_plan_data || []
        this.draw()
      })
      .catch(error => console.error("Canvas data loading failed:", error))
  }

  setupActionCable() {
    import("channels/rooms_channel").then(module => {
      module.subscribeToRoom(this.roomIdValue, (data) => {
        if (data.type === "seat_updated") {
          this.mergeSeat(data.seat)
        } else if (data.type === "seat_removed") {
          this.removeSeatById(data.seat_id)
        }
      })
    })
  }

  draw() {
    this.ctx.fillStyle = "#ffffff"
    this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height)

    this.drawGrid()
    this.drawShapes()
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
    if (!this.seats || this.seats.length === 0) {
      this.seatRects = []
      return
    }

    this.seatRects = []
    const seatWidth = 60
    const seatHeight = 60

    this.seats.forEach(seat => {
      let x, y

      if (seat.position_x !== null && seat.position_y !== null) {
        x = seat.position_x
        y = seat.position_y
      } else {
        const padding = 40
        const gridWidth = this.canvas.width - padding * 2
        const gridHeight = this.canvas.height - padding * 2
        const rowCount = Math.max(...this.seats.map(s => s.row_number || 0)) + 1
        const colCount = Math.max(...this.seats.map(s => s.column_number || 0)) + 1
        const computedWidth = Math.min(80, gridWidth / colCount)
        const computedHeight = Math.min(80, gridHeight / rowCount)
        const spacing = 16
        x = padding + (seat.column_number || 0) * (computedWidth + spacing)
        y = padding + (seat.row_number || 0) * (computedHeight + spacing)
      }

      this.drawSeat(x, y, seatWidth, seatHeight, seat)

      this.seatRects.push({ x, y, width: seatWidth, height: seatHeight, seat })
    })
  }

  drawSeat(x, y, width, height, seat) {
    const isOccupied = seat.session !== null && seat.session !== undefined

    this.ctx.strokeStyle = isOccupied ? "#3b82f6" : "#10b981"
    this.ctx.fillStyle = isOccupied ? "rgba(59, 130, 246, 0.2)" : "rgba(16, 185, 129, 0.1)"
    this.ctx.lineWidth = 2

    this.ctx.fillRect(x, y, width, height)
    this.ctx.strokeRect(x, y, width, height)

    this.ctx.fillStyle = "rgba(0, 0, 0, 0.7)"
    this.ctx.font = "12px bold sans-serif"
    this.ctx.textAlign = "center"
    this.ctx.textBaseline = "middle"
    this.ctx.fillText(seat.seat_identifier || `${String.fromCharCode(65 + (seat.row_number || 0))}${seat.column_number || 0}`, x + width / 2, y + height / 2 - 10)

    const dotColor = isOccupied ? "#3b82f6" : "#94a3b8"
    this.ctx.fillStyle = dotColor
    this.ctx.beginPath()
    this.ctx.arc(x + width / 2, y + height / 2 + 15, 6, 0, Math.PI * 2)
    this.ctx.fill()
  }
}
