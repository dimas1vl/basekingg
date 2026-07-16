import { useState } from 'react'
import { useListener } from '@/hooks/listener'
import { useVisibility } from '@/providers/Visibility'

interface Blip {
  id: number
  modeId: string
  label: string
  promptKey: string
  sx: number
  sy: number
  distance: number
  interactable: boolean
}

const FONT = 'Termina, Rajdhani, Inter, system-ui, sans-serif'

const opacityFor = (d: number) => {
  if (d < 3)  return 1
  if (d < 15) return 0.95
  if (d < 25) return 0.78
  if (d < 35) return 0.55
  return Math.max(0, 1 - (d - 35) / 8)
}

const scaleFor = (d: number, interactable: boolean) => {
  if (interactable) return 1
  if (d < 15) return 0.9
  if (d < 25) return 0.75
  return 0.62
}

function NpcBlip({ blip }: { blip: Blip }) {
  const opacity = opacityFor(blip.distance)
  const scale   = scaleFor(blip.distance, blip.interactable)

  return (
    <div
      style={{
        position: 'fixed',
        left: 0,
        top: 0,
        transform: `translate3d(${blip.sx * 100}vw, ${blip.sy * 100}vh, 0) translate(-50%, -100%)`,
        willChange: 'transform',
        pointerEvents: 'none',
        fontFamily: FONT,
      }}
    >
      <div
        style={{
          transform: `scale(${scale})`,
          transformOrigin: 'center bottom',
          opacity,
          willChange: 'transform, opacity',
          transition: 'opacity 0.12s linear, transform 0.12s linear',
        }}
      >
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 8,
            padding: '6px 10px',
            background: 'rgba(29, 28, 38, 0.92)',
            borderLeft:  '3px solid #e8ffb5',
            borderRight: '3px solid #e8ffb5',
            whiteSpace: 'nowrap',
            boxSizing: 'border-box',
            boxShadow: '0 2px 8px rgba(0, 0, 0, 0.45)',
          }}
        >
          {blip.interactable && (
            <span
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                justifyContent: 'center',
                minWidth: 20,
                height: 18,
                padding: '0 6px',
                background: '#c8fe4e',
                color: '#1d1c26',
                fontWeight: 700,
                fontSize: 10,
                letterSpacing: '0.05em',
                lineHeight: 1,
              }}
            >
              {blip.promptKey}
            </span>
          )}
          <span
            style={{
              color: '#f8efff',
              fontWeight: 600,
              fontSize: blip.interactable ? 11 : 10,
              letterSpacing: '0.07em',
              textTransform: 'uppercase',
              lineHeight: 1,
            }}
          >
            {blip.label}
          </span>
        </div>

        <div
          style={{
            width: 0,
            height: 0,
            margin: '0 auto',
            borderLeft:  '5px solid transparent',
            borderRight: '5px solid transparent',
            borderTop:   '6px solid rgba(29, 28, 38, 0.92)',
          }}
        />
      </div>
    </div>
  )
}

export default function NpcBlips() {
  const { opened } = useVisibility()
  const [blips, setBlips] = useState<Blip[]>([])

  useListener<Blip[]>('lobby_minigames:npcs:update', (data) => {
    setBlips(Array.isArray(data) ? data : [])
  })

  if (opened || blips.length === 0) return null

  return (
    <div className="pointer-events-none fixed inset-0" style={{ zIndex: 150 }}>
      {blips.map((b) => (
        <NpcBlip key={b.id} blip={b} />
      ))}
    </div>
  )
}
