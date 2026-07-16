export type Rarity = 'blue' | 'green' | 'orange' | 'purple' | 'gold'

export const RARITY_COLOR: Record<Rarity, string> = {
  blue: '#4a9eff',
  green: '#8bd346',
  orange: '#f2a13a',
  purple: '#b44dff',
  gold: '#fedb4e',
}

const RARITY_ORDER: Rarity[] = ['blue', 'green', 'orange', 'purple', 'gold']

export type Box = {
  id: string
  name: string
  image: string
  status: string
}

export type RouletteItem = {
  id: string
  name: string
  image: string
  rarity: Rarity
}

const ITEM_IMAGE = new URL('/inventory-item.png', import.meta.url).href

export const CAIXAS_BG = new URL('/caixas-bg.jpg', import.meta.url).href

export const MOCK_BOXES: Box[] = Array.from({ length: 15 }).map((_, i) => ({
  id: `box-${i}`,
  name: 'NOME DO ITEM - 30 DIAS',
  image: ITEM_IMAGE,
  status: 'ADQUIRIDO',
}))

/** Pool de prêmios de uma caixa (usado na roleta). */
export const ROULETTE_POOL: RouletteItem[] = Array.from({ length: 8 }).map((_, i) => ({
  id: `prize-${i}`,
  name: 'NOME DO ITEM - 30 DIAS',
  image: ITEM_IMAGE,
  rarity: RARITY_ORDER[i % RARITY_ORDER.length],
}))

/** Gera uma fita (reel) com um vencedor numa posição fixa perto do fim. */
export function buildReel(
  pool: RouletteItem[],
  winner: RouletteItem,
  length: number,
  winnerIndex: number,
): RouletteItem[] {
  const reel: RouletteItem[] = []
  for (let i = 0; i < length; i++) {
    if (i === winnerIndex) {
      reel.push({ ...winner, id: `reel-${i}` })
    } else {
      // Distribuição pseudo-aleatória mas determinística (sem Math.random no build).
      const pick = pool[(i * 7 + 3) % pool.length]
      reel.push({ ...pick, id: `reel-${i}` })
    }
  }
  return reel
}
