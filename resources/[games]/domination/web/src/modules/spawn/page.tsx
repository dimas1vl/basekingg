import { useEffect, useState } from 'react'
import { useListener } from '@/hooks/listener'
import { nuiPost } from '@/utils/nui'
import { fmtInt } from '@/utils/fmt'
import type { DeathCard, RespawnPayload, SpawnState, SpawnZone } from '@/types/domination'

/* ===================== Escolher spawn (F5) ===================== */
function SpawnList() {
  const [zones, setZones] = useState<SpawnZone[]>([])
  const [current, setCurrent] = useState<string | number | null>(null)
  const [visible, setVisible] = useState(false)

  useListener<{ data: SpawnState }>('spawns', ({ data }) => {
    setZones((data && data.zones) || [])
    setCurrent(data ? data.current : null)
  })
  useListener<{ value: boolean }>('spawns:visible', ({ value }) => setVisible(!!value))

  function closeSpawn() {
    setVisible(false)
    nuiPost('spawn:close')
  }

  useEffect(() => {
    if (!visible) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') closeSpawn()
    }
    document.addEventListener('keydown', onKey)
    return () => document.removeEventListener('keydown', onKey)
  }, [visible])

  return (
    <div id="dom-spawn-overlay" className={visible ? 'shown' : ''}>
      <div id="dom-spawn-panel">
        <div id="dom-spawn-header">
          <div className="sp-title">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
              <path d="M12 2C8.1 2 5 5.1 5 9c0 5.2 7 13 7 13s7-7.8 7-13c0-3.9-3.1-7-7-7zm0 9.5A2.5 2.5 0 1 1 12 6.5a2.5 2.5 0 0 1 0 5z" />
            </svg>
            <span>ESCOLHER SPAWN</span>
          </div>
          <button id="dom-spawn-close" type="button" onClick={closeSpawn}>
            ✕
          </button>
        </div>
        <div id="dom-spawn-list">
          {zones.map((z) => {
            const isCur = z.id === current
            return (
              <div key={String(z.id)} className={`sp-zone${isCur ? ' is-current' : ''}`}>
                <div className="sp-zone-name">{z.label}</div>
                {isCur ? (
                  <button className="sp-zone-btn current">ATUAL</button>
                ) : (
                  <button className="sp-zone-btn select" onClick={() => nuiPost('spawn:select', { id: z.id })}>
                    SPAWNAR
                  </button>
                )}
              </div>
            )
          })}
        </div>
        <div id="dom-spawn-footer">Você renasce na zona escolhida. Aperte F5 para reabrir.</div>
      </div>
    </div>
  )
}

/* ===================== Renascimento + death card ===================== */
function RespawnOverlay() {
  const [respawn, setRespawn] = useState<{ visible: boolean; ready: boolean; pct: number; sec: number }>({
    visible: false,
    ready: false,
    pct: 0,
    sec: 0,
  })
  const [card, setCard] = useState<DeathCard | null>(null)
  const [reported, setReported] = useState(false)

  useListener<{ data: DeathCard }>('deathcard', ({ data: c }) => {
    if (!c) return
    setCard(c)
    setReported(false)
  })

  useListener('deathcard:reported', () => setReported(true))

  useListener<RespawnPayload>('respawn', (d) => {
    if (!d || !d.visible) {
      setRespawn({ visible: false, ready: false, pct: 0, sec: 0 })
      setCard(null)
      return
    }
    if (d.ready) {
      setRespawn({ visible: true, ready: true, pct: 100, sec: 0 })
    } else {
      const totalMs = d.total || 3000
      const ms = typeof d.ms === 'number' ? d.ms : 0
      const sec = Math.max(0, Math.ceil(ms / 1000))
      const pct = Math.max(0, Math.min(100, (1 - ms / totalMs) * 100))
      setRespawn({ visible: true, ready: false, pct, sec })
    }
  })

  return (
    <div id="dom-respawn-overlay" className={respawn.visible ? 'shown' : ''}>
      <div id="dom-dc-respawn">
        <div className="lbl">
          {respawn.ready ? (
            <>
              PRESSIONE <span style={{ color: '#fff' }}>[E]</span> PARA RENASCER
            </>
          ) : (
            `AGUARDE ${respawn.sec}s PARA RENASCER`
          )}
        </div>
        <div className="bar">
          <i style={{ width: `${respawn.pct}%` }} />
        </div>
      </div>

      <div id="dom-dc" className={card ? 'shown' : ''}>
        <div className="dc-ped">
          <svg viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
            <circle className="head" cx="12" cy="7" r="3.4" />
            <path d="M5 21c0-4.4 3-7 7-7s7 2.6 7 7z" />
          </svg>
        </div>
        <div className="dc-info">
          <div className="dc-top">
            <span className="dc-id">#{card?.id ?? 0}</span>
            {card?.clan ? <span className="dc-clan">{card.clan}</span> : null}
            <span className="dc-gems">
              <svg width="11" height="11" viewBox="0 0 24 24" fill="currentColor">
                <path d="M11.8 10.9c-2.27-.59-3-1.2-3-2.15 0-1.09 1.01-1.85 2.7-1.85 1.78 0 2.44.85 2.5 2.1h2.21c-.07-1.72-1.12-3.3-3.21-3.81V3h-3v2.16c-1.94.42-3.5 1.68-3.5 3.61 0 2.31 1.91 3.46 4.7 4.13 2.5.6 3 1.48 3 2.41 0 .69-.49 1.79-2.7 1.79-2.06 0-2.87-.92-2.98-2.1h-2.2c.12 2.19 1.76 3.42 3.68 3.83V21h3v-2.15c1.95-.37 3.5-1.5 3.5-3.55 0-2.84-2.43-3.81-4.7-4.4z" />
              </svg>
              <span>{fmtInt(card?.gems)}</span>
            </span>
            <span className="dc-lv">LV {card?.level ?? '—'}</span>
          </div>
          <div className="dc-name">{card?.name || '—'}</div>
          <div className="dc-hp">
            <span className="pct">100%</span>
            <div className="bar">
              <i style={{ width: '100%' }} />
            </div>
          </div>
          <div className="dc-score">
            <b>{card?.they ?? 0}</b> &times; <b>{card?.me ?? 0}</b>
          </div>
          <div className="dc-stats">
            <span title="Kills">
              <svg viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 2a7 7 0 0 0-7 7c0 3 2 4.5 2 6.5V19a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1v-3.5c0-2 2-3.5 2-6.5a7 7 0 0 0-7-7zM9.5 10A1.5 1.5 0 1 1 9.5 7a1.5 1.5 0 0 1 0 3zm5 0A1.5 1.5 0 1 1 14.5 7a1.5 1.5 0 0 1 0 3z" />
              </svg>
              <b>{card?.kills ?? 0}</b>
            </span>
            <span title="Mortes">
              <svg viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 3a6 6 0 0 0-6 6v4l-1 3h14l-1-3V9a6 6 0 0 0-6-6zm-2 17a2 2 0 0 0 4 0z" />
              </svg>
              <b>{card?.deaths ?? 0}</b>
            </span>
            <span title="Vitórias">
              <svg viewBox="0 0 24 24" fill="currentColor">
                <path d="M3 17l5-5 4 4 8-8v4h2V4h-8v2h4l-6 6-4-4-7 7z" />
              </svg>
              <b>{card?.ratio ?? 0}%</b>
            </span>
            <span title="Ping">
              <svg viewBox="0 0 24 24" fill="currentColor">
                <path d="M2 8a14 14 0 0 1 20 0l-2 2a11 11 0 0 0-16 0zM5 11a9 9 0 0 1 14 0l-2 2a6 6 0 0 0-10 0zM8 14a5 5 0 0 1 8 0l-4 4z" />
              </svg>
              <b>{card?.ping ?? 0}</b>
            </span>
          </div>
          {card && !card.self && (
            <div className={`dc-report${reported ? ' done' : ''}`}>
              {reported ? (
                'REPORTADO'
              ) : (
                <>
                  <span className="rkey">R</span> REPORTAR
                </>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

export default function SpawnOverlays() {
  return (
    <>
      <SpawnList />
      <RespawnOverlay />
    </>
  )
}
