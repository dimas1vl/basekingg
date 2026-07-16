export interface AbilityData {
  id: string
  title: string
  description: string
}

export interface AbilityVisual {
  icon: string
  iconWidth: string
  iconHeight: string
}

export type Ability = AbilityData & AbilityVisual
