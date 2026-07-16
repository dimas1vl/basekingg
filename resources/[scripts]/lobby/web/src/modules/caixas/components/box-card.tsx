import { DividerIcon } from '@/components/icons'
import type { Box } from '../data'

type BoxCardProps = {
  box: Box
  onClick: () => void
}

export function BoxCard({ box, onClick }: BoxCardProps) {
  return (
    <button onClick={onClick} className="flex flex-col text-left cursor-pointer group">
      <div className="flex flex-col gap-[0.6rem] pt-[0.4rem] px-[0.4rem] pb-[0.6rem] bg-[rgba(248,239,255,0.1)] transition-colors group-hover:bg-[rgba(248,239,255,0.16)]">
        <div className="relative h-[22rem] w-full border-2 border-[rgba(248,239,255,0.15)] border-solid overflow-hidden bg-gradient-to-b from-[#1e1f26] to-[#2b2b2b]">
          <img
            alt={box.name}
            src={box.image}
            className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 h-[75%] max-w-none object-contain pointer-events-none transition-transform group-hover:scale-105"
          />
          <div className="absolute left-0 right-0 bottom-0 flex items-center justify-center h-[3.1rem] px-[1rem] bg-[rgba(0,0,0,0.35)]">
            <span className="text-[1.2rem] font-medium text-[#f8efff] text-center whitespace-nowrap overflow-hidden text-ellipsis">
              {box.name}
            </span>
          </div>
        </div>
        <div className="flex items-center justify-center">
          <span className="text-[1.4rem] font-medium text-[#f8efff] whitespace-nowrap">{box.status}</span>
        </div>
      </div>
      <div className="h-[1.2rem] w-full overflow-hidden">
        <DividerIcon width="100%" className="text-[#c8fe4e] opacity-60" />
      </div>
    </button>
  )
}
