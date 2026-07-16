import { ReactNode } from 'react'
import { cn } from '@/lib/utils'
import { SlashesIcon } from '@/components/icons'

/** Pílula clara usada para contadores (ex: "2/32", "12", "1/3"). */
export function CountTag({ children }: { children: ReactNode }) {
  return (
    <div className="flex items-center justify-center gap-[0.6rem] px-[1rem] py-[0.4rem] bg-[rgba(255,255,255,0.55)] border-2 border-[rgba(255,255,255,0.15)] border-solid backdrop-blur-[0.4rem]">
      <span className="text-[1.2rem] font-semibold text-[#1d1c26] text-center whitespace-nowrap">
        {children}
      </span>
    </div>
  )
}

type SectionHeaderProps = {
  title: string
  subtitle?: string
  tag?: ReactNode
  right?: ReactNode
  titleSize?: string
  className?: string
}

/** Cabeçalho padrão dos painéis do perfil. */
export function SectionHeader({
  title,
  subtitle,
  tag,
  right,
  titleSize = '1.6rem',
  className,
}: SectionHeaderProps) {
  return (
    <div
      className={cn(
        'flex h-[6.9rem] items-center justify-between px-[1.2rem] py-[0.8rem] bg-[rgba(29,28,38,0.85)] overflow-hidden shrink-0 w-full',
        className,
      )}
    >
      <div className="flex items-center gap-[1.2rem] shrink-0 min-w-0">
        <span
          className="font-bold text-[#c8fe4e] whitespace-nowrap"
          style={{ fontSize: titleSize }}
        >
          {title}
        </span>
        <SlashesIcon width={18} height={11} className="text-[#c8fe4e] shrink-0" />
        {subtitle && (
          <span className="text-[1.2rem] font-medium text-[#f8efff] opacity-75 whitespace-nowrap truncate">
            {subtitle}
          </span>
        )}
        {tag}
      </div>
      {right ?? <SlashesIcon width={30} height={12} className="text-[#f8efff] shrink-0" />}
    </div>
  )
}

/** Painel externo com a borda cinza característica. */
export function Panel({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <div
      className={cn(
        'flex flex-col p-[0.2rem] border-2 border-[#4d4c55] border-solid',
        className,
      )}
    >
      {children}
    </div>
  )
}
