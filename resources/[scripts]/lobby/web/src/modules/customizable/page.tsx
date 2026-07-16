import { useState, useMemo, useEffect, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { fetchInventario } from '@inventario/utils/fetchInventario'
import type { InventarioItem, EquippedMap } from '@inventario/modules/inventory/types'
import { SearchIcon } from '@/components/icons'
import { SwitchHeader } from '@/modules/home/switchMode/components/switch-header'
import { CategorySidebar } from './components/category-sidebar'
import { ItemCard } from './components/item-card'
import { SECTIONS, CATEGORIES } from './data'
import type { ClothingItem, ClothingSection, ItemStatus } from './types'

const SUBCATEGORY_TO_SLOT: Record<string, string> = {
  tops: 'tops',
  pants: 'pants',
  shoes: 'shoes',
  hats: 'hat',
  masks: 'mask',
  accessories: 'accessories',
  bags: 'bag',
  pistol: 'primary',
  rifle: 'primary',
  smg: 'primary',
  car: 'car',
  chute: 'chute',
}

const CATEGORY_TO_SLOT: Record<string, string> = {
  weapon_skin: 'primary',
  vehicle_skin: 'car',
  parachute: 'chute',
}

function itemToSlot(item: InventarioItem): string {
  if (item.subcategory && SUBCATEGORY_TO_SLOT[item.subcategory]) {
    return SUBCATEGORY_TO_SLOT[item.subcategory]
  }
  return CATEGORY_TO_SLOT[item.category] ?? item.subcategory ?? item.category
}

function collectEquippedIds(equipped: EquippedMap | undefined): Set<string> {
  const out = new Set<string>()
  if (!equipped) return out
  for (const category of Object.keys(equipped)) {
    const slots = equipped[category] ?? {}
    for (const slot of Object.keys(slots)) {
      const v = slots[slot]
      if (typeof v === 'string') {
        out.add(v)
      } else if (v && typeof v === 'object' && typeof (v as { id?: unknown }).id === 'string') {
        out.add((v as { id: string }).id)
      }
    }
  }
  return out
}

function deriveStatus(
  itemId: string,
  purchasable: boolean,
  equippedIds: Set<string>,
  ownedIds: Set<string>,
): ItemStatus {
  if (equippedIds.has(itemId)) return 'equipped'
  if (ownedIds.has(itemId)) return 'owned'
  if (purchasable) return 'purchasable'
  return 'unavailable'
}

function mergeIntoClothingItems(
  catalog: InventarioItem[],
  ownedIds: Set<string>,
  equippedIds: Set<string>,
): ClothingItem[] {
  return catalog.map((c) => ({
    id: c.id,
    name: c.name.toUpperCase(),
    thumbnail: c.image ?? undefined,
    price: c.price ?? undefined,
    status: deriveStatus(c.id, !!c.purchasable, equippedIds, ownedIds),
    slot: itemToSlot(c),
  }))
}

export default function CustomizablePage() {
  const navigate = useNavigate()

  const [activeSection, setActiveSection] = useState<ClothingSection>('roupas')
  const [activeCategoryId, setActiveCategoryId] = useState(CATEGORIES.roupas[0].id)
  const [selectedItem, setSelectedItem] = useState<ClothingItem | null>(null)
  const [search, setSearch] = useState('')
  const [items, setItems] = useState<ClothingItem[]>([])

  const reload = useCallback(async () => {
    const [inv, catalog] = await Promise.all([
      fetchInventario.getMyInventory(),
      fetchInventario.getCatalog(),
    ])
    const ownedIds = new Set((inv?.items ?? []).map((i) => i.id))
    const equippedIds = collectEquippedIds(inv?.equipped)
    setItems(mergeIntoClothingItems(catalog ?? [], ownedIds, equippedIds))
  }, [])

  useEffect(() => {
    reload()
  }, [reload])

  const handleSectionChange = (section: ClothingSection) => {
    setActiveSection(section)
    setActiveCategoryId(CATEGORIES[section][0].id)
    setSelectedItem(null)
    setSearch('')
  }

  const handleEquip = async (item: ClothingItem) => {
    setItems((prev) =>
      prev.map((i) =>
        i.slot === item.slot
          ? {
              ...i,
              status: i.id === item.id ? 'equipped' : i.status === 'equipped' ? 'owned' : i.status,
            }
          : i,
      ),
    )
    setSelectedItem((prev) => (prev?.id === item.id ? { ...prev, status: 'equipped' } : prev))

    await fetchInventario.equipItems([item.id])
    reload()
  }

  const visibleItems = useMemo(() => {
    return items.filter((i) => {
      const matchSlot = i.slot === activeCategoryId
      const matchSearch = !search || i.name.toLowerCase().includes(search.toLowerCase())
      return matchSlot && matchSearch
    })
  }, [items, activeCategoryId, search])

  const categories = CATEGORIES[activeSection]

  return (
    <div className="flex flex-col w-full h-full px-[5rem] py-[3.2rem] overflow-hidden">
      <SwitchHeader title="CUSTOMIZAR" subtitle="" onBack={() => navigate('/')} />

      <div
        className="flex items-center gap-[0.6rem] px-[3.6rem] shrink-0 h-[3rem]"
        style={{ background: 'linear-gradient(90deg, rgba(0,0,0,0.25) 0%, rgba(0,0,0,0) 100%)' }}
      >
        {SECTIONS.map((sec) => {
          const isActive = sec.id === activeSection
          return (
            <button
              key={sec.id}
              onClick={() => handleSectionChange(sec.id)}
              className="flex items-center justify-center p-[1.2rem]  h-[3rem] text-[1.2rem] font-medium text-[#f8efff] cursor-pointer whitespace-nowrap transition-[background-color] duration-150"
              style={{ backgroundColor: isActive ? '#9d0de9' : 'transparent' }}
            >
              {sec.label}
            </button>
          )
        })}
      </div>

      <div className="flex flex-1 min-h-0 gap-[1.2rem] pt-[2.4rem]">
        <CategorySidebar
          categories={categories}
          selectedId={activeCategoryId}
          onSelect={setActiveCategoryId}
        />

        <div className="flex flex-col gap-[1.2rem] min-h-0">
          <div className="flex items-center gap-[1.2rem] pr-[1.8rem] shrink-0">
            <div
              className="flex items-center gap-[1rem] h-[4.2rem] px-[1.2rem] overflow-hidden"
              style={{ width: '38.4rem', border: '0.1rem solid rgba(248,239,255,0.25)' }}
            >
              <input
                className="flex-1 text-[1.2rem] font-medium text-[rgba(248,239,255,0.55)] bg-transparent outline-none placeholder:text-[rgba(248,239,255,0.55)]"
                placeholder="PESQUISAR ITEM"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
              <SearchIcon
                width={18}
                height={18}
                className="shrink-0 text-[rgba(248,239,255,0.55)]"
              />
            </div>
            <div
              className="flex items-center h-[4.2rem] px-[1.2rem] flex-1 overflow-hidden cursor-pointer"
              style={{ backgroundColor: '#2c2b2e', border: '0.1rem solid rgba(248,239,255,0.15)' }}
            >
              <span className="text-[1.2rem] font-medium text-[rgba(248,239,255,0.55)]">
                FILTRAR
              </span>
            </div>
          </div>

          <div className="flex-1 min-h-0 overflow-y-auto overflow-x-hidden">
            <div
              className="flex flex-wrap gap-x-[1.2rem] gap-y-0 content-start"
              style={{ width: '59.4rem' }}
            >
              {visibleItems.length === 0 ? (
                <div className="flex items-center justify-center w-full h-[20rem]">
                  <span className="text-[1.2rem] font-bold text-[rgba(248,239,255,0.2)] uppercase tracking-widest">
                    Nenhum item encontrado
                  </span>
                </div>
              ) : (
                visibleItems.map((item) => (
                  <ItemCard
                    key={item.id}
                    item={item}
                    selected={selectedItem?.id === item.id}
                    onClick={() => {
                      setSelectedItem(item)
                      if (item.status === 'owned') handleEquip(item)
                    }}
                  />
                ))
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
