import { useState } from 'react'
import { ImageOff } from 'lucide-react'
import { CoinIcon, DividerIcon } from '@/components/icons'
import lockSvg from '@/components/icons/lock.svg?url'
import shirtsSvg from '@/components/icons/categories_customizable/shirts.svg?url'
import type { ClothingItem } from '../types'
import { CARD_CIRCUIT_BG } from '../data'

const DIVIDER_COLOR: Record<string, string> = {
  equipped:    '#9d0de9',
  owned:       '#fedb4e',
  purchasable: '#9d0de9',
  unavailable: '#4d4c55',
  hover:       '#4e8cff',
}

type Props = {
  item: ClothingItem
  selected: boolean
  onClick: () => void
}

export function ItemCard({ item, selected, onClick }: Props) {
  const [hovered, setHovered] = useState(false)
  const [imgFailed, setImgFailed] = useState(false)
  const [circuitFailed, setCircuitFailed] = useState(false)

  const showImage = !!item.thumbnail && !imgFailed
  const isUnavailable = item.status === 'unavailable'
  const isEquipped    = item.status === 'equipped'
  const isOwned       = item.status === 'owned' || isEquipped
  const active        = hovered || selected

  const cardBg      = active ? 'rgba(29,28,38,0.95)' : 'rgba(29,28,38,0.75)'
  const innerBorder = active
    ? '#f8efff'
    : isUnavailable
    ? 'rgba(248,239,255,0.05)'
    : 'rgba(248,239,255,0.15)'
  const gradientFrom = isUnavailable ? '#151515' : '#1e1f26'
  const dividerColor = selected
    ? '#f8efff'
    : hovered
    ? DIVIDER_COLOR.hover
    : DIVIDER_COLOR[item.status]
  const nameBottom = active ? '0' : '-2.7rem'

  return (
    <div
      className="flex flex-col shrink-0 cursor-pointer select-none"
      style={{ width: '18.6rem' }}
      onClick={onClick}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
    >
      {/* card body — 24.9rem tall */}
      <div
        className="flex flex-col gap-[0.6rem] shrink-0"
        style={{
          height: '24.9rem',
          backgroundColor: cardBg,
          padding: '0.4rem 0.4rem 0.6rem',
          transition: 'background-color 0.15s',
        }}
      >
        {/* image area — 17.8rem wide, fills remaining height */}
        <div
          className="relative overflow-hidden flex-1 min-h-0"
          style={{
            width: '17.8rem',
            background: `linear-gradient(180deg, ${gradientFrom} 0%, #2b2b2b 100%)`,
            border: `0.2rem solid ${innerBorder}`,
            transition: 'border-color 0.15s',
          }}
        >
          {/* circuit background — hidden gracefully if asset fails to load */}
          {!circuitFailed && (
            <div
              className="absolute pointer-events-none"
              style={{
                width: '29.5rem',
                height: '39.6rem',
                left: 'calc(50% + 0.05rem)',
                top: 'calc(50% - 0.1rem)',
                transform: 'translate(-50%, -50%) scaleY(-1) rotate(180deg)',
              }}
            >
              <img
                alt=""
                src={CARD_CIRCUIT_BG}
                onError={() => setCircuitFailed(true)}
                className="absolute inset-0 w-full h-full block"
              />
            </div>
          )}

          {/* character / item image — falls back to a "no image" icon when
              the thumbnail is missing or fails to load. */}
          {showImage ? (
            <img
              alt=""
              src={item.thumbnail}
              onError={() => setImgFailed(true)}
              className="absolute pointer-events-none"
              style={{
                width: '20.5rem',
                height: '43.6rem',
                left: 'calc(50% + 2.85rem)',
                top: 'calc(50% + 9.5rem)',
                transform: 'translate(-50%, -50%)',
                objectFit: 'cover',
                opacity: isUnavailable ? 0.5 : 1,
                boxShadow: '0.5rem 0.4rem 0.4rem 0 rgba(0,0,0,0.15)',
              }}
            />
          ) : (
            <div
              className="absolute pointer-events-none flex items-center justify-center"
              style={{
                width: '7rem',
                height: '7rem',
                left: '50%',
                top: '50%',
                transform: 'translate(-50%, -50%)',
                opacity: isUnavailable ? 0.25 : 0.45,
              }}
            >
              <ImageOff
                size={56}
                strokeWidth={1.5}
                color="#f8efff"
              />
            </div>
          )}

          {/* category icon — top right, auto width to avoid squish */}
          <div className="absolute top-[0.8rem] right-[0.8rem] h-[1.8rem]">
            <img alt="" src={shirtsSvg} className="block h-full w-auto" />
          </div>

          {/* skin name — slides in on hover */}
          <div
            className="absolute left-0 right-0 flex items-center justify-center px-[1rem]"
            style={{
              bottom: nameBottom,
              height: '2.5rem',
              backgroundColor: 'rgba(0,0,0,0.35)',
              transition: 'bottom 0.15s',
            }}
          >
            <span className="text-[1.2rem] font-medium text-[#f8efff] text-center truncate whitespace-nowrap">
              {item.name}
            </span>
          </div>

          {/* EQUIPADO badge — top left */}
          {isEquipped && (
            <div
              className="absolute top-[0.8rem] left-[0.8rem] flex items-center justify-center border-2 border-solid border-[rgba(255,255,255,0.25)]"
              style={{ backgroundColor: '#9d0de9', padding: '0.4rem' }}
            >
              <span className="text-[1rem] font-semibold text-[#f8efff] whitespace-nowrap">
                EQUIPADO
              </span>
            </div>
          )}

          {/* lock icon — centered, larger to compensate for simple SVG vs Figma Union */}
          {isUnavailable && (
            <div
              className="absolute pointer-events-none"
              style={{
                width: '5rem',
                height: '5rem',
                left: '50%',
                top: '50%',
                transform: 'translate(-50%, -50%)',
              }}
            >
              <img alt="" src={lockSvg} className="block w-full h-full object-contain" />
            </div>
          )}
        </div>

        {/* status row */}
        <div className="flex items-center justify-center shrink-0" style={{ height: '2.4rem' }}>
          {isUnavailable ? (
            <span className="text-[1.4rem] font-medium text-[#f8efff] whitespace-nowrap" style={{ opacity: 0.41 }}>
              INDISPONÍVEL
            </span>
          ) : isOwned ? (
            <span className="text-[1.4rem] font-medium text-[#f8efff] whitespace-nowrap">
              ADQUIRIDO
            </span>
          ) : (
            <div className="flex items-center gap-[0.6rem]">
              <CoinIcon width={14} height={14} className="shrink-0 text-[#f8efff]" />
              <span className="text-[1.4rem] font-medium text-[#f8efff] whitespace-nowrap">
                {item.price?.toLocaleString('pt-BR') ?? '—'}
              </span>
            </div>
          )}
        </div>
      </div>

      {/* divider — 1.2rem container, Figma "Friends Divider" approach */}
      <div className="relative shrink-0 overflow-hidden w-full" style={{ height: '1.2rem' }}>
        <div
          className="absolute top-0 flex items-center"
          style={{
            left: 'calc(50% + 0.017rem)',
            transform: 'translateX(-50%)',
            width: '134.1rem',
            height: '1.1814rem',
          }}
        >
          <div style={{ transform: 'scaleY(-1) rotate(180deg)', width: '100%', flexShrink: 0 }}>
            <DividerIcon
              width="134.1rem"
              height="1.1814rem"
              style={{ color: dividerColor, display: 'block', transition: 'color 0.15s' }}
            />
          </div>
        </div>
      </div>
    </div>
  )
}
