export type StoreCategoryIcon = 'store' | 'dominance' | 'parachute' | 'gamepad'

export type StoreSubCategory = {
  id: string
  label: string
}

export type StoreCategory = {
  id: string
  label: string
  icon: StoreCategoryIcon
  sub?: StoreSubCategory[]
}

export type StoreItem = {
  id: string
  name: string
  image: string
  price: number
  category: string
  isNew?: boolean
}

export type StoreHero = {
  tag: string
  title: string[]
  cta: string
  image: string
}

const ITEM_IMAGE = new URL('/inventory-item.png', import.meta.url).href
const HERO_IMAGE = new URL('/store-hero.png', import.meta.url).href

export const SHOP_DIVIDER = new URL('/shop-divider.png', import.meta.url).href

export const STORE_CATEGORIES: StoreCategory[] = [
  { id: 'all', label: 'TODOS OS ITENS', icon: 'store' },
  { id: 'domination', label: 'DOMINAÇÃO', icon: 'dominance' },
  {
    id: 'battle-royale',
    label: 'BATTLE ROYALE / END GAME',
    icon: 'parachute',
    sub: [
      { id: 'pacotes', label: 'PACOTES' },
      { id: 'caixas', label: 'CAIXAS' },
      { id: 'clan', label: 'CLAN' },
    ],
  },
  { id: 'mini-games', label: 'MINI GAMES', icon: 'gamepad' },
]

/** Título da seção conforme a categoria/subcategoria selecionada. */
export function getCategoryLabel(id: string): string {
  for (const cat of STORE_CATEGORIES) {
    if (cat.id === id) return cat.label
    const sub = cat.sub?.find((s) => s.id === id)
    if (sub) return sub.label
  }
  return 'TODOS OS ITENS'
}

export const STORE_HERO: StoreHero = {
  tag: 'NOVIDADE',
  title: ['PACOTE', 'KINGG'],
  cta: 'APROVEITE AGORA',
  image: HERO_IMAGE,
}

export const MOCK_STORE_ITEMS: StoreItem[] = Array.from({ length: 15 }).map((_, i) => ({
  id: `store-${i}`,
  name: 'NOME DO ITEM - 30 DIAS',
  image: ITEM_IMAGE,
  price: 1000,
  category: i % 3 === 0 ? 'pacotes' : i % 3 === 1 ? 'caixas' : 'clan',
  isNew: i < 2,
}))
