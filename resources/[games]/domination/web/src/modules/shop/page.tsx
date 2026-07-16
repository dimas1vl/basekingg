import { useEffect, useState } from 'react'
import { useListener } from '@/hooks/listener'
import { nuiPost } from '@/utils/nui'
import { fmtInt } from '@/utils/fmt'
import { weaponIconSrc } from '@/utils/weaponIcons'
import type { ShopCategory, ShopState, ShopWeapon } from '@/types/domination'

function GemIcon({ size = 14 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
      <path d="M11.8 10.9c-2.27-.59-3-1.2-3-2.15 0-1.09 1.01-1.85 2.7-1.85 1.78 0 2.44.85 2.5 2.1h2.21c-.07-1.72-1.12-3.3-3.21-3.81V3h-3v2.16c-1.94.42-3.5 1.68-3.5 3.61 0 2.31 1.91 3.46 4.7 4.13 2.5.6 3 1.48 3 2.41 0 .69-.49 1.79-2.7 1.79-2.06 0-2.87-.92-2.98-2.1h-2.2c.12 2.19 1.76 3.42 3.68 3.83V21h3v-2.15c1.95-.37 3.5-1.5 3.5-3.55 0-2.84-2.43-3.81-4.7-4.4z" />
    </svg>
  )
}

function LockIcon() {
  return (
    <svg width="13" height="13" viewBox="0 0 24 24" fill="currentColor">
      <path d="M12 1a5 5 0 0 0-5 5v3H6a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-9a2 2 0 0 0-2-2h-1V6a5 5 0 0 0-5-5zm-3 8V6a3 3 0 1 1 6 0v3z" />
    </svg>
  )
}

function ShopCard({ cat, w }: { cat: ShopCategory; w: ShopWeapon }) {
  let cls = 'shop-card'
  if (w.equipped) cls += ' equipped'
  else if (w.locked) cls += ' locked'

  return (
    <div className={cls}>
      <div className="card-name">{w.label}</div>
      <div className="card-img-wrap">
        <img
          className="card-img"
          src={weaponIconSrc(w.icon)}
          alt=""
          onError={(e) => {
            ;(e.currentTarget as HTMLImageElement).style.visibility = 'hidden'
          }}
        />
      </div>

      {w.locked && (
        <div className="card-req">
          <LockIcon /> LV {w.level}
        </div>
      )}

      {!w.owned && w.price > 0 && (
        <div className="card-price">
          <GemIcon size={11} /> {fmtInt(w.price)}
        </div>
      )}

      {w.equipped ? (
        <button className="card-btn equipped">EQUIPADO</button>
      ) : w.owned ? (
        <button className="card-btn equip" onClick={() => nuiPost('shop:equip', { category: cat.key, id: w.id })}>
          EQUIPAR
        </button>
      ) : w.locked ? (
        <button className="card-btn locked">BLOQUEADO</button>
      ) : (
        <button className="card-btn buy" onClick={() => nuiPost('shop:buy', { category: cat.key, id: w.id })}>
          COMPRAR
        </button>
      )}
    </div>
  )
}

export default function ShopOverlay() {
  const [data, setData] = useState<ShopState | null>(null)
  const [tab, setTab] = useState<string | null>(null)
  const [visible, setVisible] = useState(false)

  useListener<{ data: ShopState }>('shop', ({ data: d }) => setData(d ?? null))
  useListener<{ value: boolean }>('shop:visible', ({ value }) => setVisible(!!value))

  const cats = data?.categories || []
  const activeKey = tab && cats.some((c) => c.key === tab) ? tab : cats[0]?.key
  const activeCat = cats.find((c) => c.key === activeKey) || null

  function closeShop() {
    setVisible(false)
    nuiPost('shop:close')
  }

  useEffect(() => {
    if (!visible) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') closeShop()
    }
    document.addEventListener('keydown', onKey)
    return () => document.removeEventListener('keydown', onKey)
  }, [visible])

  return (
    <div id="dom-shop-overlay" className={visible ? 'shown' : ''}>
      <div id="dom-shop-panel">
        <div id="dom-shop-header">
          <div className="shop-title">
            <svg className="shop-flag" width="20" height="20" viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
              <path d="M5 2h2v20H5z" />
              <path d="M7 3h12l-3 3.5 3 3.5H7z" />
            </svg>
            <span>ARMAMENTOS</span>
          </div>
          <div className="shop-meta">
            <div className="shop-pill gems">
              <GemIcon size={14} />
              <span id="dom-shop-gems">{fmtInt(data?.gems)}</span>
            </div>
            <div className="shop-pill lv">
              <span id="dom-shop-lv">LV {data?.level || 1}</span>
            </div>
            <button id="dom-shop-close" type="button" onClick={closeShop}>
              ✕
            </button>
          </div>
        </div>

        <div id="dom-shop-tabs">
          {cats.map((cat) => (
            <button
              key={cat.key}
              className={`shop-tab${cat.key === activeKey ? ' active' : ''}`}
              onClick={() => setTab(cat.key)}
            >
              {cat.label}
            </button>
          ))}
        </div>

        <div id="dom-shop-grid">
          {activeCat?.weapons.map((w) => (
            <ShopCard key={w.id} cat={activeCat} w={w} />
          ))}
        </div>

        <div id="dom-shop-footer">
          <span>Digite</span>
          <span className="shop-cmd">/attachs</span>
          <span>para customizar suas armas.</span>
        </div>
      </div>
    </div>
  )
}
