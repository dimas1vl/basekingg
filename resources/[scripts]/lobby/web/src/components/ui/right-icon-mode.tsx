import { cn } from '@/lib/utils'
import { ArrowRightIcon } from '@/components/icons'

type RightIconModeProps = {
  variant?: 'default' | 'active'
  onClick?: () => void
  className?: string
}

export function RightIconMode({ variant = 'default', onClick, className }: RightIconModeProps) {
  const isActive = variant === 'active'

  return (
    <button
      onClick={onClick}
      className={cn(
        'flex items-center p-[0.4rem] border-2 border-[rgba(248,239,255,0.55)] border-solid cursor-pointer',
        isActive ? 'bg-[#c8fe4e]' : 'bg-[#e9beff]',
        className,
      )}
    >
      <ArrowRightIcon width={24} height={24} className="text-[#1d1c26]" />
    </button>
  )
}
