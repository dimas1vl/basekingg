import type { HudData } from '@/types/hud'
import { getWeaponImage } from '@/config/weapons'
import { cn } from '@/lib/utils'
import { useSettings } from '@/store/settings'
import { imgVector1, imgUnion, imgIntersect, imgIntersect1 } from '../assets'

interface WeaponHotbarProps {
  health: number
  slots: HudData['slots']
  activeSlot: number
}

const SLOT_COUNT = 4

function WeaponSlot({
  index,
  slot,
}: {
  index: number
  slot?: HudData['slots'][number]
}) {
  const hasWeapon = !!slot?.weapon
  const ammo = slot?.ammo
  const ammoLabel = hasWeapon && ammo !== null && ammo !== undefined ? `${ammo}x` : '-'

  return (
    <div className={cn('h-[48px] relative shrink-0 w-[64.8px]', !hasWeapon && 'opacity-65')}>
      <div className="absolute h-[48px] left-0 top-0 w-[65px]">
        <img alt="" className="absolute block inset-0 max-w-none size-full" src={hasWeapon ? imgIntersect : imgIntersect1} />
      </div>

      <div className="-translate-x-1/2 -translate-y-1/2 absolute flex flex-col font-['Termina:Medium',sans-serif] justify-center leading-[0] left-1/2 not-italic opacity-35 text-[24px] text-[color:var(--color-light,#f8efff)] text-center top-[calc(50%+0.5px)] whitespace-nowrap">
        <p className="leading-[normal]">{index + 1}</p>
      </div>

      {hasWeapon && (
        <div className="-translate-x-1/2 -translate-y-1/2 absolute h-[13.787px] left-1/2 top-1/2 w-[40.789px]">
          <img alt="" className="absolute inset-0 max-w-none object-contain pointer-events-none size-full" src={getWeaponImage(slot?.weapon)} />
        </div>
      )}

      <div className="-translate-x-1/2 absolute flex flex-col font-['Termina:Medium',sans-serif] justify-center leading-[0] left-1/2 not-italic text-[10px] text-[color:var(--color-light,#f8efff)] text-center top-[-8px] whitespace-nowrap">
        <p className="leading-[normal]">{ammoLabel}</p>
      </div>
    </div>
  )
}

export default function WeaponHotbar({ health, slots }: WeaponHotbarProps) {
  const hideHealth = useSettings((s) => s.settings.hud.hideHealth)
  const hideHotbar = useSettings((s) => s.settings.hud.hideHotbar)

  return (
    <div className="-translate-x-1/2 absolute bottom-[35px] content-stretch flex flex-col gap-[6px] items-start left-1/2 w-[340px]">
      {/* Linha de slots de arma */}
      {!hideHotbar && (
        <div className="content-stretch flex gap-[4px] items-center justify-center relative shrink-0 w-full">
          {Array.from({ length: SLOT_COUNT }, (_, i) => (
            <WeaponSlot key={i} index={i} slot={slots?.[i]} />
          ))}
        </div>
      )}

      {/* Barra de vida */}
      {!hideHealth && (
        <div className="content-stretch flex flex-col items-start relative shrink-0 w-full">
          <div className="bg-[rgba(29,28,38,0.85)] border-[#e8ffb5] border-l-[3px] border-r-[3px] border-solid h-[18px] overflow-clip relative shrink-0 w-full">
            <div
              className="absolute bg-[var(--color-primary,#c8fe4e)] h-[18px] left-0 top-0 transition-all duration-300"
              style={{ width: `${Math.max(0, Math.min(100, health))}%` }}
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
                <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgUnion} />
              </div>
              <div className="[word-break:break-word] flex flex-col font-['Termina:Demi',sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[#c8fe4e] text-[10px] text-center whitespace-nowrap">
                <p className="leading-[normal]">{Math.round(health)}</p>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
