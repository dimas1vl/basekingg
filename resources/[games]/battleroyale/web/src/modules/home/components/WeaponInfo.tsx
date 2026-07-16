import type { HudData } from '@/types/hud'
import {
  A,
  imgVector3,
  imgMaskGroup,
  imgVector4,
  imgVector5,
  imgWeaponCarbinerifleMk23,
  imgUnion2,
  imgVector14,
} from '../assets'

interface WeaponInfoProps {
  ammo: number
  maxAmmo: number
  activeSlot: number
  speed: number
  slots: HudData['slots']
}

function normalizeImageKey(value: string): string {
  return value
    .trim()
    .replace(/\.[^.]+$/, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
}

function getWeaponImageSrc(image?: string, weaponName?: string): string {
  const rawImage = image?.trim()
  if (rawImage) {
    if (rawImage.includes('/') || rawImage.includes('\\') || rawImage.includes('.')) {
      return rawImage
    }
    return `${A}${normalizeImageKey(rawImage)}.webp`
  }

  if (weaponName) {
    return `${A}${normalizeImageKey(weaponName)}.webp`
  }

  return imgWeaponCarbinerifleMk23
}

export default function WeaponInfo({ ammo, maxAmmo, activeSlot, speed, slots }: WeaponInfoProps) {
  const activeSlotItem = activeSlot > 0 ? slots[activeSlot - 1] : false
  const weaponImageSrc = activeSlotItem
    ? getWeaponImageSrc(activeSlotItem.image, activeSlotItem.name)
    : imgWeaponCarbinerifleMk23

  return (
    <>
      <div className="absolute bottom-[40px] h-[44px] right-[35px] w-[211px]">
        <div className="absolute h-[47px] left-0 top-[-1px] w-[211px]">
          <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgVector3} />
        </div>
        <div className="absolute h-[47px] left-0 top-[-1px] w-[211px]">
          <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgMaskGroup} />
        </div>
        <div className="absolute h-[51px] left-[-2px] top-[-3px] w-[215px]">
          <div className="absolute inset-[-0.99%_-0.41%_-1.35%_-0.26%]">
            <img alt="" className="block max-w-none size-full" src={imgVector4} />
          </div>
        </div>
        <div className="-translate-y-1/2 absolute content-stretch flex gap-[6px] items-center right-[18px] top-1/2">
          <div className="content-stretch flex gap-[4px] items-center justify-end relative shrink-0">
            <div className="[word-break:break-word] content-stretch flex gap-[2px] items-center leading-[0] not-italic relative shrink-0 text-[12px] text-[color:var(--color-light,#f8efff)] text-center whitespace-nowrap">
              <div className="flex flex-col font-['Termina:Bold',sans-serif] justify-center relative shrink-0">
                <p className="leading-[normal]">{ammo}</p>
              </div>
              <div className="flex flex-col font-['Termina:Medium',sans-serif] justify-center opacity-55 relative shrink-0">
                <p className="leading-[normal]">/</p>
              </div>
              <div className="flex flex-col font-['Termina:Medium',sans-serif] justify-center opacity-55 relative shrink-0">
                <p className="leading-[normal]">{maxAmmo}</p>
              </div>
            </div>
            <div className="flex h-[13px] items-center justify-center relative shrink-0 w-[12px]">
              <div className="-rotate-90 flex-none">
                <div className="h-[12px] relative w-[13px]">
                  <img
                    alt=""
                    className="absolute block inset-0 max-w-none size-full"
                    src={imgVector5}
                  />
                </div>
              </div>
            </div>
          </div>
          <div className="h-[44px] relative shrink-0 w-[83px]">
            <div className="-translate-y-1/2 absolute flex h-[27.911px] items-center justify-center right-[0.12px] top-[calc(50%-0.04px)] w-[82.573px]">
              <div className="-scale-y-100 flex-none rotate-180">
                <div className="h-[27.911px] relative w-[82.573px]">
                  <img
                    alt=""
                    className="absolute inset-0 max-w-none object-bottom pointer-events-none size-full"
                    src={weaponImageSrc}
                    onError={(event) => {
                      event.currentTarget.onerror = null
                      event.currentTarget.src = imgWeaponCarbinerifleMk23
                    }}
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
        <div className="-translate-x-1/2 absolute bg-[var(--color-background,#1d1c26)] bottom-[15px] content-stretch flex flex-col items-center justify-center left-[calc(50%-122.5px)] px-[3px] size-[14px]">
          <div className="[word-break:break-word] flex flex-col font-['Termina:Demi',sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[12px] text-[color:var(--color-primary,#c8fe4e)] text-center w-full">
            <p className="leading-[normal]">{activeSlot}</p>
          </div>
        </div>
        <div className="absolute h-[10px] left-[160px] top-[-5px] w-[25px]">
          <div className="absolute inset-[-10%_-4%]">
            <img alt="" className="block max-w-none size-full" src={imgUnion2} />
          </div>
        </div>
      </div>

      {speed >= 0 && (
        <div className="[word-break:break-word] absolute bottom-[103.5px] flex flex-col font-['Termina:Bold',sans-serif] justify-center leading-[0] not-italic right-[104.5px] text-[14px] text-[color:var(--color-light,#f8efff)] text-center translate-x-1/2 translate-y-1/2 whitespace-nowrap">
          <p className="leading-[normal]">{Math.round(speed)} KM/H</p>
        </div>
        
      )}

  {speed >= 0 && (
        <div className="absolute h-[14px] left-[calc(87.5%+29.5px)] top-[977.5px] w-[56px]">
        <div className="absolute inset-[-15.71%_-2.14%_-13.43%_-3.45%]">
          <img alt="" className="block max-w-none size-full" src={imgVector14} />
        </div>
      </div>
      )}
    </>
  )
}
