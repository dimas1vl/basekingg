import { useState } from 'react'
import { cn } from '@/lib/utils'

const BTN_IMG = new URL('/button-hero.png', import.meta.url).href
const BTN_HOVER_IMG = new URL('/button-hero-hover.png', import.meta.url).href

type ButtonHeroProps = {
  label?: string
  onClick?: () => void
  className?: string
  disabled?: boolean
}

export function ButtonHero({ label = 'JOGAR', onClick, className, disabled }: ButtonHeroProps) {
  const [hovered, setHovered] = useState(false)

  return (
    <button
      onClick={disabled ? undefined : onClick}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      className={cn('relative w-full cursor-pointer', disabled && 'opacity-40 cursor-not-allowed', className)}
    >
      <img
        src={hovered ? BTN_HOVER_IMG : BTN_IMG}
        alt=""
        className="block w-full pointer-events-none"
      />
      <span
        className={cn(
          'absolute inset-0 flex items-center justify-center font-bold text-[4rem] transition-colors duration-200',
          hovered ? 'text-[#343d20]' : 'text-[#c8fe4e]'
        )}
      >
        {label}
      </span>
    </button>
  )
}
