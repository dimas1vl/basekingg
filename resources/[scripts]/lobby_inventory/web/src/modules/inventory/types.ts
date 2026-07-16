// =============================================================================
// Inventario — NUI types (frontend mirror of the Lua contract)
// =============================================================================
// These shapes are aligned with the server contract documented in
// `[scripts]/inventario/ARQUITETURA.md`. Keep them strict so the lobby build
// catches drift before it reaches the player.

export type Rarity = 'common' | 'rare' | 'epic' | 'legendary' | 'mythic'

export type Category =
  | 'clothes'
  | 'weapon_skin'
  | 'vehicle_skin'
  | 'parachute'
  | (string & {}) // allow future categories without losing autocomplete

export interface InventarioMetadata {
  // clothes
  kind?: 'component' | 'prop'
  slot_id?: number
  drawable?: number
  texture?: number
  palette?: number
  model?: 'mp_m_freemode_01' | 'mp_f_freemode_01' | null

  // weapon_skin
  weapon_hash?: string
  components?: string[]

  // vehicle_skin
  vehicle_model?: string
  livery?: number
  primary_color?: number
  secondary_color?: number
  mod_kit?: number
  wheel_type?: number | null

  // parachute / weapon_skin share `tint`
  tint?: number
  reserve_tint?: number
  pack_tint?: number

  // free-form extras
  [key: string]: unknown
}

export interface InventarioItem {
  id: string
  name: string
  category: Category
  subcategory?: string
  rarity: Rarity
  price?: number | null
  purchasable: boolean
  image?: string | null
  metadata?: InventarioMetadata
  /** Optional flag set by the server to mark items the player cannot use
   *  (e.g. wrong ped model for a clothes piece). */
  incompatible?: boolean
}

/** equipped[category][slot] = itemId  — slot is stringified for JSON safety. */
export type EquippedMap = Record<string, Record<string, string>>

export interface InventoryPayload {
  items: InventarioItem[]
  equipped: EquippedMap
}

export interface CatalogFilter {
  category?: Category
  rarity?: Rarity
  purchasable?: boolean
  search?: string
}

export interface EquipResult {
  ok: boolean
  results?: Array<{ itemId: string; ok: boolean; error?: string }>
  error?: string
}

export interface UnequipSlotInput {
  category: Category
  slot: string | number
}

export interface BuyResult {
  ok: boolean
  error?: string
  newBalance?: number
}

export type InventoryTab = 'owned' | 'shop' | 'equipped'
