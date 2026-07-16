import { useState } from 'react'
import { useListener } from '@/hooks/listener'

const FONT  = 'Termina, Rajdhani, Inter, system-ui, sans-serif'
const COLOR_ACCENT = '#c8fe4e'
const COLOR_ACCENT_BORDER = '#e8ffb5'
const COLOR_BG     = 'rgba(29, 28, 38, 0.95)'
const COLOR_BG_SOFT = 'rgba(29,28,38,0.55)'
const COLOR_LIGHT  = '#f8efff'
const COLOR_MUTED  = 'rgba(248,239,255,0.55)'

interface SpectateData {
  active: boolean
  name?: string
  hp?: number
  hpMax?: number
}

export default function SpectatePanel() {
  const [data, setData] = useState<SpectateData>({ active: false })

  useListener<SpectateData>('clutch:spectate', (msg) => {
    if (!msg) {
      setData({ active: false })
      return
    }
    setData(msg)
  })

  if (!data.active) return null

  const hp     = Math.max(0, Number(data.hp) || 0)
  const hpMax  = Math.max(1, Number(data.hpMax) || 100)
  const pct    = Math.min(100, Math.max(0, (hp / hpMax) * 100))

  return (
    <div
      style={{
        position: 'absolute',
        top: 168,
        left: '50%',
        transform: 'translateX(-50%)',
        minWidth: 360,
        fontFamily: FONT,
        background: COLOR_BG,
        borderLeft:  `3px solid ${COLOR_ACCENT_BORDER}`,
        borderRight: `3px solid ${COLOR_ACCENT_BORDER}`,
        padding: '12px 18px',
        display: 'flex',
        flexDirection: 'column',
        gap: 8,
        pointerEvents: 'none',
        boxShadow: '0 4px 16px rgba(0,0,0,0.55)',
      }}
    >
      <div
        style={{
          fontSize: 9,
          letterSpacing: '0.28em',
          fontWeight: 800,
          color: COLOR_MUTED,
          lineHeight: 1,
        }}
      >
        ESPECTANDO ALIADO
      </div>

      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 14 }}>
        <span
          style={{
            fontSize: 18,
            fontWeight: 800,
            color: COLOR_LIGHT,
            letterSpacing: '0.06em',
            textTransform: 'uppercase',
            lineHeight: 1,
            whiteSpace: 'nowrap',
            overflow: 'hidden',
            textOverflow: 'ellipsis',
            maxWidth: 220,
          }}
        >
          {data.name || '—'}
        </span>
        <span
          style={{
            fontSize: 14,
            fontWeight: 700,
            color: COLOR_ACCENT,
            fontVariantNumeric: 'tabular-nums',
            display: 'inline-flex',
            alignItems: 'center',
            gap: 4,
            lineHeight: 1,
          }}
        >
          <span style={{ fontSize: 14 }}>♥</span>
          <span>{hp}</span>
          <span style={{ color: COLOR_MUTED, fontWeight: 500 }}>/ {hpMax}</span>
        </span>
      </div>

      <div
        style={{
          position: 'relative',
          height: 8,
          background: COLOR_BG_SOFT,
          overflow: 'hidden',
          borderLeft:  `2px solid ${COLOR_ACCENT_BORDER}`,
          borderRight: `2px solid ${COLOR_ACCENT_BORDER}`,
        }}
      >
        <div
          style={{
            position: 'absolute',
            left: 0,
            top: 0,
            height: '100%',
            width: `${pct}%`,
            background: COLOR_ACCENT,
            transition: 'width 0.25s ease-out',
          }}
        />
      </div>
    </div>
  )
}
