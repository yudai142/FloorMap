import React from 'react'
import { createRoot } from 'react-dom/client'
import '../styles/application.css'

const App = () => {
  return (
    <div className="flex items-center justify-center min-h-screen bg-gray-100">
      <div className="bg-white p-8 rounded-lg shadow-lg">
        <h1 className="text-3xl font-bold text-center mb-4">FloorMap</h1>
        <p className="text-gray-600 text-center">React + Vite + Tailwind CSS が正常に動作しています</p>
      </div>
    </div>
  )
}

const container = document.getElementById('root')
if (container) {
  const root = createRoot(container)
  root.render(<App />)
}
