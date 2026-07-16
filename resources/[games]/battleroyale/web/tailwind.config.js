/** @type {import('tailwindcss').Config} */

export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: 'hsl(var(--primary-color))',
        light: 'hsl(var(--light-color) / <alpha-value>)',
        dark: 'hsl(var(--dark-color) / <alpha-value>)',
        accent: 'hsl(var(--accent-color) / <alpha-value>)',
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
        termina: ['Termina', 'Poppins', 'sans-serif'],
      },
      dropShadow: {
        lg: '0 0 1rem hsl(var(--primary-color) / .4)',
        accent: '0 0 0.6rem hsl(var(--accent-color) / .55)',
      },
    },
  },
  plugins: [require('tailwindcss-animate')],
}
