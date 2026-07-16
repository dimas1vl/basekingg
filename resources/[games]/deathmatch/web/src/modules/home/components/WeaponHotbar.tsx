import type { HudData } from '@/types/hud'
import { imgVector1, imgUnion } from '../assets'

interface WeaponHotbarProps {
  health: number
  armor: number
  slots: HudData['slots']
  activeSlot: number
}

interface HintProps {
  keyLabel: string
  action: string
}

function ControlHint({ keyLabel, action }: HintProps) {
  return (
    <div className="flex items-center gap-[6px] shrink-0">
      <div
        className="flex items-center justify-center h-[18px] min-w-[26px] px-[6px] font-['Termina:Bold',sans-serif] text-[10px] tracking-wider"
        style={{ backgroundColor: '#c8fe4e', color: '#1d1c26' }}
      >
        {keyLabel}
      </div>
      <span className="font-['Termina:Medium',sans-serif] text-[10px] tracking-wider text-[#f8efff] whitespace-nowrap">
        {action}
      </span>
    </div>
  )
}

export default function WeaponHotbar({ health, armor, slots }: WeaponHotbarProps) {
  const slotCount = (slots && slots.length) || 0
  const slotsLabel = slotCount > 1 ? `1-${slotCount}` : slotCount === 1 ? '1' : '1-7'

  return (
    <div className="-translate-x-1/2 absolute bottom-[35px] content-stretch flex flex-col gap-[6px] items-start left-1/2 w-[480px]">
      <div className="bg-[rgba(29,28,38,0.92)] flex items-center justify-around gap-[14px] w-full h-[28px] px-[14px] border-l-[3px] border-r-[3px] border-solid border-[#e8ffb5]">
        <ControlHint keyLabel="TAB" action="ESTATÍSTICAS" />
        <ControlHint keyLabel="F" action="SAIR DA PARTIDA" />
        <ControlHint keyLabel={slotsLabel} action="ARMAS" />
      </div>

      <div className="content-stretch flex flex-col gap-[4px] items-start relative shrink-0 w-full">
        <div className="bg-[rgba(29,28,38,0.85)] h-[6px] overflow-clip relative shrink-0 w-full">
          <div
            className="absolute bg-[var(--color-light,#f8efff)] h-[6px] left-0 top-0"
            style={{ width: `${armor}%` }}
          />
        </div>
        <div className="bg-[rgba(29,28,38,0.85)] border-[#e8ffb5] border-l-[3px] border-r-[3px] border-solid h-[18px] overflow-clip relative shrink-0 w-full">
          <div
            className="absolute bg-[var(--color-primary,#c8fe4e)] h-[18px] left-0 top-0 transition-all duration-300"
            style={{ width: `${health}%` }}
          />
          <div className="absolute flex h-[776px] items-center justify-center left-[-68px] top-[-151px] w-[577px]">
            <div className="-scale-y-100 flex-none rotate-180">
              <div className="h-[776px] relative w-[577px]">
                <div className="absolute inset-[-1.8%_-2.43%]">
                  <img alt="" className="block max-w-none size-full" src={imgVector1} />
                </div>
              </div>
            </div>
          </div>
          <div className="-translate-x-1/2 -translate-y-1/2 absolute content-stretch flex gap-[2px] items-center justify-center left-1/2 mix-blend-difference top-1/2">
            <div className="relative shrink-0 size-[10px]">
              <img
                alt=""
                className="absolute block inset-0 max-w-none size-full"
                src={imgUnion}
              />
            </div>
            <div className="[word-break:break-word] flex flex-col font-['Termina:Demi',sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[#c8fe4e] text-[10px] text-center whitespace-nowrap">
              <p className="leading-[normal]">{health}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
