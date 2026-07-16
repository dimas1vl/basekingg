import imgIconClosePanel from '@/assets/minigames/icon-close-panel.svg'
import imgDividerH from '@/assets/minigames/divider-h.png'
import imgIconCaretRight from '@/assets/minigames/icon-caret-right.svg'
import type { SafeZoneOption } from '@/providers/Visibility'

type Props = {
  zones: SafeZoneOption[]
  onSelect: (zoneId: string) => void
  onClose: () => void
}

export default function SafeZonePanel({ zones, onSelect, onClose }: Props) {
  return (
    <div className="flex flex-col items-start w-[340px] max-h-[483px]">
      <div className="bg-[rgba(29,28,38,0.95)] flex flex-col items-start px-[18px] py-[12px] shrink-0 w-full">
        <div className="border-mg-primary border-l-4 flex h-[24px] items-center justify-between pl-[16px] pr-[12px] w-full">
          <span className="font-termina font-medium text-[12px] text-mg-primary text-center whitespace-nowrap">
            SAFE ZONE
          </span>
          <button onClick={onClose} className="h-[12px] w-[30px] relative cursor-pointer">
            <img alt="" className="absolute inset-[-8.33%_-3.33%] block w-full h-full" src={imgIconClosePanel} />
          </button>
        </div>
      </div>

      <div className="bg-[rgba(29,28,38,0.9)] flex flex-1 flex-col items-center justify-start min-h-0 p-[18px] w-full gap-[10px]">
        <div className="w-full flex flex-col gap-[6px] max-h-[370px] overflow-y-auto pr-[2px]">
          {zones.length === 0 ? (
            <div className="text-[rgba(248,239,255,0.55)] font-termina text-[12px] text-center py-[24px]">
              NENHUMA ZONA DISPONÍVEL
            </div>
          ) : (
            zones.map((z) => (
              <button
                key={z.id}
                onClick={() => onSelect(z.id)}
                className="bg-[rgba(248,239,255,0.05)] border border-[rgba(248,239,255,0.25)] flex h-[44px] items-center justify-between px-[14px] cursor-pointer hover:bg-[rgba(248,239,255,0.12)] transition-colors w-full group"
              >
                <span className="font-termina font-semibold text-[12px] text-mg-light tracking-wider uppercase">
                  {z.label}
                </span>
                <img alt="" src={imgIconCaretRight} className="w-[6px] h-[10px] opacity-60 group-hover:opacity-100 transition-opacity" />
              </button>
            ))
          )}
        </div>
      </div>

      <div className="h-[17px] overflow-hidden relative shrink-0 w-full">
        <div
          className="absolute flex h-[17px] items-center justify-center top-0"
          style={{ left: 'calc(50% + 204.75px)', transform: 'translateX(-50%)', width: '1929.5px' }}
        >
          <div style={{ transform: 'scaleY(-1) rotate(180deg)' }}>
            <img alt="" src={imgDividerH} style={{ width: '1929.5px', height: '17px', display: 'block' }} />
          </div>
        </div>
      </div>
    </div>
  )
}
