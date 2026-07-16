import {
  Backpack,
  Car,
  Crosshair,
  Footprints,
  HardHat,
  Shirt,
  Square,
  Triangle,
  VenetianMask,
  Watch,
  type LucideIcon,
} from 'lucide-react'
import type { ClothingCategory } from '../types'

type Props = {
  categories: ClothingCategory[]
  selectedId: string
  onSelect: (id: string) => void
}

// Friendly PT-BR labels per category id (shown in the hover tooltip).
const CATEGORY_LABELS: Record<string, string> = {
  tops: 'Camiseta',
  pants: 'Calça',
  shoes: 'Tênis',
  hat: 'Chapéu',
  mask: 'Máscara',
  accessories: 'Acessórios',
  bag: 'Mochila',
  primary: 'Arma',
  car: 'Veículo',
  chute: 'Paraquedas',
}

// Lucide icon per category id; falls back to a square placeholder.
const CATEGORY_ICONS: Record<string, LucideIcon> = {
  tops: Shirt,
  pants: Square,
  shoes: Footprints,
  hat: HardHat,
  mask: VenetianMask,
  accessories: Watch,
  bag: Backpack,
  primary: Crosshair,
  car: Car,
  chute: Triangle,
}

export function CategorySidebar({ categories, selectedId, onSelect }: Props) {
  return (
    <div
      className="flex flex-col shrink-0 border-2 border-solid border-[#4d4c55]"
      style={{ width: '5.2rem' }}
    >
      {categories.map((cat, i) => {
        const isActive = cat.id === selectedId
        const Icon = CATEGORY_ICONS[cat.id] ?? Square
        const label = CATEGORY_LABELS[cat.id] ?? cat.id.toUpperCase()
        return (
          <div key={cat.id} className="flex flex-col shrink-0">
            <div className="group/cat relative">
              <button
                onClick={() => onSelect(cat.id)}
                className="flex items-center justify-center overflow-hidden cursor-pointer transition-[background-color] duration-150 w-full"
                style={{
                  height: '5.2rem',
                  backgroundColor: isActive ? '#f8efff' : 'rgba(248,239,255,0.05)',
                }}
              >
                <Icon
                  size={26}
                  strokeWidth={1.8}
                  color={isActive ? '#151515' : '#f8efff'}
                  style={{
                    opacity: isActive ? 1 : 0.6,
                    flexShrink: 0,
                  }}
                />
              </button>

              {/* Hover tooltip — appears to the right of the sidebar */}
              <span
                className="pointer-events-none absolute left-full top-1/2 z-30 ml-[0.8rem] -translate-y-1/2 -translate-x-1 whitespace-nowrap rounded-md px-[1rem] py-[0.5rem] text-[1.1rem] font-medium text-[#f8efff] opacity-0 shadow-lg transition-all duration-150 group-hover/cat:translate-x-0 group-hover/cat:opacity-100"
                style={{
                  backgroundColor: 'rgba(12,12,12,0.95)',
                  border: '0.1rem solid rgba(248,239,255,0.15)',
                }}
              >
                {label}
                {/* Arrow pointing back at the button */}
                <span
                  className="absolute top-1/2 -translate-y-1/2"
                  style={{
                    right: '100%',
                    width: 0,
                    height: 0,
                    borderTop: '0.4rem solid transparent',
                    borderBottom: '0.4rem solid transparent',
                    borderRight: '0.4rem solid rgba(12,12,12,0.95)',
                  }}
                />
              </span>
            </div>
            {i < categories.length - 1 && (
              <div className="shrink-0 w-full bg-[#4d4c55]" style={{ height: '0.2rem' }} />
            )}
          </div>
        )
      })}
    </div>
  )
}
