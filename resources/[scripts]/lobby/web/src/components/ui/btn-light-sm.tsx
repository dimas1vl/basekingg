import { cn } from '@/lib/utils'

type BtnLightSmProps = {
  children: React.ReactNode
  variant?: 'purple' | 'primary'
  onClick?: () => void
  className?: string
}

export function BtnLightSm({ children, variant = 'purple', onClick, className }: BtnLightSmProps) {
  const isPrimary = variant === 'primary'

  return (
    <button
      onClick={onClick}
      className={cn(
        'flex h-[3.2rem] items-center px-[1.2rem] py-[0.4rem] border-2 border-[rgba(248,239,255,0.55)] border-solid cursor-pointer',
        isPrimary ? 'bg-[#c8fe4e]' : 'bg-[#e9beff]',
        className,
      )}
    >
      <span className="font-['Termina',sans-serif] text-[1.4rem] font-semibold text-[#1d1c26] whitespace-nowrap">
        {children}
      </span>
    </button>
  )
}
