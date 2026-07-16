/** @type {import('tailwindcss').Config} */

export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: 'hsl(var(--primary-color))',
      },
      backgroundImage: {
        modal: 'linear-gradient(180deg, rgba(21, 21, 21, 0.98) 0%, rgba(14, 14, 14, 0.98) 100%)',
      },
      fontFamily: {
        inter: ['Inter', 'sans-serif'],
        poppins: ['Poppins', 'sans-serif'],
      },
      keyframes: {
        'toast-in': {
          '0%': { opacity: '0', transform: 'translateX(1.5rem)' },
          '100%': { opacity: '1', transform: 'translateX(0)' },
        },
      },
      animation: {
        'toast-in': 'toast-in 0.25s ease-out',
      },
    },
  },
  plugins: [require('tailwindcss-animate')],
}
