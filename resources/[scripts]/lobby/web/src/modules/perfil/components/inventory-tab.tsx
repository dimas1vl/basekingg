import { DividerIcon } from '@/components/icons'
import { MOCK_INVENTORY, type InventoryItem } from '../data'
import { CountTag, Panel, SectionHeader } from './section'

type InventoryTabProps = {
  items?: InventoryItem[]
}

export function InventoryTab({ items = MOCK_INVENTORY }: InventoryTabProps) {
  return (
    <div className="flex h-full w-full px-[5rem] pb-[5rem] pt-[1.2rem] min-h-0">
      <Panel className="flex-1 min-w-0 h-full">
        <SectionHeader
          title="INVENTÁRIO"
          subtitle="SEUS ITENS CONSUMIVEIS FICAM AQUI"
          tag={<CountTag>{items.length}</CountTag>}
        />
        <div className="flex-1 min-h-0 bg-[rgba(29,28,38,0.55)] overflow-y-auto p-[2.4rem]">
          {items.length ? (
            <div className="grid grid-cols-6 gap-x-[2rem] gap-y-[2.4rem]">
              {items.map((item) => (
                <ItemCard key={item.id} item={item} />
              ))}
            </div>
          ) : (
            <div className="flex items-center justify-center h-full opacity-55">
              <span className="text-[1.2rem] font-medium text-[#f8efff]">
                NENHUM ITEM NO INVENTÁRIO
              </span>
            </div>
          )}
        </div>
      </Panel>
    </div>
  )
}

function ItemCard({ item }: { item: InventoryItem }) {
  return (
    <div className="flex flex-col">
      <div className="flex flex-col gap-[0.6rem] pt-[0.4rem] px-[0.4rem] pb-[0.6rem] bg-[rgba(248,239,255,0.1)]">
        <div className="relative h-[22rem] w-full border-2 border-[rgba(248,239,255,0.15)] border-solid overflow-hidden bg-gradient-to-b from-[#1e1f26] to-[#2b2b2b]">
          <img
            alt={item.name}
            src={item.image}
            className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 h-[75%] max-w-none object-contain pointer-events-none"
          />
          <div className="absolute left-0 right-0 bottom-0 flex items-center justify-center h-[3.1rem] px-[1rem] bg-[rgba(0,0,0,0.35)]">
            <span className="text-[1.2rem] font-medium text-[#f8efff] text-center whitespace-nowrap overflow-hidden text-ellipsis">
              {item.name}
            </span>
          </div>
        </div>
        <div className="flex items-center justify-center">
          <span className="text-[1.4rem] font-medium text-[#f8efff] whitespace-nowrap">
            {item.status}
          </span>
        </div>
      </div>
      <div className="h-[1.2rem] w-full overflow-hidden">
        <DividerIcon width="100%" className="text-[#c8fe4e] opacity-60" />
      </div>
    </div>
  )
}
