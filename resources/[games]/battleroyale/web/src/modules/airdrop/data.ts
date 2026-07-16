import iconRevive from '@/assets/airdrop/icon-revive.svg'
import iconVant from '@/assets/airdrop/icon-vant.svg'
import iconRadar from '@/assets/airdrop/icon-radar.svg'
import type { AbilityData, AbilityVisual } from './types'

export const ABILITY_VISUALS: Record<string, AbilityVisual> = {
  revive: { icon: iconRevive, iconWidth: '7.5rem', iconHeight: '4.6rem' },
  vant: { icon: iconVant, iconWidth: '7.5rem', iconHeight: '5rem' },
  radar: { icon: iconRadar, iconWidth: '7.5rem', iconHeight: '5rem' },
}

export const FALLBACK_VISUAL: AbilityVisual = {
  icon: iconRevive,
  iconWidth: '7.5rem',
  iconHeight: '4.6rem',
}

export function resolveVisual(id: string): AbilityVisual {
  return ABILITY_VISUALS[id] ?? FALLBACK_VISUAL
}

export const MOCK_ABILITIES: AbilityData[] = [
  { id: 'revive', title: 'REVIVE', description: 'REVIVER TODOS\nOS ALIADOS' },
  { id: 'vant', title: 'VANT', description: 'REVELAR\nINIMIGOS' },
  { id: 'radar', title: 'RADAR', description: 'REVELAR PROXIMA SAFE' },
]
