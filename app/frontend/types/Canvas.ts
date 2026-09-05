// Canvas and drawing types
export type ToolType = 'select' | 'seat' | 'line' | 'rectangle' | 'circle' | 'arrow' | 'text' | 'polygon' | 'delete'
export type DrawMode = 'click' | 'drag'
export type ShapeType = 'line' | 'rectangle' | 'circle' | 'arrow' | 'text' | 'polygon'

export interface Seat {
  id: number
  label: string
  x: number
  y: number
  occupied: boolean
  occupant_name?: string
  seat_type: string
}

export interface Shape {
  id: string
  type: ShapeType
  color: string
  // Line & Arrow
  x1?: number
  y1?: number
  x2?: number
  y2?: number
  // Rectangle
  x?: number
  y?: number
  width?: number
  height?: number
  // Circle
  cx?: number
  cy?: number
  r?: number
  // Text
  text?: string
  // Polygon
  points?: string
  pointsArray?: { x: number; y: number }[]
}

export interface Room {
  id: number
  name: string
  width: number
  height: number
  floor_plan_data?: Shape[]
}

export interface HistoryEntry {
  seats: Seat[]
  shapes: Shape[]
}

export interface EditorState {
  // Canvas Data
  shapes: Shape[]
  seats: Seat[]
  selectedElements: SelectedElement[]

  // UI State
  currentTool: ToolType
  drawMode: DrawMode
  selectedColor: string
  zoom: number
  showGrid: boolean
  hasUnsavedChanges: boolean

  // History
  history: HistoryEntry[]
  historyIndex: number

  // Drawing State
  isDrawing: boolean
  drawingStart?: { x: number; y: number }
  preview?: Partial<Shape>
  dragging?: { id: number; offsetX: number; offsetY: number }
  selectionBox?: { x: number; y: number; width: number; height: number }
  polygonPoints: { x: number; y: number }[]
  textInput?: { x: number; y: number; text: string }

  // Actions
  setCurrentTool: (tool: ToolType) => void
  setDrawMode: (mode: DrawMode) => void
  setSelectedColor: (color: string) => void
  setZoom: (zoom: number) => void
  setShowGrid: (show: boolean) => void

  // Shape operations
  addShape: (shape: Shape) => void
  updateShape: (id: string, updates: Partial<Shape>) => void
  deleteShape: (id: string) => void
  setShapes: (shapes: Shape[]) => void

  // Seat operations
  setSeats: (seats: Seat[]) => void
  mergeSeat: (seat: Seat) => void
  removeSeat: (seatId: number) => void

  // Selection
  setSelectedElements: (elements: SelectedElement[]) => void
  addToSelection: (element: SelectedElement) => void
  clearSelection: () => void

  // History
  undo: () => void
  redo: () => void
  saveToHistory: (seats: Seat[], shapes: Shape[]) => void

  // Drawing
  setDrawingStart: (point?: { x: number; y: number }) => void
  setPreview: (preview?: Partial<Shape>) => void
  setDragging: (dragging?: { id: number; offsetX: number; offsetY: number }) => void
  setSelectionBox: (box?: { x: number; y: number; width: number; height: number }) => void
  setPolygonPoints: (points: { x: number; y: number }[]) => void
  setTextInput: (input?: { x: number; y: number; text: string }) => void

  // Batch update
  saveChanges: () => void
  reset: () => void
}

export interface SelectedElement {
  type: 'seat' | 'shape'
  id: number | string
}

export interface ColorPreset {
  name: string
  value: string
}
