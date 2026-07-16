import { useCallback, useEffect, useMemo, useState } from 'react'
import { useListener } from '@/hooks/listener'
import { fetchInventario } from '@inventario/utils/fetchInventario'
import type {
  BuyResult,
  CatalogFilter,
  InventarioItem,
  EquipResult,
  EquippedMap,
  InventoryPayload,
  UnequipSlotInput,
} from '@inventario/modules/inventory/types'

// -----------------------------------------------------------------------------
// useInventario — single source of truth for the inventory UI.
// -----------------------------------------------------------------------------
// Behavior:
//   - On mount: fetches `getMyInventory` and `getCatalog` (no filter).
//   - Listens for the server-broadcasted `inventario:apply` event so the UI
//     refreshes whenever another tab/admin equips something for the player.
//   - Exposes equip/unequip/buy helpers that optimistically refresh the
//     inventory after the RPC resolves. We don't try to merge the result
//     locally — the server is the source of truth and a refetch is cheap.

export interface UseInventarioState {
  inventory: InventoryPayload | null
  equipped: EquippedMap
  catalog: InventarioItem[]
  loading: boolean
  /** Last error string from a mutation, cleared on next call. */
  error: string | null
}

export interface UseInventarioActions {
  refresh: () => Promise<void>
  refreshCatalog: (filter?: CatalogFilter) => Promise<void>
  equipItem: (itemId: string) => Promise<EquipResult>
  equipItems: (itemIds: string[]) => Promise<EquipResult>
  unequipSlot: (input: UnequipSlotInput) => Promise<EquipResult>
  buyItem: (itemId: string) => Promise<BuyResult>
}

const EMPTY_EQUIPPED: EquippedMap = {}

export function useInventario(): UseInventarioState & UseInventarioActions {
  const [inventory, setInventory] = useState<InventoryPayload | null>(null)
  const [catalog, setCatalog] = useState<InventarioItem[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const refresh = useCallback(async () => {
    setLoading(true)
    try {
      const inv = await fetchInventario.getMyInventory()
      // Defensive: server may return `nil` on cold-start; coerce to a sane shape.
      setInventory(
        inv && typeof inv === 'object'
          ? { items: inv.items ?? [], equipped: inv.equipped ?? EMPTY_EQUIPPED }
          : { items: [], equipped: EMPTY_EQUIPPED },
      )
    } finally {
      setLoading(false)
    }
  }, [])

  const refreshCatalog = useCallback(async (filter?: CatalogFilter) => {
    const items = await fetchInventario.getCatalog(filter)
    setCatalog(Array.isArray(items) ? items : [])
  }, [])

  // Initial load — both calls run in parallel.
  useEffect(() => {
    void Promise.all([refresh(), refreshCatalog()])
  }, [refresh, refreshCatalog])

  // Server pushes `inventario:apply` after every apply/applyOne/unapplyOne so
  // we can keep the UI in sync without polling. The payload itself isn't
  // sufficient to fully rebuild inventory (it only carries items), so we
  // simply refetch — equipped maps are tiny.
  useListener('inventario:apply', () => {
    void refresh()
  })
  useListener('inventario:applyOne', () => {
    void refresh()
  })
  useListener('inventario:unapplyOne', () => {
    void refresh()
  })

  const equipItems = useCallback(
    async (itemIds: string[]): Promise<EquipResult> => {
      setError(null)
      const result = await fetchInventario.equipItems(itemIds)
      if (!result?.ok) setError(result?.error ?? 'Falha ao equipar.')
      // Server emits `inventario:apply` so the listener will refresh,
      // but we also refresh defensively in case the listener is missed.
      await refresh()
      return result
    },
    [refresh],
  )

  const equipItem = useCallback(
    (itemId: string) => equipItems([itemId]),
    [equipItems],
  )

  const unequipSlot = useCallback(
    async (input: UnequipSlotInput): Promise<EquipResult> => {
      setError(null)
      const result = await fetchInventario.unequipSlots([input])
      if (!result?.ok) setError(result?.error ?? 'Falha ao desequipar.')
      await refresh()
      return result
    },
    [refresh],
  )

  const buyItem = useCallback(
    async (itemId: string): Promise<BuyResult> => {
      setError(null)
      const result = await fetchInventario.buyItem(itemId)
      if (!result?.ok) setError(result?.error ?? 'Falha ao comprar.')
      else await refresh()
      return result
    },
    [refresh],
  )

  const equipped = inventory?.equipped ?? EMPTY_EQUIPPED

  return useMemo(
    () => ({
      inventory,
      equipped,
      catalog,
      loading,
      error,
      refresh,
      refreshCatalog,
      equipItem,
      equipItems,
      unequipSlot,
      buyItem,
    }),
    [
      inventory,
      equipped,
      catalog,
      loading,
      error,
      refresh,
      refreshCatalog,
      equipItem,
      equipItems,
      unequipSlot,
      buyItem,
    ],
  )
}
