/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './app/**/*.{rb,erb,js,jsx,ts,tsx}',
    './app/frontend/**/*.{js,jsx,ts,tsx}',
    './app/views/**/*.erb',
  ],
  theme: {
    extend: {
      colors: {
        primary: '#3b82f6',
        success: '#10b981',
        error: '#ef4444',
        background: '#f8fafc',
        text: '#0f172a',
      },
      fontFamily: {
        geist: ['Geist', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
