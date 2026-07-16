/** @type {import('tailwindcss').Config} */

export default {
  content: [
    './index.html',
    './src/**/*.{js,ts,jsx,tsx}',
    // Inventario NUI module bundled via @inventario alias — must be scanned so
    // Tailwind JIT keeps the classes it uses (otherwise the inventory page
    // renders without styles).
    '../../lobby_inventory/web/src/**/*.{js,ts,jsx,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        primary: 'hsl(var(--primary-color))',
      },
      textColor: {
        secondary: '#151515',
      },
      backgroundImage: {
        modal: 'linear-gradient(180deg, rgba(21, 21, 21, 0.98) 0%, rgba(14, 14, 14, 0.98) 100%)',
      },
      fontFamily: {
        inter: ['Inter', 'sans-serif'],
        poppins: ['Poppins', 'sans-serif'],
        termina: ['termina', 'sans-serif'],
      },
      dropShadow: {
        lg: '0 0 1rem hsl(var(--primary-color) / .4)',
      },
    },
  },
  plugins: [require('tailwindcss-animate')],
}
