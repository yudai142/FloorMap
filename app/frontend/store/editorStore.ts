import { create } from 'zustand'
import { immer } from 'zustand/middleware/immer'
import type { EditorState, Seat, Shape, SelectedElement, HistoryEntry } from '../types/Canvas'

const initialState: Omit<EditorState, keyof typeof editorStore> = {
  shapes: [],
  seats: [],
  selectedElements: [],
  currentTool: 'seat',
  drawMode: 'click',
  selectedColor: '#3b82f6',
  zoom: 1,
  showGrid: true,
  hasUnsavedChanges: false,
  history: [],
  historyIndex: -1,
  isDrawing: false,
  polygonPoints: [],
}

export const useEditorStore = create<EditorState>()(
  immer((set) => ({
    ...initialState,

    // Tool & UI State
    setCurrentTool: (tool) =>
      set((state) => {
        state.currentTool = tool
      }),
    setDrawMode: (mode) =>
      set((state) => {
        state.drawMode = mode
      }),
    setSelectedColor: (color) =>
      set((state) => {
        state.selectedColor = color
      }),
    setZoom: (zoom) =>
      set((state) => {
        state.zoom = Math.max(0.1, Math.min(zoom, 3))
      }),
    setShowGrid: (show) =>
      set((state) => {
        state.showGrid = show
      }),

    // Shape operations
    addShape: (shape) =>
      set((state) => {
        state.shapes.push(shape)
        state.hasUnsavedChanges = true
      }),
    updateShape: (id, updates) =>
      set((state) => {
        const shape = state.shapes.find((s) => s.id === id)
        if (shape) {
          Object.assign(shape, updates)
          state.hasUnsavedChanges = true
        }
      }),
    deleteShape: (id) =>
      set((state) => {
        state.shapes = state.shapes.filter((s) => s.id !== id)
        state.selectedElements = state.selectedElements.filter((el) => !(el.type === 'shape' && el.id === id))
        state.hasUnsavedChanges = true
      }),
    setShapes: (shapes) =>
      set((state) => {
        state.shapes = shapes
      }),

    // Seat operations
    setSeats: (seats) =>
      set((state) => {
        state.seats = seats
      }),
    mergeSeat: (seat) =>
      set((state) => {
        const index = state.seats.findIndex((s) => s.id === seat.id)
        if (index !== -1) {
          state.seats[index] = seat
        } else {
          state.seats.push(seat)
        }
      }),
    removeSeat: (seatId) =>
      set((state) => {
        state.seats = state.seats.filter((s) => s.id !== seatId)
        state.selectedElements = state.selectedElements.filter((el) => !(el.type === 'seat' && el.id === seatId))
      }),

    // Selection
    setSelectedElements: (elements) =>
      set((state) => {
        state.selectedElements = elements
      }),
    addToSelection: (element) =>
      set((state) => {
        if (!state.selectedElements.find((el) => el.type === element.type && el.id === element.id)) {
          state.selectedElements.push(element)
        }
      }),
    clearSelection: () =>
      set((state) => {
        state.selectedElements = []
      }),

    // History
    saveToHistory: (seats, shapes) =>
      set((state) => {
        const newHistory = state.history.slice(0, state.historyIndex + 1)
        newHistory.push({ seats: JSON.parse(JSON.stringify(seats)), shapes: JSON.parse(JSON.stringify(shapes)) })
        state.history = newHistory
        state.historyIndex = newHistory.length - 1
      }),
    undo: () =>
      set((state) => {
        if (state.historyIndex > 0) {
          const newIndex = state.historyIndex - 1
          const { seats, shapes } = state.history[newIndex]
          state.seats = JSON.parse(JSON.stringify(seats))
          state.shapes = JSON.parse(JSON.stringify(shapes))
          state.historyIndex = newIndex
        }
      }),
    redo: () =>
      set((state) => {
        if (state.historyIndex < state.history.length - 1) {
          const newIndex = state.historyIndex + 1
          const { seats, shapes } = state.history[newIndex]
          state.seats = JSON.parse(JSON.stringify(seats))
          state.shapes = JSON.parse(JSON.stringify(shapes))
          state.historyIndex = newIndex
        }
      }),

    // Drawing state
    setDrawingStart: (point) =>
      set((state) => {
        state.drawingStart = point
      }),
    setPreview: (preview) =>
      set((state) => {
        state.preview = preview
      }),
    setDragging: (dragging) =>
      set((state) => {
        state.dragging = dragging
      }),
    setSelectionBox: (box) =>
      set((state) => {
        state.selectionBox = box
      }),
    setPolygonPoints: (points) =>
      set((state) => {
        state.polygonPoints = points
      }),
    setTextInput: (input) =>
      set((state) => {
        state.textInput = input
      }),

    // Batch operations
    saveChanges: () =>
      set((state) => {
        state.hasUnsavedChanges = false
      }),
    reset: () =>
      set(() => ({
        ...initialState,
      })),
  }))
)
