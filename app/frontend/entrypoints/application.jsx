import '../styles/application.css'
import { createInertiaApp } from '@inertiajs/react'
import { createRoot } from 'react-dom/client'
import Layout from '../components/Layout'

import Home from '../Pages/Home'
import RoomsIndex from '../Pages/Rooms/Index'
import RoomsNew from '../Pages/Rooms/New'
import RoomsShow from '../Pages/Rooms/Show'
import RoomsCanvasEditor from '../Pages/Rooms/CanvasEditor'

console.log('=== Inertia.js Initialization ===')
console.log('Home:', Home)
console.log('RoomsIndex:', RoomsIndex)
console.log('RoomsNew:', RoomsNew)
console.log('RoomsShow:', RoomsShow)
console.log('RoomsCanvasEditor:', RoomsCanvasEditor)
console.log('Layout:', Layout)

const pageMap = {
  'Home': Home,
  'Rooms/Index': RoomsIndex,
  'Rooms/New': RoomsNew,
  'Rooms/Show': RoomsShow,
  'Rooms/CanvasEditor': RoomsCanvasEditor,
}

createInertiaApp({
  resolve: async name => {
    console.log('Resolving page:', name)
    const component = pageMap[name]
    console.log('Component found:', !!component, 'Component:', component)
    if (!component) {
      console.error('Page not found:', name, 'Available:', Object.keys(pageMap))
      throw new Error(`Page not found: ${name}`)
    }
    return { default: component }
  },
  setup({ el, App, props }) {
    console.log('Setup called')
    console.log('App component:', App?.name || App?.displayName || 'unknown')

    try {
      const root = createRoot(el)
      const auth = props.initialPage?.props?.auth || {}

      root.render(
        <Layout auth={auth}>
          <App {...props} />
        </Layout>
      )
      console.log('Render successful')
    } catch (error) {
      console.error('Render error:', error)
      throw error
    }
  },
})
