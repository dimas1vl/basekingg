// =============================================================================
// fetchInventario — NUI bridge to the `inventario` client resource
// =============================================================================
// TODO(agent-2): The inventario client (`[scripts]/inventario/client/main.lua`)
// MUST register the following NUI callbacks that delegate to the server via the
// existing `RPC` helper from `[main]/kingg/shared/lib.lua`:
//
//   - RegisterNUICallback('getMyInventory', ...) -> RPC 'net.inventario:getMyInventory'
//   - RegisterNUICallback('getCatalog', ...)     -> RPC 'net.inventario:getCatalog'   (filter payload)
//   - RegisterNUICallback('getMyEquipped', ...)  -> RPC 'net.inventario:getMyEquipped'
//   - RegisterNUICallback('equipItems', ...)     -> RPC 'net.inventario:equipItems'   ({ itemIds })
//   - RegisterNUICallback('unequipSlots', ...)   -> RPC 'net.inventario:unequipSlots' ({ slots })
//   - RegisterNUICallback('buyItem', ...)        -> RPC 'net.inventario:buyItem'      ({ itemId })
//
// Because the inventario resource has no UI of its own, the lobby NUI talks to
// the inventario resource directly via `https://lobby_inventory/<callback>` — NOT the
// parent lobby resource. That allows the lobby to remain a thin shell.

import type {
  BuyResult,
  CatalogFilter,
  InventarioItem,
  EquipResult,
  EquippedMap,
  InventoryPayload,
  UnequipSlotInput,
} from '@inventario/modules/inventory/types'

const isBrowser = (): boolean => !(window as any).invokeNative
const INVENTARIO_RESOURCE = 'lobby_inventory'

async function call<T>(event: string, data?: unknown, mockData?: T): Promise<T> {
  if (isBrowser() && mockData !== undefined) {
    return mockData
  }

  const resp = await fetch(`https://${INVENTARIO_RESOURCE}/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data ?? {}),
  })

  const text = await resp.text()
  if (!text) return undefined as unknown as T
  try {
    return JSON.parse(text) as T
  } catch {
    return undefined as unknown as T
  }
}

// -----------------------------------------------------------------------------
// Browser mocks — used when running the lobby web in `vite dev` outside FiveM.
// -----------------------------------------------------------------------------
const MOCK_ITEMS: InventarioItem[] = [
  {
    id: 'tops_red_hoodie_01',
    name: 'Hoodie Vermelho',
    category: 'clothes',
    subcategory: 'tops',
    rarity: 'rare',
    purchasable: false,
    image: 'images/inventario/tops_red_01.png',
  },
  {
    id: 'tops_black_tee_01',
    name: 'Camiseta Preta',
    category: 'clothes',
    subcategory: 'tops',
    rarity: 'common',
    price: 250,
    purchasable: true,
    image: null,
  },
  {
    id: 'pistol_neon_skin_01',
    name: 'Pistola Neon',
    category: 'weapon_skin',
    subcategory: 'pistol',
    rarity: 'epic',
    price: 1500,
    purchasable: true,
    image: null,
  },
  {
    id: 'kuruma_gold_01',
    name: 'Kuruma Ouro',
    category: 'vehicle_skin',
    subcategory: 'car',
    rarity: 'legendary',
    price: 5000,
    purchasable: true,
    image: null,
  },
  {
    id: 'chute_mythic_01',
    name: 'Para-quedas Místico',
    category: 'parachute',
    subcategory: 'chute',
    rarity: 'mythic',
    purchasable: false,
    image: null,
  },
]

const MOCK_EQUIPPED: EquippedMap = {
  clothes: { '11': 'tops_red_hoodie_01' },
}

// -----------------------------------------------------------------------------
// Public API — these are the only entry points used by the React layer.
// -----------------------------------------------------------------------------
export const fetchInventario = {
  getMyInventory(): Promise<InventoryPayload> {
    return call<InventoryPayload>('getMyInventory', undefined, {
      items: MOCK_ITEMS,
      equipped: MOCK_EQUIPPED,
    })
  },

  getCatalog(filter?: CatalogFilter): Promise<InventarioItem[]> {
    return call<InventarioItem[]>('getCatalog', filter ?? {}, MOCK_ITEMS)
  },

  getMyEquipped(): Promise<EquippedMap> {
    return call<EquippedMap>('getMyEquipped', undefined, MOCK_EQUIPPED)
  },

  equipItems(itemIds: string[]): Promise<EquipResult> {
    return call<EquipResult>(
      'equipItems',
      { itemIds },
      { ok: true, results: itemIds.map((id) => ({ itemId: id, ok: true })) },
    )
  },

  unequipSlots(slots: UnequipSlotInput[]): Promise<EquipResult> {
    return call<EquipResult>(
      'unequipSlots',
      { slots },
      { ok: true, results: slots.map((s) => ({ itemId: `${s.category}:${s.slot}`, ok: true })) },
    )
  },

  buyItem(itemId: string): Promise<BuyResult> {
    return call<BuyResult>('buyItem', { itemId }, { ok: true, newBalance: 9999 })
  },
}
