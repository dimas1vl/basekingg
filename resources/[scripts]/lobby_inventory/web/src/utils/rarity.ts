import type { Rarity } from '@inventario/modules/inventory/types'

// Single source of truth for rarity colors used by badges, borders and chips.
// Keep in sync with whatever the Lua side may render in chat/notifications.
export const RARITY_COLOR: Record<Rarity, string> = {
  common: '#9ca3af',
  rare: '#4f8dff',
  epic: '#a855f7',
  legendary: '#e0a73a',
  mythic: '#e0566b',
}

export const RARITY_LABEL: Record<Rarity, string> = {
  common: 'COMUM',
  rare: 'RARO',
  epic: 'ÉPICO',
  legendary: 'LENDÁRIO',
  mythic: 'MÍTICO',
}

const ORDER: Record<Rarity, number> = {
  common: 0,
  rare: 1,
  epic: 2,
  legendary: 3,
  mythic: 4,
}

export function getRarityColor(rarity: Rarity | undefined): string {
  return rarity ? RARITY_COLOR[rarity] : RARITY_COLOR.common
}

export function getRarityLabel(rarity: Rarity | undefined): string {
  return rarity ? RARITY_LABEL[rarity] : RARITY_LABEL.common
}

export function compareRarity(a: Rarity, b: Rarity): number {
  return ORDER[a] - ORDER[b]
}
