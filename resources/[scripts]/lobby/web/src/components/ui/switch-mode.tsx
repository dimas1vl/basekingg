import { useState } from 'react'
import { cn } from '@/lib/utils'

const SWITCH_IMG = new URL('/switch-mode.png', import.meta.url).href
const SWITCH_HOVER_IMG = new URL('/switch-mode-hover.png', import.meta.url).href

type SwitchModeProps = {
  label?: string
  hoverLabel?: string
  onClick?: () => void
  className?: string
}

export function SwitchMode({
  label = 'BATTLE ROYALE / COMPETITIVO',
  hoverLabel = 'ALTERAR MODO',
  onClick,
  className,
}: SwitchModeProps) {
  const [hovered, setHovered] = useState(false)

  return (
    <div
      className={cn(
        'relative flex h-[5.6rem] w-full overflow-hidden cursor-pointer border-none',
        className,
      )}
      onClick={onClick}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
    >
      <div
        className={cn(
          'absolute inset-0 flex items-center px-[1.8rem] py-[1.2rem] bg-[#9d0de9] transition-transform duration-300 ease-in-out',
          hovered ? '-translate-x-full' : 'translate-x-0',
        )}
      >
        <img
          alt=""
          className="absolute h-[77.6rem] w-[57.7rem] pointer-events-none"
          src={SWITCH_IMG}
        />
        <div className="relative flex flex-1 h-full min-w-0 items-center px-[0.8rem] py-[0.4rem] bg-[rgba(29,28,38,0.55)]">
          <span className="text-[1.6rem] font-bold text-[#f8efff] truncate">{label}</span>
        </div>
      </div>

      {/* Camada hover — entra pela direita no hover */}
      <div
        className={cn(
          'absolute inset-0 flex items-center px-[1.8rem] py-[1.2rem] bg-[#f8efff] transition-transform duration-300 ease-in-out',
          hovered ? 'translate-x-0' : 'translate-x-full',
        )}
      >
        <img
          alt=""
          className="absolute h-[77.6rem] w-[57.7rem] pointer-events-none"
          src={SWITCH_HOVER_IMG}
        />
        <div className="relative flex flex-1 h-full min-w-0 items-center px-[0.8rem] py-[0.4rem] bg-[rgba(255,255,255,0.75)]">
          <span className="text-[1.6rem] font-bold text-[#1d1c26] truncate">{hoverLabel}</span>
        </div>
      </div>
    </div>
  )
}
