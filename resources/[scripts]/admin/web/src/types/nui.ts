export type NotifyType = 'success' | 'error' | 'info' | 'warning' | 'importante'

export interface NotifyPayload {
  type: NotifyType
  message: string
  duration: number
}

export interface CdsPayload {
  x: number
  y: number
  z: number
  h: number
}

export interface BanPayload {
  targetSrc: number
  targetUserId: number
  targetName: string
}

export interface ZonePoint {
  x: number
  y: number
  z: number
}

export interface ZoneRadius {
  center: ZonePoint
  radius: number
  height: number
}

export interface ZonePointsPayload {
  points?: ZonePoint[]
  center?: ZonePoint
  radius?: number
  height?: number
}

export type AdminView = 'none' | 'cds' | 'panel' | 'tpcds' | 'zonepoints'

export type PlayerRole = 'user' | 'admin' | 'spec'

export interface PanelPlayer {
  src: number
  userId: number
  name: string
  role: PlayerRole
  xp: number
  gems: number
  premium: number
  mode: string
}

export interface PanelBan {
  userId: number
  name: string
  reason: string
  staffId: number
  staffName: string
  createdAt: string
  expiresAt: string
  permanent: boolean
}

export interface SpecInfo {
  name: string
  userId: number
}

export interface SpecUpdate {
  name: string
  health: number
  maxHealth: number
  armor: number
}

export type InventarioRarity = 'common' | 'rare' | 'epic' | 'legendary' | 'mythic'

export interface InventarioItem {
  id: string
  name: string
  category: string
  subcategory?: string
  rarity: InventarioRarity
  price?: number
  purchasable: boolean
  image?: string
  metadata: Record<string, unknown>
  enabled?: boolean
}

export interface PlayerInventarioEntry {
  item: InventarioItem
  source: string
  sourceRef?: string
  acquiredAt: string
  equipped: boolean
}

export interface InventarioTarget {
  userId: number
  name: string
}

export interface InventarioFilters {
  category?: string
  rarity?: InventarioRarity | ''
  search?: string
  purchasable?: boolean
}
