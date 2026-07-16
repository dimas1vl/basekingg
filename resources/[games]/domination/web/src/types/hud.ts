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

export interface KillEntry {
  id: number
  killer: string
  victim: string
  killerIsTeam: boolean
  victimIsTeam: boolean
}
