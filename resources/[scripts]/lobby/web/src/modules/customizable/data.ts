import type { ClothingCategory, ClothingItem, ClothingSection } from './types'

// Circuit background used inside item cards — replace with a static /public asset
export const CARD_CIRCUIT_BG = 'https://www.figma.com/api/mcp/asset/d56846da-6323-4269-9601-7145b03261fb'

// Character placeholder used when item has no thumbnail — replace with static asset
export const CARD_CHAR_PLACEHOLDER = 'https://www.figma.com/api/mcp/asset/aced9d00-d93a-4d92-98e4-c606eafdb346'

export const SECTIONS: { id: ClothingSection; label: string }[] = [
  { id: 'roupas',    label: 'ROUPAS' },
  { id: 'armamento', label: 'ARMAMENTO' },
  { id: 'veiculos',  label: 'VEÍCULOS' },
  { id: 'paraquedas',label: 'PARAQUEDAS' },
]

// Category icons per section — replace icon URLs with static /public assets
export const CATEGORIES: Record<ClothingSection, ClothingCategory[]> = {
  roupas: [
    { id: 'tops',        icon: 'https://www.figma.com/api/mcp/asset/71b20abf-7076-41d2-9afc-d121387c57cb' },
    { id: 'pants',       icon: 'https://www.figma.com/api/mcp/asset/71b20abf-7076-41d2-9afc-d121387c57cb' },
    { id: 'shoes',       icon: 'https://www.figma.com/api/mcp/asset/71b20abf-7076-41d2-9afc-d121387c57cb' },
    { id: 'hat',         icon: 'https://www.figma.com/api/mcp/asset/71b20abf-7076-41d2-9afc-d121387c57cb' },
    { id: 'mask',        icon: 'https://www.figma.com/api/mcp/asset/71b20abf-7076-41d2-9afc-d121387c57cb' },
    { id: 'accessories', icon: 'https://www.figma.com/api/mcp/asset/71b20abf-7076-41d2-9afc-d121387c57cb' },
    { id: 'bag',         icon: 'https://www.figma.com/api/mcp/asset/71b20abf-7076-41d2-9afc-d121387c57cb' },
  ],
  armamento:  [{ id: 'primary',  icon: 'https://www.figma.com/api/mcp/asset/71b20abf-7076-41d2-9afc-d121387c57cb' }],
  veiculos:   [{ id: 'car',      icon: 'https://www.figma.com/api/mcp/asset/71b20abf-7076-41d2-9afc-d121387c57cb' }],
  paraquedas: [{ id: 'chute',    icon: 'https://www.figma.com/api/mcp/asset/71b20abf-7076-41d2-9afc-d121387c57cb' }],
}

export const DIVIDER_COLOR: Record<string, string> = {
  equipped:    '#fedb4e',
  owned:       '#c8fe4e',
  purchasable: '#9d0de9',
  unavailable: '#4d4c55',
}

export const MOCK_ITEMS: ClothingItem[] = [
  { id: '1',  name: 'CAMISETA KINGG',     status: 'equipped',    slot: 'tops',        price: undefined },
  { id: '2',  name: 'CAMISETA VERDE',     status: 'owned',       slot: 'tops',        price: undefined },
  { id: '3',  name: 'CAMISETA CAMO',      status: 'purchasable', slot: 'tops',        price: 1000 },
  { id: '4',  name: 'CAMISETA PRETA',     status: 'purchasable', slot: 'tops',        price: 1000 },
  { id: '5',  name: 'CAMISETA EXCLUSIVA', status: 'unavailable', slot: 'tops',        price: undefined },
  { id: '6',  name: 'CAMISETA DROP',      status: 'unavailable', slot: 'tops',        price: undefined },
  { id: '7',  name: 'CAMISETA EVENTO',    status: 'unavailable', slot: 'tops',        price: undefined },
  { id: '8',  name: 'CAMISETA ELITE',     status: 'unavailable', slot: 'tops',        price: undefined },
  { id: '9',  name: 'JEANS AZUL',         status: 'equipped',    slot: 'pants',       price: undefined },
  { id: '10', name: 'JEANS RASGADO',      status: 'owned',       slot: 'pants',       price: undefined },
  { id: '11', name: 'SHORTS PRETO',       status: 'purchasable', slot: 'pants',       price: 800 },
  { id: '12', name: 'TÊNIS BRANCO',       status: 'equipped',    slot: 'shoes',       price: undefined },
  { id: '13', name: 'TÊNIS KINGG',        status: 'purchasable', slot: 'shoes',       price: 1500 },
  { id: '14', name: 'BONÉ KINGG',         status: 'owned',       slot: 'hat',         price: undefined },
  { id: '15', name: 'CAPACETE TÁTICO',    status: 'unavailable', slot: 'hat',         price: undefined },
]
