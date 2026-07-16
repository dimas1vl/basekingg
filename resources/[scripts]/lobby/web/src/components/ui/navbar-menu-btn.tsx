import { useEffect, useState } from 'react'
import { cn } from '@/lib/utils'
import { SlashesIcon } from '@/components/icons'

const NAVBAR_MENU_IMG = new URL('/navbar-menu.png', import.meta.url).href
const ORNAMENT_IMG = new URL('/ornament-navbar-btn.png', import.meta.url).href

type NavbarMenuBtnProps = {
  label: string
  state?: 'default' | 'active'
  gold?: boolean
  onClick?: () => void
  className?: string
}

export function NavbarMenuBtn({
  label,
  state = 'default',
  gold = false,
  onClick,
  className,
}: NavbarMenuBtnProps) {
  const [hovered, setHovered] = useState(false)

  const isActive = state === 'active'
  const borderColor = gold ? '#fedb4e' : '#f8efff'
  const activeBorderColor = gold ? '#fff0b5' : '#e8ffb5'
  const activeBgColor = gold ? '#fedb4e' : '#c8fe4e'

  useEffect(() => {
    if (isActive) setHovered(false)
  }, [isActive])

  if (isActive) {
    return (
      <div className={cn('relative flex h-[4rem] items-start', className)}>
        <div
          className="absolute inset-0 border-solid border-t-2 border-r-2 border-b-2 border-l-8"
          style={{ borderColor: activeBorderColor }}
        >
          <div className="absolute inset-0" style={{ backgroundColor: activeBgColor }} />
          <img
            alt=""
            className="absolute inset-0 size-full max-w-none object-cover opacity-15 pointer-events-none"
            src={NAVBAR_MENU_IMG}
          />
          <img
            alt=""
            className="absolute inset-0 size-full object-cover pointer-events-none"
            src={ORNAMENT_IMG}
          />
        </div>
        <div className="relative flex h-[4rem] items-center gap-[1rem] pl-[1.6rem] pr-[1.2rem]">
          <SlashesIcon width={30} height={12} className="shrink-0 text-[#1d1c26]" />
          <span className="text-[1.6rem] font-medium text-[#1d1c26] whitespace-nowrap">
            {label}
          </span>
        </div>
      </div>
    )
  }

  return (
    <div
      className={cn('relative flex h-[4rem] items-center cursor-pointer', className)}
      onClick={onClick}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
    >
      {/* Borda */}
      <div
        className="absolute inset-0 border-solid border-t-2 border-r-2 border-b-2 border-l-8 transition-[opacity,background-color] duration-200"
        style={{
          borderColor,
          opacity: hovered ? 1 : 0,
          backgroundColor: hovered ? 'rgba(248,239,255,0.1)' : 'transparent',
        }}
      />

      {/* Slash — sempre ocupa espaço (w-[4.6rem] fixo), aparece no hover */}
      <div className="w-[4.6rem] shrink-0 flex items-center">
        <SlashesIcon
          width={30}
          height={12}
          className="ml-[1.6rem] shrink-0 transition-[opacity,transform] duration-200"
          style={{
            color: borderColor,
            opacity: hovered ? 1 : 0,
            transform: hovered ? 'translateX(0)' : 'translateX(-6px)',
          }}
        />
      </div>

      {/* Label — sem hover desliza -2.3rem (metade do slash) para parecer centrado */}
      <div
        className="relative px-[1.2rem] transition-transform duration-200"
        style={{ transform: hovered ? 'translateX(0)' : 'translateX(-2.3rem)' }}
      >
        {gold ? (
          <span
            className="text-[1.6rem] font-medium whitespace-nowrap"
            style={{
              background: 'linear-gradient(180deg, #fff1ba 0%, #fedb4e 100%)',
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
              backgroundClip: 'text',
            }}
          >
            {label}
          </span>
        ) : (
          <span className="text-[1.6rem] font-medium text-[#f8efff] whitespace-nowrap">
            {label}
          </span>
        )}
      </div>
    </div>
  )
}
