import { cn } from '@/lib/utils'
import { ArrowRightIcon } from '@/components/icons'

type RightIconContainerProps = {
  variant?: 'default' | 'active'
  onClick?: () => void
  className?: string
}

export function RightIconContainer({
  variant = 'default',
  onClick,
  className,
}: RightIconContainerProps) {
  const isActive = variant === 'active'

  return (
    <button
      onClick={onClick}
      className={cn(
        'flex items-center p-[0.4rem] border-2 border-[rgba(255,255,255,0.25)] border-solid cursor-pointer',
        isActive ? 'bg-[#c8fe4e]' : 'bg-[#f8efff]',
        className,
      )}
    >
      <ArrowRightIcon width={24} height={24} className="text-[#1d1c26]" />
    </button>
  )
}
