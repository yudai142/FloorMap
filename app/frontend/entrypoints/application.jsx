import '../styles/application.css'
import { createInertiaApp } from '@inertiajs/react'
import { createRoot } from 'react-dom/client'
import Layout from '../components/Layout'

// Import pages directly
import Home from '../Pages/Home'
import RoomsNew from '../Pages/Rooms/New'
import RoomsCanvasEditor from '../Pages/Rooms/CanvasEditor'

const pages = {
  'Home': { default: Home },
  'Rooms/New': { default: RoomsNew },
  'Rooms/CanvasEditor': { default: RoomsCanvasEditor },
}

createInertiaApp({
  resolve: name => {
    console.log('Inertia resolve:', { name, available: Object.keys(pages) })
    return pages[name]?.default
  },
  setup({ el, App, props }) {
    const root = createRoot(el)
    root.render(
      <Layout auth={props.initialPage.props.auth}>
        <App {...props} />
      </Layout>
    )
  },
})
