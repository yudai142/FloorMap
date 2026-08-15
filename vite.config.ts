import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [
    RubyPlugin({ skipCompatibilityCheck: true }),
    react(),
  ],
  server: {
    middlewareMode: true,
    hmr: {
      host: 'localhost',
      port: 5173,
      protocol: 'ws',
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
    postcss: process.env.NODE_ENV === 'development' ? false : path.resolve(__dirname, 'postcss.config.cjs'),
  },
})
