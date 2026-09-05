import '../styles/application.css'
import { createInertiaApp } from '@inertiajs/react'
import { createRoot } from 'react-dom/client'
import Layout from '../components/Layout'

import Home from '../Pages/Home'
import RoomsIndex from '../Pages/Rooms/Index'
import RoomsNew from '../Pages/Rooms/New'
import RoomsShow from '../Pages/Rooms/Show'
import RoomsCanvasEditor from '../Pages/Rooms/CanvasEditor'

const pageMap = {
  'Home': Home,
  'Rooms/Index': RoomsIndex,
  'Rooms/New': RoomsNew,
  'Rooms/Show': RoomsShow,
  'Rooms/CanvasEditor': RoomsCanvasEditor,
}

createInertiaApp({
  resolve: name => {
    console.log('Resolving page:', name, 'Available:', Object.keys(pageMap))
    const component = pageMap[name]
    if (!component) {
      throw new Error(`Page not found: ${name}`)
    }
    return component
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
