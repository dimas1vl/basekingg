import { cn } from '@/lib/utils'
import { SearchIcon } from '@/components/icons'

type SearchInputProps = {
  placeholder?: string
  value?: string
  onChange?: (value: string) => void
  onKeyDown?: (e: React.KeyboardEvent<HTMLInputElement>) => void
  focused?: boolean
  className?: string
}

export function SearchInput({
  placeholder = 'PESQUISAR AMIGOS',
  value,
  onChange,
  onKeyDown,
  focused = false,
  className,
}: SearchInputProps) {
  return (
    <div
      className={cn(
        'flex items-center gap-[1rem] h-[4.2rem] border border-solid overflow-hidden px-[1.2rem] w-[37.4rem]',
        focused ? 'border-[#9d0de9]' : 'border-[rgba(248,239,255,0.25)]',
        className,
      )}
    >
      <input
        type="text"
        value={value}
        onChange={(e) => onChange?.(e.target.value)}
        onKeyDown={onKeyDown}
        placeholder={placeholder}
        className={cn(
          'flex-1 min-w-0 bg-transparent outline-none font-["Termina",sans-serif] text-[1.2rem] font-medium text-center',
          focused
            ? 'text-[#f8efff] placeholder:text-[#f8efff]'
            : 'text-[rgba(248,239,255,0.55)] placeholder:text-[rgba(248,239,255,0.55)]',
        )}
      />
      <SearchIcon
        width={18}
        height={18}
        className="shrink-0"
        style={{ color: focused ? '#9d0de9' : '#f8efff', fillOpacity: 1 }}
      />
    </div>
  )
}
