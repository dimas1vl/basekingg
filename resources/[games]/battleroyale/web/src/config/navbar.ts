import type { ElementType } from 'react'

export interface NavbarItem {
  label: string
  path: string
  icon?: ElementType
}

export const NAVBAR_ITEMS: NavbarItem[] = []
