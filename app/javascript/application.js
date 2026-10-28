import '@hotwired/turbo-rails'
import './controllers'

// Initialize Stimulus controllers
import { Application } from '@hotwired/stimulus'

const application = Application.start()

// Load all controller files from controllers directory
const controllerNames = [
  'seat-canvas'
]

// Import controllers
import SeatCanvasController from './controllers/seat_canvas_controller'

// Register controllers
application.register('seat-canvas', SeatCanvasController)
