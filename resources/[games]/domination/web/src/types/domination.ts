// Tipos do protocolo NUI dos overlays da Dominação.
// Espelham exatamente os payloads montados pelo servidor/cliente Lua
// (server/sv_progression.lua, sv_vehicles.lua, sv_team.lua, sv_combat.lua).

/* ===================== Loja de armamentos (F2) ===================== */
export interface ShopWeapon {
  id: string
  label: string
  icon: string
  level: number
  price: number
  owned: boolean
  equipped: boolean
  locked: boolean
}

export interface ShopCategory {
  key: string
  label: string
  slot?: number
  weapons: ShopWeapon[]
}

export interface ShopState {
  level: number
  xp?: number
  xpPerLevel?: number
  xpIntoLevel?: number
  gems: number
  kills?: number
  deaths?: number
  equipped?: Record<string, string>
  categories: ShopCategory[]
}

/* ===================== Veículos (F3) ===================== */
export type VehicleAction = 'spawn' | 'buy' | 'req' | 'locked'

export interface VehicleItem {
  id: string
  label: string
  image: string
  level: number
  price: number
  requires?: string
  action: VehicleAction
  favorite: boolean
}

export interface VehicleCategory {
  key: string
  label: string
  vehicles: VehicleItem[]
}

export interface VehicleState {
  level: number
  gems: number
  imageBase: string
  categories: VehicleCategory[]
}

/* ===================== Spawn (F5) ===================== */
export interface SpawnZone {
  id: string | number
  label: string
}

export interface SpawnState {
  zones: SpawnZone[]
  current: string | number | null
}

/* ===================== Death card / respawn ===================== */
export interface DeathCard {
  self: boolean
  id: number
  name: string
  clan?: string | null
  level: number
  gems: number
  kills: number
  deaths: number
  ratio: number
  ping: number
  they: number
  me: number
}

export interface RespawnPayload {
  visible: boolean
  ready?: boolean
  ms?: number
  total?: number
}

/* ===================== Time (hub F1) ===================== */
export type TeamRole = 'lider' | 'gerente' | 'sublider' | 'recrutador' | 'membro'

export interface TeamMember {
  id: number
  name: string
  role: TeamRole
  online: boolean
  lastLogin?: string | null
}

export interface TeamPerms {
  invite: boolean
  kick: boolean
  promote: boolean
  setDiscord: boolean
}

export interface TeamInvite {
  team: string
  from: string
}

export interface TeamState {
  hasTeam: boolean
  invite?: TeamInvite
  id?: number
  name?: string
  premium?: boolean
  discord?: string | null
  maxMembers?: number
  memberCount?: number
  onlineCount?: number
  counts?: Partial<Record<TeamRole, number>>
  caps?: Partial<Record<TeamRole, number>>
  roleLabels?: Partial<Record<TeamRole, string>>
  myRole?: TeamRole
  perms?: TeamPerms
  members?: TeamMember[]
}

/* ===================== Captura / status / recompensa ===================== */
export interface CapturePayload {
  visible: boolean
  zone?: string
  team?: string
  members?: number
  pct?: number
  color?: number[]
  contested?: boolean
}

export interface StatusPayload {
  visible: boolean
  kind?: 'ghost' | 'danger'
  label?: string | null
  ms?: number
}

export interface RewardPayload {
  xp?: number
  money?: number
}
