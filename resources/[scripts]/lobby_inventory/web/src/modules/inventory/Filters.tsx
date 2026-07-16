import { Search } from 'lucide-react'
import type { Category, Rarity } from './types'
import { RARITY_LABEL } from '@inventario/utils/rarity'

export interface FiltersState {
  category: Category | 'all'
  rarity: Rarity | 'all'
  onlyShop: boolean
  search: string
}

export interface FiltersProps {
  value: FiltersState
  onChange: (next: FiltersState) => void
  /** When set, hides the "only shop" checkbox (e.g. on the Equipped tab). */
  hideOnlyShop?: boolean
}

const CATEGORIES: Array<{ value: Category | 'all'; label: string }> = [
  { value: 'all', label: 'Todas as categorias' },
  { value: 'clothes', label: 'Roupas' },
  { value: 'weapon_skin', label: 'Skins de Arma' },
  { value: 'vehicle_skin', label: 'Skins de Veiculo' },
  { value: 'parachute', label: 'Para-quedas' },
]

const RARITIES: Array<{ value: Rarity | 'all'; label: string }> = [
  { value: 'all', label: 'Qualquer raridade' },
  { value: 'common', label: RARITY_LABEL.common },
  { value: 'rare', label: RARITY_LABEL.rare },
  { value: 'epic', label: RARITY_LABEL.epic },
  { value: 'legendary', label: RARITY_LABEL.legendary },
  { value: 'mythic', label: RARITY_LABEL.mythic },
]

export default function Filters({ value, onChange, hideOnlyShop }: FiltersProps) {
  const update = <K extends keyof FiltersState>(key: K, v: FiltersState[K]) =>
    onChange({ ...value, [key]: v })

  return (
    <div className="flex flex-wrap items-center gap-3 border-b border-white/10 px-7 py-3">
      {/* Search */}
      <div className="flex items-center gap-2 rounded-md border border-white/10 bg-white/[0.03] px-3 py-2">
        <Search size={15} className="text-white/40" />
        <input
          value={value.search}
          onChange={(e) => update('search', e.target.value)}
          placeholder="Buscar por nome..."
          className="w-56 bg-transparent text-[1.2rem] text-[#f8efff] outline-none placeholder:text-white/30"
        />
      </div>

      {/* Category */}
      <select
        value={value.category}
        onChange={(e) => update('category', e.target.value as Category | 'all')}
        className="rounded-md border border-white/10 bg-[#151515] px-3 py-2 text-[1.2rem] text-[#f8efff] outline-none focus:border-primary/50"
      >
        {CATEGORIES.map((c) => (
          <option key={c.value} value={c.value}>
            {c.label}
          </option>
        ))}
      </select>

      {/* Rarity */}
      <select
        value={value.rarity}
        onChange={(e) => update('rarity', e.target.value as Rarity | 'all')}
        className="rounded-md border border-white/10 bg-[#151515] px-3 py-2 text-[1.2rem] text-[#f8efff] outline-none focus:border-primary/50"
      >
        {RARITIES.map((r) => (
          <option key={r.value} value={r.value}>
            {r.label}
          </option>
        ))}
      </select>

      {/* Only shop */}
      {!hideOnlyShop && (
        <label className="flex cursor-pointer items-center gap-2 select-none text-[1.2rem] text-white/70 hover:text-white">
          <input
            type="checkbox"
            checked={value.onlyShop}
            onChange={(e) => update('onlyShop', e.target.checked)}
            className="h-4 w-4 cursor-pointer accent-[#9d0de9]"
          />
          So loja
        </label>
      )}
    </div>
  )
}
