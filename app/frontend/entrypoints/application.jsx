import '../styles/application.css'
import { createInertiaApp } from '@inertiajs/react'
import { createRoot } from 'react-dom/client'
import Layout from '../components/Layout'

// Stimulus
import { Application } from '@hotwired/stimulus'

// Initialize Stimulus manually for Vite environment
const app = Application.start()

// Dynamically load Stimulus controllers
const controllerModules = import.meta.glob('../../javascript/controllers/**/*_controller.js', { eager: true })
for (const [path, module] of Object.entries(controllerModules)) {
  const matches = path.match(/\/(\w+)_controller\.js$/)
  if (matches) {
    const controllerName = matches[1]
    app.register(controllerName, module.default)
  }
}

// Disable HMR completely
if (import.meta.hot) {
  import.meta.hot.dispose?.(() => {})
  try {
    Object.defineProperty(import.meta, 'hot', { value: null })
  } catch (e) {
    // ignore if hot is not writable
  }
}
globalThis.__VITE_HMR__ = false

// Suppress WebSocket and HMR-related console errors
const originalError = console.error
const originalWarn = console.warn
const shouldSuppressMessage = (message) => {
  const msg = String(message).toLowerCase()
  return msg.includes('websocket') || msg.includes('upgrade') || msg.includes('hmr') ||
         msg.includes('vite') || msg.includes('err_connection_refused')
}

console.error = function(...args) {
  if (!shouldSuppressMessage(args.join(' '))) {
    originalError.apply(console, args)
  }
}

console.warn = function(...args) {
  if (!shouldSuppressMessage(args.join(' '))) {
    originalWarn.apply(console, args)
  }
}

import Home from '../Pages/Home'
import RoomsIndex from '../Pages/Rooms/Index'
import RoomsNew from '../Pages/Rooms/New'
import RoomsShow from '../Pages/Rooms/Show'
import RoomsCanvasEditor from '../Pages/Rooms/CanvasEditor'
import FloorPlanTemplatesIndex from '../Pages/FloorPlanTemplates/Index'
import FloorPlanTemplatesNew from '../Pages/FloorPlanTemplates/New'
import FloorPlanTemplatesShow from '../Pages/FloorPlanTemplates/Show'
import FloorPlanTemplatesCanvasEditor from '../Pages/FloorPlanTemplates/CanvasEditor'
import FloorPlanTemplatesDetails from '../Pages/FloorPlanTemplates/Details'

const pageMap = {
  'Home': Home,
  'Rooms/Index': RoomsIndex,
  'Rooms/New': RoomsNew,
  'Rooms/Show': RoomsShow,
  'Rooms/CanvasEditor': RoomsCanvasEditor,
  'FloorPlanTemplates/Index': FloorPlanTemplatesIndex,
  'FloorPlanTemplates/New': FloorPlanTemplatesNew,
  'FloorPlanTemplates/Show': FloorPlanTemplatesShow,
  'FloorPlanTemplates/CanvasEditor': FloorPlanTemplatesCanvasEditor,
  'FloorPlanTemplates/Details': FloorPlanTemplatesDetails,
}

createInertiaApp({
  resolve: async name => {
    const component = pageMap[name]
    if (!component) {
      // ERB テンプレート（component が無い）の場合は null を返して Inertia を初期化しない
      return null
    }
    return { default: component }
  },
  setup({ el, App, props }) {
    // component が無い場合（ERB テンプレート）はスキップ
    if (!App) {
      console.log('[Inertia] Skipping Inertia setup for ERB template')
      return
    }

    const root = createRoot(el)
    const auth = props.initialPage?.props?.auth || {}

    root.render(
      <Layout auth={auth}>
        <App {...props} />
      </Layout>
    )
  },
})
