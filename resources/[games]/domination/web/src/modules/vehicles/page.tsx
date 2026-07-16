import { useEffect, useState } from 'react'
import { useListener } from '@/hooks/listener'
import { nuiPost } from '@/utils/nui'
import { fmtInt } from '@/utils/fmt'
import type { VehicleCategory, VehicleItem, VehicleState } from '@/types/domination'

const LOCAL_BASE = (() => {
  const el =
    (document.querySelector('script[src*="assets/index-"]') as HTMLScriptElement | null) ||
    (document.querySelector('link[href*="assets/index-"]') as HTMLLinkElement | null)
  const url = el ? ((el as HTMLScriptElement).src || (el as HTMLLinkElement).href) : ''
  const m = url.match(/^(.*\/)assets\/[^/]*$/)
  return m ? m[1] : document.baseURI.replace(/[^/]*$/, '')
})()

function GemIcon({ size = 14 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
      <path d="M11.8 10.9c-2.27-.59-3-1.2-3-2.15 0-1.09 1.01-1.85 2.7-1.85 1.78 0 2.44.85 2.5 2.1h2.21c-.07-1.72-1.12-3.3-3.21-3.81V3h-3v2.16c-1.94.42-3.5 1.68-3.5 3.61 0 2.31 1.91 3.46 4.7 4.13 2.5.6 3 1.48 3 2.41 0 .69-.49 1.79-2.7 1.79-2.06 0-2.87-.92-2.98-2.1h-2.2c.12 2.19 1.76 3.42 3.68 3.83V21h3v-2.15c1.95-.37 3.5-1.5 3.5-3.55 0-2.84-2.43-3.81-4.7-4.4z" />
    </svg>
  )
}

function reqLabel(r?: string): string {
  return r === 'vip' ? 'VIP' : r === 'streamer' ? 'STREAMER' : r === 'exclusive' ? 'EXCLUSIVO' : 'BLOQUEADO'
}

function VehicleCard({
  cat,
  v,
  base,
  favorite,
  onFav,
}: {
  cat: VehicleCategory
  v: VehicleItem
  base: string
  favorite: boolean
  onFav: (fav: boolean) => void
}) {
  const useExt = /^https?:\/\//i.test(base)
  const locSrc = `${LOCAL_BASE}veiculos/${v.image}.png`
  const initial = useExt ? `${base}${v.image}.png` : locSrc

  const locked = v.action === 'locked' || v.action === 'req'

  return (
    <div className={`vh-card${locked ? ' locked' : ''}`}>
      <div className="vh-name">{v.label}</div>
      <div className="vh-img-wrap">
        <img
          className="vh-img"
          src={initial}
          alt=""
          data-fb="0"
          onError={(e) => {
            const img = e.currentTarget as HTMLImageElement
            if (useExt && img.getAttribute('data-fb') !== '1') {
              img.setAttribute('data-fb', '1')
              img.src = locSrc
            } else {
              img.style.visibility = 'hidden'
            }
          }}
        />
      </div>

      <div className="vh-info">
        {v.action === 'locked' && (
          <span className="vh-req">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 1a5 5 0 0 0-5 5v3H6a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-9a2 2 0 0 0-2-2h-1V6a5 5 0 0 0-5-5zm-3 8V6a3 3 0 1 1 6 0v3z" />
            </svg>{' '}
            LV {v.level}
          </span>
        )}
        {v.action === 'buy' && (
          <span className="vh-price">
            <GemIcon size={11} /> {fmtInt(v.price)}
          </span>
        )}
        {v.action === 'req' && <span className="vh-req">{reqLabel(v.requires)}</span>}
      </div>

      <div className="vh-actions">
        {v.action === 'spawn' ? (
          <button className="vh-btn spawn" onClick={() => nuiPost('veh:spawn', { category: cat.key, id: v.id })}>
            SPAWNAR
          </button>
        ) : v.action === 'buy' ? (
          <button className="vh-btn buy" onClick={() => nuiPost('veh:buy', { category: cat.key, id: v.id })}>
            COMPRAR
          </button>
        ) : v.action === 'req' ? (
          <button className="vh-btn locked">{reqLabel(v.requires)}</button>
        ) : (
          <button className="vh-btn locked">BLOQUEADO</button>
        )}
        <button
          className={`vh-star${favorite ? ' on' : ''}`}
          onClick={() => onFav(!favorite)}
        >
          <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 2l3 6.5 7 .6-5.3 4.6L18.5 21 12 17.3 5.5 21l1.8-7.3L2 9.1l7-.6z" />
          </svg>
        </button>
      </div>
    </div>
  )
}

export default function VehiclesOverlay() {
  const [data, setData] = useState<VehicleState | null>(null)
  const [tab, setTab] = useState<string | null>(null)
  const [visible, setVisible] = useState(false)
  const [favOverrides, setFavOverrides] = useState<Record<string, boolean>>({})

  useListener<{ data: VehicleState }>('vehicles', ({ data: d }) => {
    setData(d ?? null)
    setFavOverrides({})
  })
  useListener<{ value: boolean }>('vehicles:visible', ({ value }) => setVisible(!!value))

  const cats = data?.categories || []
  const activeKey = tab && cats.some((c) => c.key === tab) ? tab : cats[0]?.key
  const activeCat = cats.find((c) => c.key === activeKey) || null
  const base = data?.imageBase || ''

  function closeVeh() {
    setVisible(false)
    nuiPost('veh:close')
  }

  useEffect(() => {
    if (!visible) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') closeVeh()
    }
    document.addEventListener('keydown', onKey)
    return () => document.removeEventListener('keydown', onKey)
  }, [visible])

  return (
    <div id="dom-veh-overlay" className={visible ? 'shown' : ''}>
      <div id="dom-veh-panel">
        <div id="dom-veh-header">
          <div className="vh-title">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
              <path d="M5 11l1.5-4.5A2 2 0 0 1 8.4 5h7.2a2 2 0 0 1 1.9 1.5L19 11h1a1 1 0 0 1 1 1v4a1 1 0 0 1-1 1h-1v1a1 1 0 0 1-1 1h-1a1 1 0 0 1-1-1v-1H8v1a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1v-1H4a1 1 0 0 1-1-1v-4a1 1 0 0 1 1-1h1zm2.2-1h9.6l-1-3H8.2l-1 3zM6.5 15a1 1 0 1 0 0-2 1 1 0 0 0 0 2zm11 0a1 1 0 1 0 0-2 1 1 0 0 0 0 2z" />
            </svg>
            <span>VEÍCULOS</span>
          </div>
          <div id="dom-veh-meta">
            <div className="vh-pill gems">
              <GemIcon size={14} />
              <span id="dom-veh-gems">{fmtInt(data?.gems)}</span>
            </div>
            <div className="vh-pill lv">
              <span id="dom-veh-lv">LV {data?.level || 1}</span>
            </div>
            <button id="dom-veh-close" type="button" onClick={closeVeh}>
              ✕
            </button>
          </div>
        </div>

        <div id="dom-veh-tabs">
          {cats.map((cat) => (
            <button
              key={cat.key}
              className={`vh-tab${cat.key === activeKey ? ' active' : ''}`}
              onClick={() => setTab(cat.key)}
            >
              {cat.label}
            </button>
          ))}
        </div>

        <div id="dom-veh-grid">
          {activeCat?.vehicles.map((v) => (
            <VehicleCard
              key={v.id}
              cat={activeCat}
              v={v}
              base={base}
              favorite={favOverrides[v.id] ?? v.favorite}
              onFav={(fav) => {
                setFavOverrides((prev) => ({ ...prev, [v.id]: fav }))
                nuiPost('veh:favorite', { category: activeCat.key, id: v.id, fav })
              }}
            />
          ))}
        </div>
      </div>
    </div>
  )
}
