import { useCallback, useMemo, useState } from 'react'
import { ArrowLeft, Box, ShoppingBag, Sparkles } from 'lucide-react'
import { cn } from '@/lib/utils'
import { useInventario } from '@inventario/hooks/useInventario'
import Filters, { type FiltersState } from './Filters'
import ItemCard, { type ItemAction } from './ItemCard'
import type { InventarioItem, InventoryTab } from './types'

// -----------------------------------------------------------------------------
// InventoryPage — the only top-level export consumed by the lobby NUI.
// -----------------------------------------------------------------------------
// Layout intentionally mirrors `admin/panel` for a consistent look:
// header + tabs strip + filters + scrollable grid body.

export interface InventoryPageProps {
  onClose: () => void
}

const TABS: Array<{ id: InventoryTab; label: string; icon: typeof Box }> = [
  { id: 'owned', label: 'POSSUIDOS', icon: Box },
  { id: 'shop', label: 'LOJA', icon: ShoppingBag },
  { id: 'equipped', label: 'EQUIPADO', icon: Sparkles },
]

const DEFAULT_FILTERS: FiltersState = {
  category: 'all',
  rarity: 'all',
  onlyShop: false,
  search: '',
}

function matchesFilters(item: InventarioItem, filters: FiltersState): boolean {
  if (filters.category !== 'all' && item.category !== filters.category) return false
  if (filters.rarity !== 'all' && item.rarity !== filters.rarity) return false
  if (filters.onlyShop && !item.purchasable) return false
  if (filters.search) {
    const q = filters.search.trim().toLowerCase()
    if (q && !item.name.toLowerCase().includes(q)) return false
  }
  return true
}

function notify(type: 'success' | 'error', message: string) {
  // The lobby runtime sets up a global `Notify` listener — we call it via the
  // FiveM bridge if available, otherwise we degrade silently in the browser.
  const send = (window as any).GetParentResourceName
  if (!send) return
  try {
    void fetch(`https://${send()}/__inventarioNotify__`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify({ type, message }),
    })
  } catch {
    // ignore — UI feedback is best effort
  }
}

export default function InventoryPage({ onClose }: InventoryPageProps) {
  const inventario = useInventario()
  const [tab, setTab] = useState<InventoryTab>('owned')
  const [filters, setFilters] = useState<FiltersState>(DEFAULT_FILTERS)
  const [pendingId, setPendingId] = useState<string | null>(null)

  // ---------------------------------------------------------------------------
  // Derived sets — quick lookups for "owned" / "equipped" used by every card.
  // ---------------------------------------------------------------------------
  const ownedIds = useMemo(
    () => new Set((inventario.inventory?.items ?? []).map((i) => i.id)),
    [inventario.inventory],
  )

  const equippedIds = useMemo(() => {
    const set = new Set<string>()
    for (const cat of Object.values(inventario.equipped)) {
      for (const itemId of Object.values(cat)) set.add(itemId)
    }
    return set
  }, [inventario.equipped])

  // ---------------------------------------------------------------------------
  // Visible items per tab
  // ---------------------------------------------------------------------------
  const ownedItems = inventario.inventory?.items ?? []
  const catalogItems = inventario.catalog

  const items: InventarioItem[] = useMemo(() => {
    if (tab === 'owned') return ownedItems.filter((i) => matchesFilters(i, filters))
    if (tab === 'shop') {
      // Shop = purchasable catalog items the player doesn't yet own.
      const ff = { ...filters, onlyShop: true }
      return catalogItems.filter((i) => !ownedIds.has(i.id) && matchesFilters(i, ff))
    }
    // Equipped: only items currently equipped, ignore "onlyShop" filter.
    const ff = { ...filters, onlyShop: false }
    return ownedItems.filter((i) => equippedIds.has(i.id) && matchesFilters(i, ff))
  }, [tab, ownedItems, catalogItems, filters, ownedIds, equippedIds])

  // ---------------------------------------------------------------------------
  // Per-tab action resolution
  // ---------------------------------------------------------------------------
  const resolveAction = useCallback(
    (item: InventarioItem): ItemAction => {
      if (item.incompatible) return 'none'
      if (equippedIds.has(item.id)) return 'unequip'
      if (ownedIds.has(item.id)) return 'equip'
      if (item.purchasable) return 'buy'
      return 'none'
    },
    [ownedIds, equippedIds],
  )

  const handleAction = useCallback(
    async (item: InventarioItem, action: ItemAction) => {
      if (pendingId) return
      setPendingId(item.id)
      try {
        if (action === 'equip') {
          const r = await inventario.equipItem(item.id)
          notify(r.ok ? 'success' : 'error', r.ok ? `${item.name} equipado.` : r.error ?? 'Falha ao equipar.')
        } else if (action === 'unequip') {
          // We need a slot — derive from the equipped map.
          let target: { category: string; slot: string } | null = null
          for (const [cat, slots] of Object.entries(inventario.equipped)) {
            for (const [slot, id] of Object.entries(slots)) {
              if (id === item.id) {
                target = { category: cat, slot }
                break
              }
            }
            if (target) break
          }
          if (!target) {
            notify('error', 'Slot equipado nao localizado.')
            return
          }
          const r = await inventario.unequipSlot(target)
          notify(
            r.ok ? 'success' : 'error',
            r.ok ? `${item.name} desequipado.` : r.error ?? 'Falha ao desequipar.',
          )
        } else if (action === 'buy') {
          const r = await inventario.buyItem(item.id)
          notify(
            r.ok ? 'success' : 'error',
            r.ok
              ? `${item.name} comprado! Saldo: ${r.newBalance?.toLocaleString('pt-BR') ?? '?'} gems`
              : r.error ?? 'Falha ao comprar.',
          )
        }
      } finally {
        setPendingId(null)
      }
    },
    [pendingId, inventario],
  )

  // ---------------------------------------------------------------------------
  // Render
  // ---------------------------------------------------------------------------
  return (
    <div className="flex h-[80vh] w-[96rem] flex-col overflow-hidden rounded-xl bg-modal shadow-2xl">
      {/* Header */}
      <div className="flex items-center justify-between border-b border-white/10 px-7 py-5">
        <div className="flex items-center gap-3">
          <Sparkles size={24} className="text-primary" />
          <span className="text-[1.8rem] font-bold uppercase tracking-wide text-[#f8efff]">
            Inventario
          </span>
        </div>
        <button
          onClick={onClose}
          className="flex items-center gap-2 rounded-md border border-white/10 bg-white/[0.03] px-3 py-2 text-[1.2rem] text-white/70 transition-colors hover:border-primary/50 hover:text-primary"
        >
          <ArrowLeft size={16} />
          Voltar
        </button>
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-3 border-b border-white/10 px-7 py-3">
        {TABS.map((t) => {
          const Icon = t.icon
          const active = tab === t.id
          const count =
            t.id === 'owned'
              ? ownedItems.length
              : t.id === 'shop'
              ? catalogItems.filter((i) => i.purchasable && !ownedIds.has(i.id)).length
              : equippedIds.size
          return (
            <button
              key={t.id}
              onClick={() => setTab(t.id)}
              className={cn(
                'flex items-center gap-2 rounded-md px-4 py-2 text-[1.3rem] font-medium uppercase tracking-wide transition-colors',
                active ? 'bg-primary/15 text-primary' : 'text-white/55 hover:text-white',
              )}
            >
              <Icon size={16} />
              {t.label} ({count})
            </button>
          )
        })}
        {inventario.loading && (
          <span className="ml-auto text-[1.1rem] text-white/40">Carregando...</span>
        )}
      </div>

      {/* Filters */}
      <Filters value={filters} onChange={setFilters} hideOnlyShop={tab !== 'owned'} />

      {/* Grid body */}
      <div className="flex-1 overflow-y-auto overflow-x-hidden px-7 py-5">
        {items.length === 0 ? (
          <p className="py-16 text-center text-[1.3rem] text-white/35">
            {inventario.loading ? 'Carregando...' : 'Nenhum item encontrado.'}
          </p>
        ) : (
          <div className="grid grid-cols-[repeat(auto-fill,minmax(20rem,1fr))] gap-4">
            {items.map((item) => (
              <ItemCard
                key={item.id}
                item={item}
                owned={ownedIds.has(item.id)}
                equipped={equippedIds.has(item.id)}
                action={resolveAction(item)}
                disabled={pendingId === item.id}
                onAction={handleAction}
              />
            ))}
          </div>
        )}
      </div>

      {inventario.error && (
        <div className="border-t border-[#e0566b]/30 bg-[#e0566b]/10 px-7 py-2 text-[1.1rem] text-[#e0566b]">
          {inventario.error}
        </div>
      )}
    </div>
  )
}
