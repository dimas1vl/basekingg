import { useState } from 'react'
import { useListener } from '@/hooks/listener'

interface TeammateMarker {
  src: number
  name: string
  sx: number
  sy: number
}

const FONT  = 'Termina, Rajdhani, Inter, system-ui, sans-serif'
const COLOR_ACCENT = '#c8fe4e'
const COLOR_ACCENT_BORDER = '#e8ffb5'
const COLOR_BG     = 'rgba(29, 28, 38, 0.92)'
const COLOR_LIGHT  = '#f8efff'

function Marker({ m }: { m: TeammateMarker }) {
  return (
    <div
      style={{
        position: 'fixed',
        left: 0,
        top: 0,
        transform: `translate3d(${m.sx * 100}vw, ${m.sy * 100}vh, 0) translate(-50%, -100%)`,
        willChange: 'transform',
        fontFamily: FONT,
        pointerEvents: 'none',
      }}
    >
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: 6,
          padding: '4px 10px',
          background: COLOR_BG,
          borderLeft:  `3px solid ${COLOR_ACCENT_BORDER}`,
          borderRight: `3px solid ${COLOR_ACCENT_BORDER}`,
          whiteSpace: 'nowrap',
          boxShadow: '0 2px 8px rgba(0,0,0,0.45)',
        }}
      >
        <span
          style={{
            color: COLOR_LIGHT,
            fontWeight: 700,
            fontSize: 10,
            letterSpacing: '0.08em',
            textTransform: 'uppercase',
            lineHeight: 1,
          }}
        >
          {m.name}
        </span>
      </div>
      <div
        style={{
          width: 0,
          height: 0,
          margin: '0 auto',
          borderLeft:  '4px solid transparent',
          borderRight: '4px solid transparent',
          borderTop:   `5px solid ${COLOR_BG}`,
        }}
      />
    </div>
  )
}

export default function TeammateMarkers() {
  const [markers, setMarkers] = useState<TeammateMarker[]>([])

  useListener<TeammateMarker[]>('clutch:teammates', (data) => {
    setMarkers(Array.isArray(data) ? data : [])
  })

  if (markers.length === 0) return null

  return (
    <div
      className="pointer-events-none fixed inset-0"
      style={{ zIndex: 160 }}
    >
      {markers.map((m) => <Marker key={m.src} m={m} />)}
    </div>
  )
}
