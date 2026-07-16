export type ProfileTab = 'info' | 'inventory' | 'settings'

export type Achievement = {
  id: string
  name: string
  icon?: string
  unlocked: boolean
}

export type ClanInfo = {
  tag: string
  name: string
  members: number
  trophies: number[]
  leader: number
}

export type ProfileComment = {
  id: string
  name: string
  avatar?: string
  date: string
  text: string
}

export type InventoryItem = {
  id: string
  name: string
  image: string
  status: string
}

export type ProfileSettingKey =
  | 'public'
  | 'stats'
  | 'wins'
  | 'kills'
  | 'kd'
  | 'comments'
  | 'achievements'
  | 'clan'

export type ProfileSetting = {
  key: ProfileSettingKey
  label: string
  value: boolean
}

const ITEM_IMAGE = new URL('/inventory-item.png', import.meta.url).href

/** Total de conquistas disponíveis no jogo. */
export const TOTAL_ACHIEVEMENTS = 32

/** Quantidade de slots exibidos na vitrine de conquistas. */
export const ACHIEVEMENT_SLOTS = 15

export const MOCK_CLAN: ClanInfo = {
  tag: 'KZN',
  name: 'KillZone',
  members: 8,
  trophies: [8, 8, 8],
  leader: 8,
}

export const MOCK_COMMENTS: ProfileComment[] = Array.from({ length: 14 }).map((_, i) => ({
  id: `c-${i}`,
  name: 'rAccoZr',
  date: '21/06/2026',
  text: 'Melhor jogador da historiaaa!!!!',
}))

export const MOCK_INVENTORY: InventoryItem[] = Array.from({ length: 12 }).map((_, i) => ({
  id: `item-${i}`,
  name: 'NOME DO ITEM - 30 DIAS',
  image: ITEM_IMAGE,
  status: 'ADQUIRIDO',
}))

export const DEFAULT_SETTINGS: ProfileSetting[] = [
  { key: 'public', label: 'VISIVEL PARA O PUBLICO', value: true },
  { key: 'stats', label: 'MOSTRAR ESTATISTICAS', value: false },
  { key: 'wins', label: 'MOSTRAR VITÓRIAS', value: true },
  { key: 'kills', label: 'MOSTRAR ELIMINAÇÕES', value: true },
  { key: 'kd', label: 'MOSTRAR K/D', value: true },
  { key: 'comments', label: 'MOSTRAR COMENTÁRIOS', value: true },
  { key: 'achievements', label: 'MOSTRAR CONQUISTAS', value: true },
  { key: 'clan', label: 'MOSTRAR CLAN', value: true },
]

export const COMMENTS_PER_PAGE = 6
