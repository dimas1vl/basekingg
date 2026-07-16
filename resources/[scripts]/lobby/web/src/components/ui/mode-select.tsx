import { ReactNode, useState } from 'react'
import { cn } from '@/lib/utils'

type ModeSelectProps = {
  label: string
  icon?: ReactNode
  state?: 'default' | 'active' | 'inactive'
  premium?: boolean
  onClick?: () => void
  className?: string
}

export function ModeSelect({
  label,
  icon,
  state = 'default',
  premium = false,
  onClick,
  className,
}: ModeSelectProps) {
  const [hovered, setHovered] = useState(false)

  const isActive = state === 'active'
  const isInactive = state === 'inactive'
  const isHovered = hovered && !isActive && !isInactive

  const bg =
    isActive || isHovered
      ? 'bg-[#c8fe4e] border-[rgba(248,239,255,0.25)]'
      : isInactive
        ? 'bg-[rgba(248,239,255,0.05)] border-[rgba(248,239,255,0.05)]'
        : 'bg-[rgba(248,239,255,0.1)] border-[rgba(248,239,255,0.1)]'

  const textColor =
    isActive || isHovered
      ? 'text-[#1d1c26]'
      : isInactive
        ? 'text-[rgba(248,239,255,0.25)]'
        : 'text-[#f8efff]'

  const iconColor =
    isActive || isHovered
      ? 'text-[rgba(29,28,38,0.3)]'
      : isInactive
        ? 'text-[rgba(248,239,255,0.1)]'
        : 'text-[rgba(248,239,255,0.2)]'

  return (
    <div
      className={cn(
        'relative flex h-[5.6rem] w-[41rem] items-center justify-between border-2 border-solid px-[1.8rem] py-[1.2rem] transition-[background-color,border-color] duration-200',
        isInactive ? 'cursor-not-allowed pointer-events-none' : 'cursor-pointer',
        bg,
        className,
      )}
      onClick={onClick}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
    >
      <div className="flex flex-1 min-w-0 items-center px-[0.8rem] py-[0.4rem]">
        <span
          className={cn(
            'text-[1.6rem] font-bold whitespace-nowrap transition-colors duration-200',
            textColor,
          )}
        >
          {label}
        </span>
      </div>

      {icon && (
        <div
          className={cn(
            'absolute right-0 top-1/2 -translate-y-1/2 h-[5.6rem] w-[7.1rem] flex items-center justify-center overflow-hidden pointer-events-none transition-colors duration-200',
            iconColor,
          )}
        >
          {icon}
        </div>
      )}

      {premium && (
        <div className="absolute left-[2.3rem] top-[-1.7rem] flex h-[2.6rem] w-[8.4rem] items-center justify-center pointer-events-none">
          <div className="rotate-[2.75deg]">
            <div className="bg-[#9d0de9] border-2 border-[rgba(255,255,255,0.25)] border-solid flex items-center justify-center px-[0.4rem] py-[0.4rem]">
              <span className="text-[1.2rem] font-semibold text-[#f8efff] whitespace-nowrap">
                PREMIUM
              </span>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
