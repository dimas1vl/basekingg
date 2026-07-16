import { useState } from 'react'
import { cn } from '@/lib/utils'
import { Check } from './check'

type PreencherProps = {
  label?: string
  defaultChecked?: boolean
  onChange?: (checked: boolean) => void
  className?: string
}

export function Preencher({
  label = 'PREENCHER',
  defaultChecked = false,
  onChange,
  className,
}: PreencherProps) {
  const [checked, setChecked] = useState(defaultChecked)

  const handleClick = () => {
    const next = !checked
    setChecked(next)
    onChange?.(next)
  }

  return (
    <div
      className={cn(
        'relative flex items-center justify-between border-solid border-t-2 border-r-2 border-b-2 border-l-8 bg-[rgba(248,239,255,0.1)] pl-[1.6rem] pr-[1.2rem] py-[1.2rem] w-full cursor-pointer',
        className
      )}
      style={{ borderColor: checked ? '#c8fe4e' : 'rgba(248,239,255,0.1)' }}
      onClick={handleClick}
    >
      <span
        className={cn(
          'text-[1.6rem] font-medium whitespace-nowrap',
          checked ? 'text-[#c8fe4e]' : 'text-white'
        )}
      >
        {label}
      </span>

      <Check
        checked={checked}
        className={cn(!checked && 'opacity-35')}
      />
    </div>
  )
}
