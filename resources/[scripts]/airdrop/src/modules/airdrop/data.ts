import iconRevive from '@/assets/icon-revive.svg'
import iconVant from '@/assets/icon-vant.svg'
import iconRadar from '@/assets/icon-radar.svg'
import type { AbilityData, AbilityVisual } from './types'

/**
 * Frontend-owned visuals keyed by ability id. The Lua backend only sends data
 * (id/title/description); the icon for each id is resolved here so bundled
 * assets never have to travel over the NUI bridge. To support a new ability,
 * add its id here and have the backend include that id in `getAbilities`.
 */
export const ABILITY_VISUALS: Record<string, AbilityVisual> = {
  revive: { icon: iconRevive, iconWidth: '7.5rem', iconHeight: '4.6rem' },
  vant: { icon: iconVant, iconWidth: '7.5rem', iconHeight: '5rem' },
  radar: { icon: iconRadar, iconWidth: '7.5rem', iconHeight: '5rem' },
}

/** Used when the backend sends an id we don't have artwork for. */
export const FALLBACK_VISUAL: AbilityVisual = {
  icon: iconRevive,
  iconWidth: '7.5rem',
  iconHeight: '4.6rem',
}

/** Resolve the full visual config for a given ability id. */
export function resolveVisual(id: string): AbilityVisual {
  return ABILITY_VISUALS[id] ?? FALLBACK_VISUAL
}

/**
 * Mock backend payload — exactly what Lua should return from the `getAbilities`
 * callback. Used in the browser and as a fallback when no backend responds.
 */
export const MOCK_ABILITIES: AbilityData[] = [
  { id: 'revive', title: 'REVIVE', description: 'REVIVER TODOS\nOS ALIADOS' },
  { id: 'vant', title: 'VANT', description: 'REVELAR\nINIMIGOS' },
  { id: 'radar', title: 'RADAR', description: 'REVELAR PROXIMA SAFE' },
]
