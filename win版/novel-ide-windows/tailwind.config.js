/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./src/renderer/src/**/*.{tsx,ts}', './src/renderer/index.html'],
  theme: {
    extend: {
      colors: {
        bg: {
          primary: '#1e1e1e',
          secondary: '#252526',
          tertiary: '#2d2d2d',
          hover: '#383838',
        },
        border: {
          DEFAULT: '#404040',
        },
        text: {
          primary: '#cccccc',
          secondary: '#969696',
          muted: '#666666',
        },
        accent: {
          DEFAULT: '#0078d4',
          hover: '#1a8ae8',
        },
      },
    },
  },
  plugins: [],
}
