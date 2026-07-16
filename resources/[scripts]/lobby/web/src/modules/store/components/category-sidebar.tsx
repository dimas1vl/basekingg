import { ComponentType, SVGProps, useState } from 'react'
import { cn } from '@/lib/utils'
import { DividerIcon } from '@/components/icons'
import {
  CaretDownIcon,
  DominanceIcon,
  GameControllerIcon,
  ParachuteIcon,
  StorefrontIcon,
} from '../icons'
import type { StoreCategory, StoreCategoryIcon } from '../data'

const ICONS: Record<StoreCategoryIcon, ComponentType<SVGProps<SVGSVGElement>>> = {
  store: StorefrontIcon,
  dominance: DominanceIcon,
  parachute: ParachuteIcon,
  gamepad: GameControllerIcon,
}

type CategorySidebarProps = {
  categories: StoreCategory[]
  selected: string
  onSelect: (id: string) => void
}

export function CategorySidebar({ categories, selected, onSelect }: CategorySidebarProps) {
  // Começa com a categoria pai da seleção expandida.
  const [expanded, setExpanded] = useState<string | null>(
    categories.find((c) => c.sub?.some((s) => s.id === selected))?.id ??
      categories.find((c) => c.sub)?.id ??
      null,
  )

  return (
    <div className="flex flex-col w-[38.6rem] shrink-0 h-full min-h-0">
      <div className="flex flex-col flex-1 min-h-0 gap-[1rem] p-[0.6rem] bg-[rgba(29,28,38,0.95)]">
        {/* Cabeçalho */}
        <div className="flex items-center h-[4.3rem] pl-[2rem] pr-[1.2rem] bg-[rgba(248,239,255,0.1)] border-l-8 border-[#f8efff] border-solid shrink-0">
          <span className="text-[1.6rem] font-semibold text-[#f8efff] whitespace-nowrap">CATEGORIAS</span>
        </div>

        {/* Lista */}
        <div className="flex flex-col gap-[1rem] flex-1 min-h-0 overflow-y-auto">
          {categories.map((cat) => {
            const Icon = ICONS[cat.icon]
            const isExpanded = expanded === cat.id
            const isActive = selected === cat.id || cat.sub?.some((s) => s.id === selected)

            return (
              <div key={cat.id} className="flex flex-col shrink-0">
                <button
                  onClick={() => {
                    if (cat.sub) {
                      setExpanded((prev) => (prev === cat.id ? null : cat.id))
                    } else {
                      onSelect(cat.id)
                    }
                  }}
                  className={cn(
                    'flex h-[4.8rem] items-center justify-between px-[1.2rem] py-[0.4rem] bg-[rgba(248,239,255,0.05)] border-2 border-solid overflow-hidden cursor-pointer transition-colors',
                    isActive ? 'border-[#c8fe4e]' : 'border-[#4d4c55] hover:border-[rgba(248,239,255,0.3)]',
                  )}
                >
                  <div className="flex items-center gap-[1.2rem]">
                    <Icon className="size-[2.4rem] text-[#f8efff] shrink-0" />
                    <span className="text-[1.4rem] font-semibold text-[#f8efff] whitespace-nowrap">
                      {cat.label}
                    </span>
                  </div>
                  {cat.sub && (
                    <CaretDownIcon
                      className={cn(
                        'size-[2.4rem] text-[#f8efff] shrink-0 transition-transform',
                        isExpanded && '-scale-y-100',
                      )}
                    />
                  )}
                </button>

                {cat.sub && isExpanded && (
                  <div className="flex flex-col bg-[rgba(248,239,255,0.1)] overflow-hidden">
                    {cat.sub.map((s) => (
                      <button
                        key={s.id}
                        onClick={() => onSelect(s.id)}
                        className={cn(
                          'flex h-[4.9rem] items-center px-[1.4rem] cursor-pointer transition-colors',
                          selected === s.id
                            ? 'bg-[rgba(200,254,78,0.12)]'
                            : 'bg-[rgba(29,28,38,0.2)] hover:bg-[rgba(248,239,255,0.06)]',
                        )}
                      >
                        <span
                          className={cn(
                            'text-[1.4rem] font-semibold whitespace-nowrap',
                            selected === s.id ? 'text-[#c8fe4e]' : 'text-[#f8efff]',
                          )}
                        >
                          {s.label}
                        </span>
                      </button>
                    ))}
                  </div>
                )}
              </div>
            )
          })}
        </div>
      </div>
      <DividerIcon width="100%" className="text-[#c8fe4e] shrink-0" />
    </div>
  )
}
