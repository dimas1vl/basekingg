export interface NavbarItem {
  label: string
  path: string
  gold?: boolean
}

export const NAVBAR_ITEMS: NavbarItem[] = [
  { label: 'INICIO',    path: '/' },
  { label: 'PASSE',     path: '/pass' },
  { label: 'LOJA',      path: '/store', gold: true },
  { label: 'CUSTOMIZAR', path: '/custom' },
  { label: 'RANKING',   path: '/ranking' },
  { label: 'CAIXAS',    path: '/boxes' },
]
