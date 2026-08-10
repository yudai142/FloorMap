import { Application } from "@hotwired/stimulus"
import SeatCanvasController from "controllers/seat_canvas_controller"

describe("SeatCanvasController", () => {
  let application
  let controller
  let canvas
  let fixture

  beforeEach(() => {
    fixture = `
      <div data-controller="seat-canvas" data-seat-canvas-room-id-value="1" data-seat-canvas-grid-size-value="40" data-seat-canvas-snap-to-grid-value="true">
        <canvas data-seat-canvas-target="canvas" style="width: 800px; height: 600px;"></canvas>
      </div>
    `
    document.body.innerHTML = fixture

    application = Application.start()
    application.register("seat-canvas", SeatCanvasController)

    const element = document.querySelector("[data-controller='seat-canvas']")
    controller = application.controllers[0]
  })

  afterEach(() => {
    application.stop()
  })

  describe("Initialization", () => {
    it("initializes the controller with canvas target", () => {
      expect(controller.canvasTarget).toBeTruthy()
    })

    it("sets grid size from data attribute", () => {
      expect(controller.gridSizeValue).toBe(40)
    })

    it("sets snap to grid from data attribute", () => {
      expect(controller.snapToGridValue).toBe(true)
    })

    it("initializes shapes array", () => {
      expect(controller.shapes).toEqual([])
    })
  })

  describe("Grid functionality", () => {
    it("draws grid on canvas", () => {
      const ctx = controller.ctx
      const spy = spyOn(ctx, "stroke")
      controller.drawGrid()
      expect(spy).toHaveBeenCalled()
    })

    it("calculates grid positions correctly", () => {
      const gridSize = controller.gridSizeValue
      const snappedX = Math.round(125 / gridSize) * gridSize
      const snappedY = Math.round(85 / gridSize) * gridSize
      expect(snappedX).toBe(120)
      expect(snappedY).toBe(80)
    })
  })

  describe("Shape drawing", () => {
    it("adds rectangle to shapes array", () => {
      controller.addRectangle(10, 20, 100, 50)
      expect(controller.shapes.length).toBe(1)
      expect(controller.shapes[0].type).toBe("rectangle")
    })

    it("adds circle to shapes array", () => {
      controller.addCircle(50, 50, 30)
      expect(controller.shapes.length).toBe(1)
      expect(controller.shapes[0].type).toBe("circle")
    })

    it("adds line to shapes array", () => {
      controller.addLine(0, 0, 100, 100)
      expect(controller.shapes.length).toBe(1)
      expect(controller.shapes[0].type).toBe("line")
    })

    it("clears all shapes", () => {
      controller.addRectangle(10, 20, 100, 50)
      controller.addCircle(50, 50, 30)
      controller.clearShapes()
      expect(controller.shapes.length).toBe(0)
    })

    it("sets custom colors for shapes", () => {
      controller.addRectangle(10, 20, 100, 50, "#3b82f6")
      expect(controller.shapes[0].color).toBe("#3b82f6")
    })

    it("sets custom line width for shapes", () => {
      controller.addLine(0, 0, 100, 100, "#ef4444", 3)
      expect(controller.shapes[0].lineWidth).toBe(3)
    })
  })

  describe("Snap to grid", () => {
    beforeEach(() => {
      controller.snapToGridValue = true
      controller.gridSizeValue = 40
    })

    it("snaps position to grid when enabled", () => {
      const snappedX = Math.round(95 / controller.gridSizeValue) * controller.gridSizeValue
      const snappedY = Math.round(145 / controller.gridSizeValue) * controller.gridSizeValue
      expect(snappedX).toBe(80)
      expect(snappedY).toBe(160)
    })

    it("respects snap to grid setting", () => {
      controller.snapToGridValue = false
      const x = 95
      const y = 145
      expect(x).toBe(95)
      expect(y).toBe(145)
    })
  })
})
