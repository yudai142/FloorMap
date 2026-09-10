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
      animation: {
        'fade-in': 'fadeIn 0.3s ease-in',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0', transform: 'translateY(-10px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
      },
    },
  },
  plugins: [],
}
