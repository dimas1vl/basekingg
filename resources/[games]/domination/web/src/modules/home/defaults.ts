import type { HudData } from '@/types/hud'

export const DEFAULT_HUD: HudData = {
  health: 100,
  armor: 100,
  ammo: 30,
  maxAmmo: 140,
  activeSlot: 1,
  slots: [{ ammo: 1 }, { ammo: 1 }, { ammo: 1 }, { ammo: 1 }, { ammo: 1 }],
  speed: 0,
  inVehicle: false,
  kills: 0,
  deaths: 0,
  killStreak: 0,
  players: 1,
}
