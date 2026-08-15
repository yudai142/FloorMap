import '../styles/application.css'
import { createInertiaApp } from '@inertiajs/react'
import { createRoot } from 'react-dom/client'
import Layout from '../components/Layout'

createInertiaApp({
  resolve: name => {
    const pages = import.meta.glob('../Pages/*.jsx', { eager: true })
    return pages[`../Pages/${name}.jsx`]?.default
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
