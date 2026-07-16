import { useState } from 'react'
import { useListener } from '@/hooks/listener'

interface HudData {
  hp: number
  hpMax: number
  armor: number
  armorMax: number
}

interface WaitingRoom {
  roomId: string
  mode: string
  map: string
  variant?: string
  current: number
  max: number
  owner: string
}

const DEFAULT_HUD: HudData = { hp: 100, hpMax: 100, armor: 0, armorMax: 100 }

const MODE_LABELS: Record<string, string> = {
  clutch:    'CLUTCH',
  gang:      'GANG',
  predios:   'PRÉDIOS',
  dominacao: 'DOMINAÇÃO',
}

const formatMode = (mode: string, variant?: string) => {
  const label = MODE_LABELS[mode] || (mode ? mode.toUpperCase() : 'SALA')
  return variant ? `${label} · ${variant.toUpperCase()}` : label
}

export default function HudOverlay() {
  const [visible, setVisible] = useState(false)
  const [hud, setHud] = useState<HudData>(DEFAULT_HUD)
  const [leaveVisible, setLeaveVisible] = useState(false)
  const [leavePct, setLeavePct] = useState(0)
  const [waitingRoom, setWaitingRoom] = useState<WaitingRoom | null>(null)

  useListener<{ visible: boolean }>('lobby_minigames:hud:visible', (data) => {
    setVisible(!!(data && data.visible))
    if (!(data && data.visible)) setWaitingRoom(null)
  })

  useListener<HudData>('lobby_minigames:hud:update', (data) => {
    if (!data) return
    setHud(data)
  })

  useListener<{ visible: boolean; percent: number }>('lobby_minigames:leaveHold', (data) => {
    if (!data) return
    setLeaveVisible(!!data.visible)
    setLeavePct(Math.max(0, Math.min(100, Number(data.percent) || 0)))
  })

  useListener<WaitingRoom>('lobby_minigames:room:waiting', (data) => {
    if (!data) return
    setWaitingRoom(data)
  })

  useListener('lobby_minigames:room:closed', () => {
    setWaitingRoom(null)
  })

  if (!visible) return null

  const hpPct    = hud.hpMax    > 0 ? Math.max(0, Math.min(100, (hud.hp    / hud.hpMax)    * 100)) : 0
  const armorPct = hud.armorMax > 0 ? Math.max(0, Math.min(100, (hud.armor / hud.armorMax) * 100)) : 0

  return (
    <div
      className="pointer-events-none fixed inset-0 z-[200]"
      style={{ color: '#f8efff', fontFamily: 'Termina, Rajdhani, Inter, system-ui, sans-serif' }}
    >
      <div
        className="absolute left-1/2 flex w-[340px] flex-col items-stretch gap-[6px]"
        style={{ bottom: 35, transform: 'translateX(-50%)' }}
      >
        {waitingRoom && (
          <div
            className="flex h-[38px] items-center justify-between border-l-[3px] border-r-[3px] border-solid"
            style={{ background: 'rgba(29,28,38,0.92)', borderColor: '#e8ffb5', padding: '0 12px', boxSizing: 'border-box' }}
          >
            <div className="flex items-center gap-[8px]">
              <span
                className="inline-flex items-center justify-center"
                style={{
                  height: 18,
                  padding: '0 6px',
                  background: '#c8fe4e',
                  color: '#1d1c26',
                  fontWeight: 700,
                  fontSize: 10,
                  letterSpacing: '0.05em',
                  lineHeight: 1,
                  whiteSpace: 'nowrap',
                }}
              >
                {formatMode(waitingRoom.mode, waitingRoom.variant)}
              </span>
              <span style={{ fontWeight: 500, fontSize: 10, letterSpacing: '0.05em', whiteSpace: 'nowrap', lineHeight: 1 }}>
                AGUARDANDO JOGADORES
              </span>
            </div>
            <span
              style={{
                fontWeight: 700,
                fontSize: 13,
                color: '#c8fe4e',
                fontVariantNumeric: 'tabular-nums',
                letterSpacing: '0.05em',
                lineHeight: 1,
              }}
            >
              {Number(waitingRoom.current) || 0}/{Number(waitingRoom.max) || 0}
            </span>
          </div>
        )}

        <div
          className="flex h-[28px] items-center justify-center gap-[14px] border-l-[3px] border-r-[3px] border-solid"
          style={{ background: 'rgba(29,28,38,0.92)', borderColor: '#e8ffb5', padding: '0 14px', boxSizing: 'border-box' }}
        >
          {waitingRoom ? (
            <div className="inline-flex items-center gap-[6px]">
              <span
                className="inline-flex items-center justify-center"
                style={{
                  height: 18,
                  minWidth: 26,
                  padding: '0 6px',
                  background: '#ff6b6b',
                  color: '#1d1c26',
                  fontWeight: 700,
                  fontSize: 10,
                  letterSpacing: '0.05em',
                  lineHeight: 1,
                }}
              >
                F6
              </span>
              <span style={{ fontWeight: 500, fontSize: 10, letterSpacing: '0.05em', whiteSpace: 'nowrap', lineHeight: 1 }}>
                CANCELAR SALA
              </span>
            </div>
          ) : (
            <div className="inline-flex items-center gap-[6px]">
              <span
                className="inline-flex items-center justify-center"
                style={{
                  height: 18,
                  minWidth: 26,
                  padding: '0 6px',
                  background: '#c8fe4e',
                  color: '#1d1c26',
                  fontWeight: 700,
                  fontSize: 10,
                  letterSpacing: '0.05em',
                  lineHeight: 1,
                }}
              >
                F
              </span>
              <span style={{ fontWeight: 500, fontSize: 10, letterSpacing: '0.05em', whiteSpace: 'nowrap', lineHeight: 1 }}>
                SEGURE PARA VOLTAR AO LOBBY
              </span>
            </div>
          )}
        </div>

        <div className="relative w-full" style={{ background: 'rgba(29,28,38,0.85)', height: 6, overflow: 'hidden', boxSizing: 'border-box' }}>
          <div
            className="absolute left-0 top-0 h-[6px]"
            style={{ background: '#f8efff', width: `${armorPct}%`, transition: 'width 0.2s ease-out' }}
          />
        </div>

        <div
          className="relative w-full border-l-[3px] border-r-[3px] border-solid"
          style={{ background: 'rgba(29,28,38,0.85)', borderColor: '#e8ffb5', height: 18, overflow: 'hidden', boxSizing: 'border-box' }}
        >
          <div
            className="absolute left-0 top-0 h-[18px]"
            style={{ background: '#c8fe4e', width: `${hpPct}%`, transition: 'width 0.3s ease-out' }}
          />
          <div
            className="absolute inline-flex items-center gap-[2px]"
            style={{
              left: '50%',
              top: '50%',
              transform: 'translate(-50%, -50%)',
              mixBlendMode: 'difference',
              color: '#c8fe4e',
              fontWeight: 600,
              fontSize: 10,
              lineHeight: 1,
              fontVariantNumeric: 'tabular-nums',
              zIndex: 2,
            }}
          >
            <span style={{ fontSize: 11, lineHeight: 1 }}>♥</span>
            <span>{Math.round(hud.hp)}</span>
          </div>
        </div>

        {leaveVisible && (
          <div className="relative w-full" style={{ background: 'rgba(29,28,38,0.85)', height: 4, overflow: 'hidden' }}>
            <div
              className="absolute left-0 top-0 h-full"
              style={{ background: '#c8fe4e', width: `${leavePct}%`, transition: 'width 0.05s linear' }}
            />
          </div>
        )}
      </div>
    </div>
  )
}
