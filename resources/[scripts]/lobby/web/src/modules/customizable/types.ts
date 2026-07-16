export type ItemStatus = 'equipped' | 'owned' | 'purchasable' | 'unavailable'

export type ClothingItem = {
  id: string
  name: string
  thumbnail?: string
  price?: number
  status: ItemStatus
  slot: string
}

export type ClothingSection = 'roupas' | 'armamento' | 'veiculos' | 'paraquedas'

export type ClothingCategory = {
  id: string
  icon: string
}
