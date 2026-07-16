export interface HudSlot {
  name: string
  amount: number
  image?: string
}

export interface HudData {
  health: number
  armor: number
  ammo: number
  maxAmmo: number
  activeSlot: number
  slots: Array<HudSlot | false>
  speed: number
  kills: number
}

export interface SquadMember {
  slot: number
  name: string
  health: number
  armor: number
  alive: boolean
  speaking: boolean
  badgeColor: string
}

export interface KillEntry {
  id: number
  killer: string
  victim: string
  killerIsTeam: boolean
  victimIsTeam: boolean
  weapon?: string
  weaponImage?: string
}

export interface PhaseData {
  timer: string
  phase: number
  totalPhases: number
  progress: number // 0-1
}

export interface SafeZoneData {
  visible: boolean
  title: string
  message: string
}

export interface InteractionData {
  visible: boolean
  key: string
  action: string
  detail: string
  detailValue: string
}

export interface ActionData {
  visible: boolean
  type: 'medkit' | 'reload' | null
  text: string      // texto exibido na barra (ex: "USANDO KIT MEDICO")
  cancelKey: string
  progress: number  // 0-1, preenche do centro para as pontas
}

export interface MetersData {
  visible: boolean
  distance: number
  distanceLabel: string
  vehicleSpeed: number
  altitude: number
  heading: number // 0-359
}

export interface MatchAliveData {
  players: number
  squads: number
}

export interface MinimapFrame {
  frame: { x: number; y: number; w: number; h: number }
  screen: { width: number; height: number }
}

export interface ShortcutItem {
  key: string
  label: string
}

export interface PregameShortcuts {
  visible: boolean
  passive: boolean
  current?: number
  max?: number
}
