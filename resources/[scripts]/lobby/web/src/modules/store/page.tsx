import { useMemo, useState } from 'react'
import { useToast } from '@/components/ui'
import { fetchData } from '@/utils/fetchData'
import {
  getCategoryLabel,
  MOCK_STORE_ITEMS,
  SHOP_DIVIDER,
  STORE_CATEGORIES,
  STORE_HERO,
  type StoreItem,
} from './data'
import { CategorySidebar } from './components/category-sidebar'
import { StoreItemCard } from './components/store-item-card'
import { PurchaseModal } from './components/purchase-modal'

export default function StorePage() {
  const { addToast } = useToast()
  const [category, setCategory] = useState('all')
  const [selectedItem, setSelectedItem] = useState<StoreItem | null>(null)

  const items = useMemo(
    () => (category === 'all' ? MOCK_STORE_ITEMS : MOCK_STORE_ITEMS.filter((i) => i.category === category)),
    [category],
  )

  const handleConfirm = async () => {
    if (!selectedItem) return
    const item = selectedItem
    setSelectedItem(null)
    const res = await fetchData<{ ok: boolean; error?: string }>('buyStoreItem', { itemId: item.id })
    if (res?.ok) {
      addToast('Compra realizada com sucesso!', 'success')
    } else {
      addToast(res?.error ?? 'Erro ao realizar a compra', 'error')
    }
  }

  return (
    <div className="relative flex w-full h-full overflow-hidden">
      {/* Fundo escuro com brilho radial (design LOJA) */}
      <div className="absolute inset-0 -z-10 bg-[#101012]" />
      <div
        className="absolute inset-0 -z-10"
        style={{
          background:
            'radial-gradient(115rem 65rem at 50% 40%, rgba(29,28,34,0.9) 0%, rgba(29,28,34,0) 70%)',
        }}
      />

      <div className="flex gap-[1.2rem] w-full h-full px-[5rem] pt-[1.8rem] pb-[1.8rem] min-h-0">
        {/* Sidebar de categorias */}
        <CategorySidebar categories={STORE_CATEGORIES} selected={category} onSelect={setCategory} />

        {/* Conteúdo */}
        <div className="flex flex-col gap-[1.2rem] flex-1 min-w-0 h-full min-h-0">
          {/* Banner */}
          <div className="relative h-[22.5rem] w-full border-4 border-[#4d4c55] border-solid overflow-hidden shrink-0">
            <img
              alt=""
              src={STORE_HERO.image}
              className="absolute inset-0 size-full object-cover opacity-95 pointer-events-none"
            />
            <div className="absolute inset-0 bg-gradient-to-r from-[#131313] from-[17%] to-[45%] to-transparent pointer-events-none" />
            <div className="absolute left-[4.4rem] top-1/2 -translate-y-1/2 flex flex-col gap-[1.2rem]">
              <div className="flex flex-col gap-[0.6rem] items-start">
                <div className="flex items-center bg-[#c8fe4e] px-[0.8rem] py-[0.2rem]">
                  <span className="text-[1.6rem] font-bold text-[#1d1c26] whitespace-nowrap">
                    {STORE_HERO.tag}
                  </span>
                </div>
                <div className="flex gap-[1.2rem]">
                  {STORE_HERO.title.map((word) => (
                    <span key={word} className="text-[3.2rem] font-bold text-[#c8fe4e] whitespace-nowrap">
                      {word}
                    </span>
                  ))}
                </div>
              </div>
              <button
                onClick={() => fetchData('openStorePackage')}
                className="flex items-center justify-center h-[5.6rem] w-[31.8rem] px-[1.8rem] bg-[rgba(248,239,255,0.1)] border-2 border-[#e8ffb5] border-solid cursor-pointer transition-colors hover:bg-[rgba(232,255,181,0.15)]"
              >
                <span className="text-[2rem] font-semibold text-[#f8efff] whitespace-nowrap">
                  {STORE_HERO.cta}
                </span>
              </button>
            </div>
          </div>

          {/* Título da seção (muda conforme a categoria) */}
          <div className="flex items-center gap-[1.2rem] shrink-0">
            <span className="text-[1.6rem] font-bold text-[#f8efff] whitespace-nowrap uppercase">
              {getCategoryLabel(category)}
            </span>
            <img
              src={SHOP_DIVIDER}
              alt=""
              className="flex-1 min-w-0 h-[1.1rem] object-fill pointer-events-none"
            />
          </div>

          {/* Grid de itens */}
          <div className="flex-1 min-h-0 overflow-y-auto pr-[0.8rem]">
            {items.length ? (
              <div className="grid grid-cols-5 gap-x-[1.5rem] gap-y-[1.4rem]">
                {items.map((item) => (
                  <StoreItemCard key={item.id} item={item} onClick={() => setSelectedItem(item)} />
                ))}
              </div>
            ) : (
              <div className="flex items-center justify-center h-full opacity-55">
                <span className="text-[1.4rem] font-medium text-[#f8efff]">
                  NENHUM ITEM NESSA CATEGORIA
                </span>
              </div>
            )}
          </div>
        </div>
      </div>

      {selectedItem && (
        <PurchaseModal
          item={selectedItem}
          onCancel={() => setSelectedItem(null)}
          onConfirm={handleConfirm}
        />
      )}
    </div>
  )
}
