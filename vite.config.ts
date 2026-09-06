import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [
    RubyPlugin({ skipCompatibilityCheck: true, port: 5173, autoBuild: false }),
    react(),
  ],
  server: {
    host: '0.0.0.0',
    port: 5173,
    hmr: {
      protocol: 'ws',
      host: 'localhost',
      port: process.env.VITE_HMR_PORT ? parseInt(process.env.VITE_HMR_PORT) : 5173,
    },
  },
  build: {
    rollupOptions: {
      output: {
        entryFileNames: '[name].js',
        chunkFileNames: '[name]-[hash].js',
        assetFileNames: '[name]-[hash][extname]',
      },
    },
  },
  css: {
    postcss: path.resolve(__dirname, 'postcss.config.cjs'),
  },
})
