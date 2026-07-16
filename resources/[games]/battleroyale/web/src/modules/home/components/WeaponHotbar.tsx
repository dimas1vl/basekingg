import type { HudData } from '@/types/hud'
import {
  imgIntersect,
  imgIntersect1,
  imgWeaponCarbinerifleMk23,
  imgWeaponAssaultrifle,
  imgWeaponAssaultrifleMk2,
  imgWeaponSpecialcarbine,
  imgWeaponCarbinerifle,
  imgWeaponPistolMk2,
  imgWeaponAppistol,
  imgWeaponMicrosmg,
  imgWeaponAssaultsmg,
  imgWeaponMachinepistol,
  imgWeaponPumpshotgun,
  imgWeaponSmokegrenade,
  imgWeaponAmmo,
  imgArmourStandard,
  imgHealthStandard,
  imgVector1,
  imgUnion,
} from '../assets'

const ITEM_IMAGES: Record<string, string> = {
  WEAPON_ASSAULTRIFLE: imgWeaponAssaultrifle,
  WEAPON_ASSAULTRIFLE_MK2: imgWeaponAssaultrifleMk2,
  WEAPON_SPECIALCARBINE: imgWeaponSpecialcarbine,
  WEAPON_CARBINERIFLE: imgWeaponCarbinerifle,
  WEAPON_PISTOL_MK2: imgWeaponPistolMk2,
  WEAPON_APPISTOL: imgWeaponAppistol,
  WEAPON_MICROSMG: imgWeaponMicrosmg,
  WEAPON_ASSAULTSMG: imgWeaponAssaultsmg,
  WEAPON_MACHINEPISTOL: imgWeaponMachinepistol,
  WEAPON_PUMPSHOTGUN: imgWeaponPumpshotgun,
  WEAPON_SMOKEGRENADE: imgWeaponSmokegrenade,
  WEAPON_AMMO: imgWeaponAmmo,
  ARMOUR_STANDARD: imgArmourStandard,
  HEALTH_STANDARD: imgHealthStandard,
}

function getItemImageSrc(name: string): string | null {
  return ITEM_IMAGES[name] ?? null
}

interface WeaponHotbarProps {
  health: number
  armor: number
  slots: HudData['slots']
  activeSlot: number
}

export default function WeaponHotbar({ health, armor, slots, activeSlot }: WeaponHotbarProps) {
  return (
    <div className="-translate-x-1/2 absolute bottom-[35px] content-stretch flex flex-col gap-[6px] items-start left-1/2 w-[340px]">
      <div className="content-stretch flex gap-[4px] items-center justify-center relative shrink-0 w-full">
        {slots.map((slot, i) => {
          const slotNum = i + 1
          const isActive = slotNum === activeSlot
          const isEmpty = slot === false
          const itemImage = !isEmpty ? getItemImageSrc(slot.name) : null
          return (
            <div
              key={slotNum}
              className={`h-[48px] relative shrink-0 w-[64.8px] ${isEmpty && !isActive ? 'opacity-65' : ''}`}
            >
              <div className="absolute h-[48px] left-0 top-0 w-[65px]">
                <img
                  alt=""
                  className="absolute block inset-0 max-w-none size-full"
                  src={isEmpty && !isActive ? imgIntersect1 : imgIntersect}
                />
              </div>
              <div className="-translate-x-1/2 -translate-y-1/2 [word-break:break-word] absolute flex flex-col font-['Termina:Medium',sans-serif] justify-center leading-[0] left-1/2 not-italic opacity-35 text-[24px] text-[color:var(--color-light,#f8efff)] text-center top-[calc(50%+0.5px)] whitespace-nowrap">
                <p className="leading-[normal]">{slotNum}</p>
              </div>
              {itemImage && (
                <div className="-translate-x-1/2 -translate-y-1/2 absolute h-[13.787px] left-1/2 top-[calc(50%-0.11px)] w-[40.789px]">
                  <img
                    alt=""
                    className="absolute inset-0 max-w-none object-bottom pointer-events-none size-full"
                    src={itemImage}
                    onError={(event) => {
                      event.currentTarget.onerror = null
                      event.currentTarget.src = imgWeaponCarbinerifleMk23
                    }}
                  />
                </div>
              )}
              <div className="-translate-x-1/2 -translate-y-1/2 [word-break:break-word] absolute flex flex-col font-['Termina:Medium',sans-serif] justify-center leading-[0] left-1/2 not-italic text-[10px] text-[color:var(--color-light,#f8efff)] text-center top-[-8px] whitespace-nowrap">
                <p className="leading-[normal]">{isEmpty ? '-' : `${slot.amount}x`}</p>
              </div>
            </div>
          )
        })}
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
