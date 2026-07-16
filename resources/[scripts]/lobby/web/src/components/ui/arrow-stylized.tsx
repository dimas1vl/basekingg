import { cn } from '@/lib/utils'
import { ArrowStylizedLeftIcon, ArrowStylizedRightIcon } from '@/components/icons'

type ArrowStylizedProps = {
  direction?: 'left' | 'right'
  variant?: 'default' | 'active'
  onClick?: () => void
  className?: string
}

export function ArrowStylized({
  direction = 'left',
  variant = 'default',
  onClick,
  className,
}: ArrowStylizedProps) {
  const isActive = variant === 'active'
  const Icon = direction === 'left' ? ArrowStylizedLeftIcon : ArrowStylizedRightIcon

  return (
    <button
      onClick={onClick}
      className={cn(
        'relative flex items-center justify-center overflow-hidden cursor-pointer h-[5.3rem]',
        isActive
          ? 'bg-[#c8fe4e] border-2 border-[rgba(248,239,255,0.55)] border-solid w-[5rem]'
          : 'bg-[#f8efff] w-[4.4rem]',
        className,
      )}
    >
      <Icon width={24} height={27} className="text-[#1d1c26] shrink-0" />
    </button>
  )
}
