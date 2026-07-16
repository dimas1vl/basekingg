import { cn } from '@/lib/utils'
import { CheckIcon, UncheckIcon } from '@/components/icons'

type CheckProps = {
  checked?: boolean
  className?: string
}

export function Check({ checked = false, className }: CheckProps) {
  return (
    <div className={cn('relative h-[2rem] w-[4rem] shrink-0', className)}>
      {checked ? (
        <CheckIcon
          className="absolute left-0 top-[-0.5rem] text-[#c8fe4e]"
          width={40}
          height={27}
        />
      ) : (
        <UncheckIcon className="absolute left-0 top-0 text-white" width={40} height={20} />
      )}
    </div>
  )
}
