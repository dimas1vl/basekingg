import { useMemo, useState } from 'react'
import { Gift, Search, Sparkles, X } from 'lucide-react'
import { cn } from '@/lib/utils'
import type { InventarioItem, InventarioRarity, InventarioFilters } from '@/types/nui'

interface InventarioTabProps {
  catalog: InventarioItem[]
  loading: boolean
  filters: InventarioFilters
  onFiltersChange: (filters: InventarioFilters) => void
  onGrant: (targetUserId: number, itemId: string) => void
}

const RARITY_STYLE: Record<InventarioRarity, string> = {
  common: 'bg-white/10 text-white/70 border-white/15',
  rare: 'bg-[#3b82f6]/15 text-[#60a5fa] border-[#3b82f6]/30',
  epic: 'bg-[#a855f7]/15 text-[#c084fc] border-[#a855f7]/30',
  legendary: 'bg-[#f59e0b]/15 text-[#fbbf24] border-[#f59e0b]/30',
  mythic: 'bg-[#ef4444]/15 text-[#fb7185] border-[#ef4444]/30',
}

const RARITIES: InventarioRarity[] = ['common', 'rare', 'epic', 'legendary', 'mythic']

const CATEGORY_LABEL: Record<string, string> = {
  clothes: 'Roupas',
  weapon_skin: 'Skin de arma',
  vehicle_skin: 'Skin de veiculo',
  parachute: 'Paraquedas',
}

function metadataEntries(item: InventarioItem): { key: string; value: string }[] {
  const md = item.metadata ?? {}
  const interesting = [
    'kind',
    'slot_id',
    'drawable',
    'texture',
    'palette',
    'model',
    'weapon_hash',
    'tint',
    'components',
    'vehicle_model',
    'livery',
    'primary_color',
    'secondary_color',
    'mod_kit',
    'wheel_type',
    'reserve_tint',
    'pack_tint',
  ]
  const out: { key: string; value: string }[] = []
  for (const key of interesting) {
    const v = (md as Record<string, unknown>)[key]
    if (v === undefined || v === null) continue
    let val: string
    if (Array.isArray(v)) val = v.join(', ')
    else if (typeof v === 'object') val = JSON.stringify(v)
    else val = String(v)
    out.push({ key, value: val })
  }
  return out
}

function GrantModal({
  item,
  onClose,
  onConfirm,
}: {
  item: InventarioItem
  onClose: () => void
  onConfirm: (userId: number) => void
}) {
  const [target, setTarget] = useState('')

  const submit = () => {
    const id = parseInt(target, 10)
    if (!id || id <= 0) return
    onConfirm(id)
  }

  return (
    <div
      onMouseDown={(e) => {
        if (e.target === e.currentTarget) onClose()
      }}
      className="fixed inset-0 z-50 grid place-items-center bg-black/60"
    >
      <div className="w-[34rem] overflow-hidden rounded-lg bg-modal shadow-2xl">
        <div className="flex items-center justify-between border-b border-white/10 px-5 py-3.5">
          <div className="flex items-center gap-2 text-[1.4rem] font-semibold uppercase tracking-wide text-[#f8efff]">
            <Gift size={18} className="text-primary" />
            Conceder item
          </div>
          <button
            onClick={onClose}
            className="text-white/50 transition-colors hover:text-white"
          >
            <X size={18} />
          </button>
        </div>
        <div className="flex flex-col gap-4 p-5">
          <div className="rounded-md border border-white/10 bg-white/[0.03] px-3.5 py-2.5">
            <span className="text-[1rem] uppercase tracking-wider text-white/40">Item</span>
            <p className="text-[1.3rem] font-medium text-[#f8efff]">
              {item.name} <span className="text-white/40">({item.id})</span>
            </p>
          </div>
          <div className="flex flex-col gap-1.5">
            <span className="text-[1rem] uppercase tracking-wider text-white/40">
              User ID do jogador
            </span>
            <input
              type="number"
              min={1}
              autoFocus
              value={target}
              onChange={(e) => setTarget(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') submit()
              }}
              placeholder="Ex: 42"
              className="rounded-md border border-white/10 bg-transparent px-3 py-2.5 text-[1.2rem] text-[#f8efff] outline-none focus:border-primary/50"
            />
          </div>
          <div className="flex justify-end gap-2.5">
            <button
              onClick={onClose}
              className="rounded-md border border-white/10 px-4 py-2 text-[1.15rem] font-medium text-white/60 transition-colors hover:bg-white/5"
            >
              Cancelar
            </button>
            <button
              onClick={submit}
              className="rounded-md bg-primary/15 px-4 py-2 text-[1.15rem] font-semibold text-primary transition-colors hover:bg-primary/25"
            >
              Conceder
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

function Card({
  item,
  onGrantClick,
}: {
  item: InventarioItem
  onGrantClick: (item: InventarioItem) => void
}) {
  const meta = metadataEntries(item)
  return (
    <div className="flex flex-col rounded-lg border border-white/10 bg-white/[0.02] transition-colors hover:border-white/20">
      <div className="flex items-center gap-3 px-4 py-3">
        <div className="grid h-12 w-12 shrink-0 place-items-center overflow-hidden rounded-md border border-white/10 bg-white/[0.03]">
          {item.image ? (
            <img src={item.image} alt={item.name} className="h-full w-full object-cover" />
          ) : (
            <Sparkles size={20} className="text-white/35" />
          )}
        </div>
        <div className="min-w-0 flex-1">
          <p className="truncate text-[1.3rem] font-semibold text-[#f8efff]">{item.name}</p>
          <p className="truncate text-[1rem] text-white/35">{item.id}</p>
        </div>
      </div>

      <div className="flex flex-wrap items-center gap-1.5 border-t border-white/10 px-4 py-2.5">
        <span className="rounded bg-white/5 px-2 py-0.5 text-[1rem] text-white/65">
          {CATEGORY_LABEL[item.category] ?? item.category}
          {item.subcategory ? ` / ${item.subcategory}` : ''}
        </span>
        <span
          className={cn(
            'rounded border px-2 py-0.5 text-[1rem] font-semibold uppercase',
            RARITY_STYLE[item.rarity],
          )}
        >
          {item.rarity}
        </span>
        {item.purchasable && (
          <span className="rounded bg-primary/15 px-2 py-0.5 text-[1rem] font-semibold text-primary">
            {item.price ?? 0} gems
          </span>
        )}
        {item.enabled === false && (
          <span className="rounded bg-[#e0566b]/15 px-2 py-0.5 text-[1rem] font-semibold text-[#e0566b]">
            DESATIVADO
          </span>
        )}
      </div>

      {meta.length > 0 && (
        <div className="border-t border-white/10 px-4 py-2.5">
          <p className="mb-1 text-[0.95rem] uppercase tracking-wider text-white/40">
            Metadata tecnica
          </p>
          <div className="grid grid-cols-2 gap-x-3 gap-y-0.5">
            {meta.map((m) => (
              <div key={m.key} className="truncate text-[1.05rem] text-white/55">
                <span className="text-white/40">{m.key}:</span>{' '}
                <span className="text-[#f8efff]/90">{m.value}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      <button
        onClick={() => onGrantClick(item)}
        className="mt-auto flex items-center justify-center gap-2 border-t border-white/10 bg-white/[0.02] py-2.5 text-[1.15rem] font-semibold text-primary transition-colors hover:bg-primary/10"
      >
        <Gift size={15} />
        Conceder a jogador
      </button>
    </div>
  )
}

export default function InventarioTab({
  catalog,
  loading,
  filters,
  onFiltersChange,
  onGrant,
}: InventarioTabProps) {
  const [grantTarget, setGrantTarget] = useState<InventarioItem | null>(null)

  const categories = useMemo(() => {
    const set = new Set<string>()
    for (const item of catalog) set.add(item.category)
    return Array.from(set).sort()
  }, [catalog])

  const setFilter = (patch: Partial<InventarioFilters>) => {
    onFiltersChange({ ...filters, ...patch })
  }

  return (
    <div className="flex flex-col gap-4">
      {/* Filters */}
      <div className="flex flex-wrap items-center gap-2.5 rounded-lg border border-white/10 bg-white/[0.02] px-3.5 py-3">
        <div className="flex items-center gap-2 rounded-md border border-white/10 bg-white/[0.03] px-3 py-1.5">
          <Search size={15} className="text-white/40" />
          <input
            value={filters.search ?? ''}
            onChange={(e) => setFilter({ search: e.target.value })}
            placeholder="Buscar nome ou ID..."
            className="w-56 bg-transparent text-[1.15rem] text-[#f8efff] outline-none placeholder:text-white/30"
          />
        </div>

        <select
          value={filters.category ?? ''}
          onChange={(e) => setFilter({ category: e.target.value || undefined })}
          className="rounded-md border border-white/10 bg-[#151515] px-3 py-2 text-[1.15rem] text-[#f8efff] outline-none"
        >
          <option value="">Todas categorias</option>
          {categories.map((c) => (
            <option key={c} value={c}>
              {CATEGORY_LABEL[c] ?? c}
            </option>
          ))}
        </select>

        <select
          value={filters.rarity ?? ''}
          onChange={(e) =>
            setFilter({ rarity: (e.target.value as InventarioRarity) || '' })
          }
          className="rounded-md border border-white/10 bg-[#151515] px-3 py-2 text-[1.15rem] text-[#f8efff] outline-none"
        >
          <option value="">Todas raridades</option>
          {RARITIES.map((r) => (
            <option key={r} value={r}>
              {r}
            </option>
          ))}
        </select>

        <label className="flex cursor-pointer items-center gap-2 rounded-md border border-white/10 bg-white/[0.03] px-3 py-2 text-[1.15rem] text-white/65">
          <input
            type="checkbox"
            checked={!!filters.purchasable}
            onChange={(e) => setFilter({ purchasable: e.target.checked })}
            className="h-3.5 w-3.5 accent-[#a855f7]"
          />
          Apenas compraveis
        </label>

        <span className="ml-auto text-[1.1rem] text-white/40">
          {loading ? 'Carregando...' : `${catalog.length} itens`}
        </span>
      </div>

      {/* Grid */}
      {catalog.length === 0 ? (
        <p className="py-10 text-center text-[1.3rem] text-white/35">
          {loading ? 'Carregando catalogo...' : 'Nenhum item encontrado.'}
        </p>
      ) : (
        <div className="grid grid-cols-1 gap-3 md:grid-cols-2 xl:grid-cols-3">
          {catalog.map((item) => (
            <Card key={item.id} item={item} onGrantClick={setGrantTarget} />
          ))}
        </div>
      )}

      {grantTarget && (
        <GrantModal
          item={grantTarget}
          onClose={() => setGrantTarget(null)}
          onConfirm={(userId) => {
            onGrant(userId, grantTarget.id)
            setGrantTarget(null)
          }}
        />
      )}
    </div>
  )
}
