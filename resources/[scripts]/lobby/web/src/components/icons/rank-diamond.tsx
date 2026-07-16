import { SVGProps, useId } from 'react'

/** Losango do rank (Figma: rank OURO — gradiente dourado com borda clara). */
export function RankDiamondIcon(props: SVGProps<SVGSVGElement>) {
  const id = useId()
  return (
    <svg width="56" height="56" viewBox="0 0 56 56" fill="none" xmlns="http://www.w3.org/2000/svg" {...props}>
      <rect
        x="28"
        y="0.5"
        width="39.598"
        height="39.598"
        transform="rotate(45 28 0.5)"
        fill={`url(#${id})`}
      />
      <rect
        x="28"
        y="4.74264"
        width="33.598"
        height="33.598"
        transform="rotate(45 28 4.74264)"
        stroke="white"
        strokeOpacity="0.37"
        strokeWidth="6"
      />
      <defs>
        <linearGradient id={id} x1="28" y1="0.5" x2="67.598" y2="40.098" gradientUnits="userSpaceOnUse">
          <stop stopColor="#FEC64E" />
          <stop offset="1" stopColor="#FEDE96" />
        </linearGradient>
      </defs>
    </svg>
  )
}
