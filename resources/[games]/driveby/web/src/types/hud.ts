export interface HudSlot {
  ammo: number | null
  weapon?: string
  label?: string
}

export interface HudData {
  health: number
  armor: number
  ammo: number
  maxAmmo: number
  activeSlot: number
  activeWeapon?: string
  slots: HudSlot[]
  speed: number
  inVehicle: boolean
  kills: number
  deaths: number
  killStreak: number
  players: number
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
}

export interface PhaseData {
  timer: string
  phase: number
  totalPhases: number
  progress: number // 0-1
}

export interface NotifyData {
  time: number
  title: string
  description: string
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
  distance: number
  distanceLabel: string
  vehicleSpeed: number
  altitude: number
  heading: number // 0-359
}
