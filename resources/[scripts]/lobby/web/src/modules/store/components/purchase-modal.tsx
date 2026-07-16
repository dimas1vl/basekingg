import { SlashesIcon } from '@/components/icons'
import type { StoreItem } from '../data'

type PurchaseModalProps = {
  item: StoreItem
  onCancel: () => void
  onConfirm: () => void
}

export function PurchaseModal({ item, onCancel, onConfirm }: PurchaseModalProps) {
  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-[rgba(29,28,38,0.85)] animate-[fadeIn_0.15s_ease-out]"
      onClick={onCancel}
    >
      <div
        className="flex flex-col items-center w-[41rem]"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex flex-col w-full p-[0.2rem] border-2 border-[#4d4c55] border-solid">
          {/* Cabeçalho */}
          <div className="flex items-center justify-center gap-[1rem] h-[3.4rem] px-[1.8rem] py-[0.8rem] bg-[#1d1c26]">
            <SlashesIcon width={30} height={12} className="text-[#c8fe4e]" />
            <span className="text-[1.4rem] font-semibold text-[#c8fe4e] whitespace-nowrap">COMPRA</span>
            <SlashesIcon width={30} height={12} className="text-[#c8fe4e]" />
          </div>

          {/* Corpo */}
          <div className="flex flex-col gap-[1.2rem] items-center p-[0.8rem] bg-[#17161c]">
            <span className="text-[1.4rem] font-medium text-[#f8efff] opacity-55 text-center whitespace-nowrap overflow-hidden text-ellipsis">
              DESEJA CONFIRMAR ESSA COMPRA?
            </span>

            <div className="relative w-full h-[16.8rem] bg-gradient-to-b from-[#1e1f26] to-[#2b2b2b] overflow-hidden">
              <img
                alt={item.name}
                src={item.image}
                className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 h-[85%] max-w-none object-contain pointer-events-none"
              />
              <div className="absolute left-0 right-0 bottom-0 flex items-center justify-center h-[3.1rem] px-[1rem] bg-[rgba(0,0,0,0.35)]">
                <span className="text-[1.2rem] font-medium text-[#f8efff] text-center whitespace-nowrap">
                  {item.name}
                </span>
              </div>
            </div>

            <div className="flex gap-[1.2rem] w-full">
              <button
                onClick={onCancel}
                className="flex flex-1 min-w-0 h-[4.4rem] items-center justify-center px-[1.8rem] bg-[rgba(248,239,255,0.05)] border-2 border-[rgba(248,239,255,0.1)] border-solid cursor-pointer transition-colors hover:bg-[rgba(248,239,255,0.1)]"
              >
                <span className="text-[1.6rem] font-bold text-[#f8efff] whitespace-nowrap">CANCELAR</span>
              </button>
              <button
                onClick={onConfirm}
                className="flex flex-1 min-w-0 h-[4.4rem] items-center justify-center px-[1.8rem] bg-[rgba(248,239,255,0.1)] border-2 border-[rgba(248,239,255,0.1)] border-solid cursor-pointer transition-colors hover:bg-[rgba(200,254,78,0.15)] hover:border-[#c8fe4e]"
              >
                <span className="text-[1.6rem] font-bold text-[#f8efff] whitespace-nowrap">CONFIRMAR</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
