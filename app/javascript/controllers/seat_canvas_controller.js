import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    roomId: { type: String, default: "" },
    templateId: { type: String, default: "" },
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

    // ポリゴン描画用の状態管理
    this.polygonPoints = []
    this.isDrawingText = false
    this.textPosition = null

    this.resizeCanvas()
    window.addEventListener("resize", () => this.resizeCanvas())
    window.addEventListener("keydown", (e) => this.handleKeyDown(e))

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
        // 矩形描画
        this.isDrawing = true
        this.drawingStart = { x, y }
      } else if (mode === 'line') {
        // 直線描画
        this.isDrawing = true
        this.drawingStart = { x, y }
      } else if (mode === 'circle') {
        // 円描画
        this.isDrawing = true
        this.drawingStart = { x, y }
      } else if (mode === 'arrow') {
        // 矢印描画
        this.isDrawing = true
        this.drawingStart = { x, y }
      } else if (mode === 'polygon') {
        // ポリゴン描画（クリックで点を追加）
        this.polygonPoints.push({ x, y })
        this.draw()
      } else if (mode === 'text') {
        // テキスト配置
        this.isDrawingText = true
        this.textPosition = { x, y }
        const text = prompt("入力するテキスト:")
        if (text) {
          this.drawings.push({
            type: "text",
            x: x,
            y: y,
            text: text,
            color: window.currentColor || "#000000",
            fontSize: 16,
            fontFamily: "sans-serif"
          })
          this.isDrawingText = false
          this.textPosition = null
          this.draw()
        }
      } else if (mode === 'fill') {
        // 塗りつぶし（図形を指定色で塗りつぶし）
        const drawing = this.getDrawingAtPoint(x, y)
        if (drawing) {
          drawing.fillColor = window.currentColor || "#000000"
          drawing.filled = true
          this.draw()
        }
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

    if (!this.isDrawing || !this.drawingStart) return

    this.draw()
    this.ctx.strokeStyle = "#fbbf24"
    this.ctx.lineWidth = 2
    this.ctx.setLineDash([5, 5])

    if (mode === 'draw') {
      // 矩形プレビュー
      const width = x - this.drawingStart.x
      const height = y - this.drawingStart.y
      this.ctx.strokeRect(this.drawingStart.x, this.drawingStart.y, width, height)
    } else if (mode === 'line') {
      // 直線プレビュー
      this.ctx.beginPath()
      this.ctx.moveTo(this.drawingStart.x, this.drawingStart.y)
      this.ctx.lineTo(x, y)
      this.ctx.stroke()
    } else if (mode === 'circle') {
      // 円プレビュー
      const radius = Math.sqrt(Math.pow(x - this.drawingStart.x, 2) + Math.pow(y - this.drawingStart.y, 2))
      this.ctx.beginPath()
      this.ctx.arc(this.drawingStart.x, this.drawingStart.y, radius, 0, Math.PI * 2)
      this.ctx.stroke()
    } else if (mode === 'arrow') {
      // 矢印プレビュー
      this.ctx.beginPath()
      this.ctx.moveTo(this.drawingStart.x, this.drawingStart.y)
      this.ctx.lineTo(x, y)
      this.ctx.stroke()
      // 矢印の先端
      this.drawArrowHead(this.drawingStart.x, this.drawingStart.y, x, y)
    }

    this.ctx.setLineDash([])
  }

  handleMouseUp(e) {
    const rect = this.canvas.getBoundingClientRect()
    const x = e.clientX - rect.left
    const y = e.clientY - rect.top
    const mode = window.currentEditMode || 'select'

    if (this.draggedSeat) {
      const newX = x - this.dragOffset.x
      const newY = y - this.dragOffset.y
      this.moveSeat(this.draggedSeat, newX, newY)
      this.draggedSeat = null
      this.dragOffset = null
      return
    }

    if (!this.isDrawing || !this.drawingStart) return

    const color = window.currentColor || "#3b82f6"

    if (mode === 'draw') {
      // 矩形描画
      const width = x - this.drawingStart.x
      const height = y - this.drawingStart.y

      if (Math.abs(width) > 5 && Math.abs(height) > 5) {
        this.drawings.push({
          type: "rectangle",
          x: this.drawingStart.x,
          y: this.drawingStart.y,
          width: width,
          height: height,
          color: color,
          lineWidth: 2
        })
      }
    } else if (mode === 'line') {
      // 直線描画
      if (Math.abs(x - this.drawingStart.x) > 5 || Math.abs(y - this.drawingStart.y) > 5) {
        this.drawings.push({
          type: "line",
          x1: this.drawingStart.x,
          y1: this.drawingStart.y,
          x2: x,
          y2: y,
          color: color,
          lineWidth: 2
        })
      }
    } else if (mode === 'circle') {
      // 円描画
      const radius = Math.sqrt(Math.pow(x - this.drawingStart.x, 2) + Math.pow(y - this.drawingStart.y, 2))
      if (radius > 5) {
        this.drawings.push({
          type: "circle",
          cx: this.drawingStart.x,
          cy: this.drawingStart.y,
          radius: radius,
          color: color,
          lineWidth: 2
        })
      }
    } else if (mode === 'arrow') {
      // 矢印描画
      if (Math.abs(x - this.drawingStart.x) > 5 || Math.abs(y - this.drawingStart.y) > 5) {
        this.drawings.push({
          type: "arrow",
          x1: this.drawingStart.x,
          y1: this.drawingStart.y,
          x2: x,
          y2: y,
          color: color,
          lineWidth: 2
        })
      }
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

  handleKeyDown(e) {
    const mode = window.currentEditMode || 'select'

    if (mode === 'polygon' && e.key === 'Enter') {
      // ポリゴンを確定
      if (this.polygonPoints.length >= 3) {
        this.drawings.push({
          type: "polygon",
          points: [...this.polygonPoints],
          color: window.currentColor || "#3b82f6",
          lineWidth: 2
        })
        this.polygonPoints = []
        this.draw()
      }
    } else if (mode === 'polygon' && e.key === 'Escape') {
      // ポリゴン描画をキャンセル
      this.polygonPoints = []
      this.draw()
    }
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
      .catch(() => {})
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
      .catch(() => {})
  }

  save() {
    if (this.contextValue !== "editor") return

    const url = this.roomIdValue
      ? `/rooms/${this.roomIdValue}/floor_plan.json`
      : `/floor_plan_templates/${this.templateIdValue}/canvas_editor`

    const body = this.roomIdValue
      ? { room: { floor_plan_data: this.drawings } }
      : { floor_plan_template: { floor_plan_data: this.drawings } }

    fetch(url, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken()
      },
      body: JSON.stringify(body)
    })
      .then(res => res.json())
      .then(data => {
        if (this.roomIdValue) {
          if (data.floor_plan_data !== undefined) {
            alert("床面図を保存しました")
          }
        } else {
          // テンプレートの場合はリダイレクト
          window.location.href = `/floor_plan_templates/${this.templateIdValue}/details`
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
    } else if (shape.type === "circle") {
      const distance = Math.sqrt(Math.pow(x - shape.cx, 2) + Math.pow(y - shape.cy, 2))
      return distance <= shape.radius
    } else if (shape.type === "line") {
      // 直線の近くかチェック（5px以内）
      const distance = this.distanceFromPointToLine(x, y, shape.x1, shape.y1, shape.x2, shape.y2)
      return distance <= 5
    } else if (shape.type === "arrow") {
      // 矢印の近くかチェック（5px以内）
      const distance = this.distanceFromPointToLine(x, y, shape.x1, shape.y1, shape.x2, shape.y2)
      return distance <= 5
    } else if (shape.type === "polygon") {
      return this.isPointInPolygon(x, y, shape.points)
    } else if (shape.type === "text") {
      // テキストの領域かチェック（簡易的）
      const approximateWidth = shape.text.length * 8
      const approximateHeight = 20
      return x >= shape.x && x <= shape.x + approximateWidth &&
             y >= shape.y && y <= shape.y + approximateHeight
    }
    return false
  }

  distanceFromPointToLine(px, py, x1, y1, x2, y2) {
    const numerator = Math.abs((y2 - y1) * px - (x2 - x1) * py + x2 * y1 - y2 * x1)
    const denominator = Math.sqrt(Math.pow(y2 - y1, 2) + Math.pow(x2 - x1, 2))
    return numerator / denominator
  }

  isPointInPolygon(x, y, points) {
    if (!points || points.length < 3) return false
    let inside = false
    for (let i = 0, j = points.length - 1; i < points.length; j = i++) {
      const xi = points[i].x, yi = points[i].y
      const xj = points[j].x, yj = points[j].y
      const intersect = ((yi > y) !== (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi)
      if (intersect) inside = !inside
    }
    return inside
  }

  getDrawingAtPoint(x, y) {
    for (let i = this.drawings.length - 1; i >= 0; i--) {
      if (this.isPointInShape(x, y, this.drawings[i])) {
        return this.drawings[i]
      }
    }
    return null
  }

  drawArrowHead(fromX, fromY, toX, toY, color = "#000000") {
    const headlen = 15
    const angle = Math.atan2(toY - fromY, toX - fromX)

    this.ctx.fillStyle = color
    this.ctx.beginPath()
    this.ctx.moveTo(toX, toY)
    this.ctx.lineTo(toX - headlen * Math.cos(angle - Math.PI / 6), toY - headlen * Math.sin(angle - Math.PI / 6))
    this.ctx.lineTo(toX - headlen * Math.cos(angle + Math.PI / 6), toY - headlen * Math.sin(angle + Math.PI / 6))
    this.ctx.closePath()
    this.ctx.fill()
  }

  csrfToken() {
    return document.querySelector('meta[name="csrf-token"]').content
  }

  resizeCanvas() {
    const rect = this.canvas.parentElement.getBoundingClientRect()
    this.canvas.width = Math.max(1000, rect.width - 64)
    this.canvas.height = Math.max(700, window.innerHeight - 200)
    this.draw()
  }

  loadCanvasData() {
    // テンプレートの場合はスキップ（canvas_data endpoint がない）
    if (!this.roomIdValue) {
      this.seats = []
      this.room = {}
      this.drawings = []
      this.draw()
      return
    }

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
    // ルームの場合のみ ActionCable を設定（テンプレートは不要）
    if (!this.roomIdValue) return

    import("channels/rooms_channel").then(async module => {
      await module.subscribeToRoom(this.roomIdValue, {
        onUpdate: (data) => {
          if (data.type === "seat_updated") {
            this.mergeSeat(data.seat)
          } else if (data.type === "seat_removed") {
            this.removeSeatById(data.seat_id)
          }
        }
      })
    })
  }

  draw() {
    this.ctx.fillStyle = "#ffffff"
    this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height)

    this.drawGrid()
    this.drawShapes()
    this.drawPolygonPreview()
    this.drawSeats()
  }

  drawPolygonPreview() {
    const mode = window.currentEditMode || 'select'
    if (mode !== 'polygon' || this.polygonPoints.length === 0) return

    // ポリゴンの点をプレビュー表示
    this.ctx.strokeStyle = "#fbbf24"
    this.ctx.lineWidth = 2
    this.ctx.setLineDash([5, 5])

    if (this.polygonPoints.length > 1) {
      this.ctx.beginPath()
      this.ctx.moveTo(this.polygonPoints[0].x, this.polygonPoints[0].y)
      for (let i = 1; i < this.polygonPoints.length; i++) {
        this.ctx.lineTo(this.polygonPoints[i].x, this.polygonPoints[i].y)
      }
      this.ctx.stroke()
    }

    // 点を描画
    this.ctx.fillStyle = "#fbbf24"
    this.polygonPoints.forEach(point => {
      this.ctx.beginPath()
      this.ctx.arc(point.x, point.y, 4, 0, Math.PI * 2)
      this.ctx.fill()
    })

    this.ctx.setLineDash([])
  }

  drawShapes() {
    this.drawings.forEach(drawing => {
      if (drawing.type === "rectangle") {
        this.ctx.strokeStyle = drawing.color
        this.ctx.lineWidth = drawing.lineWidth
        if (drawing.filled && drawing.fillColor) {
          this.ctx.fillStyle = drawing.fillColor
          this.ctx.fillRect(drawing.x, drawing.y, drawing.width, drawing.height)
        }
        this.ctx.strokeRect(drawing.x, drawing.y, drawing.width, drawing.height)
      } else if (drawing.type === "line") {
        this.ctx.strokeStyle = drawing.color
        this.ctx.lineWidth = drawing.lineWidth
        this.ctx.beginPath()
        this.ctx.moveTo(drawing.x1, drawing.y1)
        this.ctx.lineTo(drawing.x2, drawing.y2)
        this.ctx.stroke()
      } else if (drawing.type === "circle") {
        this.ctx.strokeStyle = drawing.color
        this.ctx.lineWidth = drawing.lineWidth
        if (drawing.filled && drawing.fillColor) {
          this.ctx.fillStyle = drawing.fillColor
          this.ctx.beginPath()
          this.ctx.arc(drawing.cx, drawing.cy, drawing.radius, 0, Math.PI * 2)
          this.ctx.fill()
        }
        this.ctx.beginPath()
        this.ctx.arc(drawing.cx, drawing.cy, drawing.radius, 0, Math.PI * 2)
        this.ctx.stroke()
      } else if (drawing.type === "arrow") {
        this.ctx.strokeStyle = drawing.color
        this.ctx.lineWidth = drawing.lineWidth
        this.ctx.beginPath()
        this.ctx.moveTo(drawing.x1, drawing.y1)
        this.ctx.lineTo(drawing.x2, drawing.y2)
        this.ctx.stroke()
        this.drawArrowHead(drawing.x1, drawing.y1, drawing.x2, drawing.y2, drawing.color)
      } else if (drawing.type === "text") {
        this.ctx.fillStyle = drawing.color
        this.ctx.font = `${drawing.fontSize}px ${drawing.fontFamily}`
        this.ctx.textAlign = "left"
        this.ctx.textBaseline = "top"
        this.ctx.fillText(drawing.text, drawing.x, drawing.y)
      } else if (drawing.type === "polygon") {
        if (drawing.points && drawing.points.length > 0) {
          this.ctx.strokeStyle = drawing.color
          this.ctx.lineWidth = drawing.lineWidth
          if (drawing.filled && drawing.fillColor) {
            this.ctx.fillStyle = drawing.fillColor
            this.ctx.beginPath()
            this.ctx.moveTo(drawing.points[0].x, drawing.points[0].y)
            for (let i = 1; i < drawing.points.length; i++) {
              this.ctx.lineTo(drawing.points[i].x, drawing.points[i].y)
            }
            this.ctx.closePath()
            this.ctx.fill()
          }
          this.ctx.beginPath()
          this.ctx.moveTo(drawing.points[0].x, drawing.points[0].y)
          for (let i = 1; i < drawing.points.length; i++) {
            this.ctx.lineTo(drawing.points[i].x, drawing.points[i].y)
          }
          this.ctx.closePath()
          this.ctx.stroke()
        }
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

  csrfToken() {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    return token || ""
  }
}
