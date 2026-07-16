import { useEffect, useState } from 'react'
import { useListener } from '@/hooks/listener'
import { isEnvBrowser } from '@/utils/misc'
import type { HudData, KillEntry } from '@/types/hud'
import { DEFAULT_HUD } from './defaults'
import WeaponHotbar from './components/WeaponHotbar'
import WeaponInfo from './components/WeaponInfo'
import StatsBar from './components/StatsBar'
import KillFeed from './components/KillFeed'

interface DmHudPayload {
  hp: number
  hpMax: number
  armor: number
  armorMax: number
  kills: number
  deaths: number
  streak: number
  players: number
  ammo?: number
  maxAmmo?: number
  weapon?: string
  inVehicle?: boolean
  speed?: number
}

interface DmWeaponsPayload {
  slots: Array<{ slot: number; label: string; weapon?: string }>
  selected: number
}

interface DmKillFeedPayload {
  killerSrc?: number | null
  killerName?: string | null
  victimSrc: number
  victimName: string
  weapon?: number
  streak?: number
}

interface DmHitmarker {
  x: number
  y: number
  damage: number
  lethal: boolean
}

interface DmScoreboardRow {
  src: number
  name: string
  kills: number
  deaths: number
  streak: number
  bestStreak: number
}

interface DmResult {
  scoreboard: DmScoreboardRow[]
  leaderSrc?: number | null
}

interface HitmarkerInstance extends DmHitmarker {
  id: number
}

let killSeq = 0
let markerSeq = 0

function Scoreboard({
  rows,
  selfSrc,
  visible,
}: {
  rows: DmScoreboardRow[]
  selfSrc: number
  visible: boolean
}) {

  if (!visible) return null

  const GRID = 'grid grid-cols-[3.6rem_1fr_5rem_5rem_5rem_5rem] gap-3'

  return (
    <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
      <div
        className="w-[840px] max-h-[82vh] overflow-hidden"
        style={{
          background: 'rgba(15,12,24,0.94)',
          border: '0.2rem solid rgba(248,239,255,0.12)',
          boxShadow: '0 18px 60px rgba(0,0,0,0.6)',
        }}
      >
        <div
          className="flex items-center justify-between h-[5.6rem] pl-[1.6rem] pr-[2rem] border-l-[8px] border-solid border-[#c8fe4e]"
          style={{
            background: 'linear-gradient(90deg, rgba(157,13,233,0.18) 0%, rgba(0,0,0,0) 100%)',
            borderBottom: '1px solid rgba(248,239,255,0.1)',
          }}
        >
          <div className="flex items-center gap-[1.2rem]">
            <span
              className="flex items-center justify-center h-[2.4rem] px-[1rem] font-['Termina:Bold',sans-serif] text-[1.1rem] tracking-[0.3rem]"
              style={{ backgroundColor: '#c8fe4e', color: '#1d1c26' }}
            >
              DRIVE-BY
            </span>
            <h1
              className="font-['Termina:Bold',sans-serif] text-[1.8rem] tracking-[0.4rem] text-[#f8efff]"
            >
              SCOREBOARD
            </h1>
          </div>
          <div className="flex items-center gap-[0.8rem]">
            <span
              className="flex items-center justify-center h-[2rem] min-w-[3.2rem] px-[0.8rem] font-['Termina:Bold',sans-serif] text-[1rem]"
              style={{ backgroundColor: '#c8fe4e', color: '#1d1c26' }}
            >
              TAB
            </span>
            <span className="font-['Termina:Medium',sans-serif] text-[1rem] tracking-[0.25rem] text-[#f8efff] opacity-55">
              SEGURE
            </span>
          </div>
        </div>

        <div
          className={`${GRID} px-[2.4rem] h-[3.2rem] items-center font-['Termina:Medium',sans-serif] text-[1rem] tracking-[0.25rem] text-[#f8efff] opacity-55`}
          style={{ borderBottom: '1px solid rgba(248,239,255,0.06)' }}
        >
          <span>#</span>
          <span>JOGADOR</span>
          <span className="text-right">KILLS</span>
          <span className="text-right">MORTES</span>
          <span className="text-right">K/D</span>
          <span className="text-right">STREAK</span>
        </div>

        <div className="max-h-[60vh] overflow-y-auto">
          {rows.map((r, i) => {

            const isSelf = r.src === selfSrc
            const kd = r.deaths > 0 ? (r.kills / r.deaths).toFixed(2) : r.kills.toString()

            return (
              <div
                key={r.src}
                className={`${GRID} px-[2.4rem] h-[3.6rem] items-center text-[1.2rem]`}
                style={{
                  color: isSelf ? '#c8fe4e' : '#f8efff',
                  backgroundColor: isSelf ? 'rgba(200,254,78,0.08)' : 'transparent',
                  borderLeft: isSelf ? '6px solid #c8fe4e' : '6px solid transparent',
                  borderBottom: '1px solid rgba(248,239,255,0.04)',
                }}
              >
                <span className="font-['Termina:Medium',sans-serif] opacity-65">{i + 1}</span>
                <span className="font-['Termina:Demi',sans-serif] truncate">{r.name}</span>
                <span className="font-['Termina:Bold',sans-serif] text-right">{r.kills}</span>
                <span className="font-['Termina:Medium',sans-serif] text-right opacity-75">{r.deaths}</span>
                <span className="font-['Termina:Medium',sans-serif] text-right opacity-75">{kd}</span>
                <span className="font-['Termina:Bold',sans-serif] text-right">{r.streak}</span>
              </div>
            )
          })}
        </div>
      </div>
    </div>
  )
}

function LeaveHold({ visible, percent }: { visible: boolean; percent: number }) {
  if (!visible) return null
  return (
    <div className="absolute bottom-[105px] left-1/2 -translate-x-1/2 pointer-events-none flex flex-col items-center gap-[4px] w-[480px]">
      <div className="bg-[rgba(29,28,38,0.92)] flex items-center justify-center gap-[8px] w-full h-[22px] px-[14px] border-l-[3px] border-r-[3px] border-solid border-[#e8ffb5]">
        <div
          className="flex items-center justify-center h-[15px] min-w-[22px] px-[5px] font-['Termina:Bold',sans-serif] text-[9px] tracking-wider"
          style={{ backgroundColor: '#c8fe4e', color: '#1d1c26' }}
        >
          F
        </div>
        <span className="font-['Termina:Medium',sans-serif] text-[9px] tracking-wider text-[#f8efff] whitespace-nowrap">
          SEGURE PARA SAIR DA PARTIDA
        </span>
      </div>
      <div className="bg-[rgba(29,28,38,0.85)] h-[4px] w-full overflow-hidden relative">
        <div
          className="absolute left-0 top-0 h-full bg-[#c8fe4e] transition-[width] duration-[50ms] ease-linear"
          style={{ width: `${Math.max(0, Math.min(100, percent))}%` }}
        />
      </div>
    </div>
  )
}

function HitMarkers({ markers }: { markers: HitmarkerInstance[] }) {

  return (
    <div className="absolute inset-0 pointer-events-none">
      {markers.map((m) => (
        <div
          key={m.id}
          className="absolute font-mono font-bold text-[1.6rem] animate-pulse"
          style={{
            left: `${m.x * 100}%`,
            top: `${m.y * 100}%`,
            transform: 'translate(-50%, -100%)',
            color: m.lethal ? '#ff3737' : '#fedb4e',
            textShadow: '0 0 4px rgba(0,0,0,0.85)',
            opacity: 0.95,
          }}
        >
          -{m.damage}
        </div>
      ))}
    </div>
  )
}

function ResultOverlay({
  result,
  selfSrc,
  visible,
}: {
  result: DmResult | null
  selfSrc: number
  visible: boolean
}) {

  if (!visible || !result) return null

  const leader = result.scoreboard.find((r) => r.src === result.leaderSrc)

  return (
    <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
      <div
        className="w-[640px] rounded-md overflow-hidden"
        style={{
          background: 'rgba(12,12,14,0.96)',
          border: '0.1rem solid rgba(248,239,255,0.12)',
        }}
      >
        <div className="px-6 py-5 text-center border-b border-white/10">
          <h1 className="text-[2.4rem] font-bold uppercase tracking-widest" style={{ color: '#c8fe4e' }}>
            FIM DE PARTIDA
          </h1>
          {leader && (
            <p className="mt-2 text-[1.2rem] text-white/65 uppercase tracking-wider">
              Vencedor: <span className="text-[#f8efff] font-semibold">{leader.name}</span> ({leader.kills} kills)
            </p>
          )}
        </div>
        <div className="max-h-[50vh] overflow-y-auto">
          {result.scoreboard.map((r, i) => {

            const isSelf = r.src === selfSrc

            return (
              <div
                key={r.src}
                className="grid grid-cols-[3rem_1fr_4.5rem_4.5rem] gap-3 px-6 py-2 text-[1.2rem] font-mono"
                style={{
                  color: isSelf ? '#c8fe4e' : '#f8efff',
                  backgroundColor: isSelf ? 'rgba(200,254,78,0.06)' : 'transparent',
                }}
              >
                <span className="text-white/45">{i + 1}</span>
                <span className="truncate font-sans">{r.name}</span>
                <span className="text-right">{r.kills}</span>
                <span className="text-right">{r.deaths}</span>
              </div>
            )
          })}
        </div>
      </div>
    </div>
  )
}

export default function Home() {

  const [hud, setHud] = useState<HudData>(DEFAULT_HUD)
  const [killFeed, setKillFeed] = useState<KillEntry[]>([])
  const [selfSrc, setSelfSrc] = useState<number>(0)
  const [scoreboardRows, setScoreboardRows] = useState<DmScoreboardRow[]>([])
  const [scoreboardVisible, setScoreboardVisible] = useState(false)
  const [hitmarkers, setHitmarkers] = useState<HitmarkerInstance[]>([])
  const [result, setResult] = useState<DmResult | null>(null)
  const [resultVisible, setResultVisible] = useState(false)
  const [leaveHold, setLeaveHold] = useState<{ visible: boolean; percent: number }>({ visible: false, percent: 0 })

  useListener<{ data: DmHudPayload }>('hud', ({ data }) => {
    if (!data) return
    setHud((prev) => ({
      ...prev,
      health: data.hp,
      armor: data.armor,
      kills: data.kills,
      deaths: data.deaths,
      killStreak: data.streak,
      players: data.players,
      ammo: typeof data.ammo === 'number' ? data.ammo : prev.ammo,
      maxAmmo: typeof data.maxAmmo === 'number' ? data.maxAmmo : prev.maxAmmo,
      activeWeapon: data.weapon ?? prev.activeWeapon,
      inVehicle: data.inVehicle === true,
      speed: typeof data.speed === 'number' ? data.speed : 0,
    }))
  })

  useListener<{ data: DmWeaponsPayload }>('weapons', ({ data }) => {
    if (!data) return
    const slots = (data.slots ?? []).map((s) => ({
      ammo: 1 as number | null,
      weapon: s.weapon,
      label: s.label,
    }))
    setHud((prev) => ({
      ...prev,
      slots: slots.length > 0 ? slots : prev.slots,
      activeSlot: data.selected ?? prev.activeSlot,
      activeWeapon: slots[(data.selected ?? 1) - 1]?.weapon ?? prev.activeWeapon,
    }))
  })

  useListener<{ selected: number; weapon?: string }>('weapon', ({ selected, weapon }) => {
    setHud((prev) => ({
      ...prev,
      activeSlot: selected ?? prev.activeSlot,
      activeWeapon: weapon ?? prev.slots[(selected ?? 1) - 1]?.weapon ?? prev.activeWeapon,
    }))
  })

  useListener<{ data: DmKillFeedPayload; selfSrc?: number }>('killFeed', ({ data, selfSrc: sSrc }) => {
    if (!data) return
    if (typeof sSrc === 'number') setSelfSrc(sSrc)
    killSeq += 1
    const id = killSeq
    const isSelfKiller = data.killerSrc != null && data.killerSrc === (sSrc ?? selfSrc)
    const isSelfVictim = data.victimSrc === (sSrc ?? selfSrc)
    const kf: KillEntry = {
      id,
      killer: data.killerName ?? 'Desconhecido',
      victim: data.victimName ?? 'Player',
      killerIsTeam: isSelfKiller,
      victimIsTeam: isSelfVictim,
    }
    setKillFeed((prev) => [kf, ...prev].slice(0, 6))
    setTimeout(() => setKillFeed((prev) => prev.filter((k) => k.id !== id)), 8000)
  })

  useListener<{ data: DmScoreboardRow[]; selfSrc?: number }>('scoreboard', ({ data, selfSrc: sSrc }) => {
    const rows = Array.isArray(data)
      ? data
      : data && typeof data === 'object'
        ? Object.values(data as Record<string, DmScoreboardRow>)
        : []
    setScoreboardRows(rows)
    if (typeof sSrc === 'number') setSelfSrc(sSrc)
  })

  useListener<{ value: boolean }>('scoreboardVisible', ({ value }) => setScoreboardVisible(!!value))

  useListener<{ data: DmHitmarker }>('hitmarker', ({ data }) => {
    if (!data) return
    markerSeq += 1
    const id = markerSeq
    setHitmarkers((prev) => [...prev, { ...data, id }])
    setTimeout(() => setHitmarkers((prev) => prev.filter((h) => h.id !== id)), 700)
  })

  useListener<{ data: DmResult; selfSrc?: number }>('result', ({ data, selfSrc: sSrc }) => {
    if (!data) return
    if (typeof sSrc === 'number') setSelfSrc(sSrc)
    setResult(data)
    setResultVisible(true)
    setTimeout(() => setResultVisible(false), 8000)
  })

  useListener<{ value: string }>('state', () => {
    /* reserved for future use */
  })

  useListener<{ visible: boolean; percent: number }>('leaveHold', (msg) => {
    setLeaveHold({ visible: !!msg.visible, percent: Number(msg.percent) || 0 })
  })

  useEffect(() => {
    if (!isEnvBrowser()) return

    const dev = setInterval(() => {
      setHud((prev) => ({
        ...prev,
        health: Math.max(0, Math.min(100, prev.health + (Math.random() - 0.5) * 8)),
      }))
    }, 1000)

    return () => clearInterval(dev)
  }, [])

  return (
    <div className="absolute inset-0 overflow-hidden">
      <StatsBar
        kills={hud.kills}
        deaths={hud.deaths}
        killStreak={hud.killStreak}
        players={hud.players}
      />

      <KillFeed entries={killFeed} />

      <WeaponHotbar
        health={hud.health}
        armor={hud.armor}
        slots={hud.slots}
        activeSlot={hud.activeSlot}
      />

      <WeaponInfo
        ammo={hud.ammo}
        maxAmmo={hud.maxAmmo}
        activeSlot={hud.activeSlot}
        speed={hud.speed}
        weapon={hud.activeWeapon}
        showSpeed={hud.inVehicle}
      />

      <HitMarkers markers={hitmarkers} />
      <Scoreboard rows={scoreboardRows} selfSrc={selfSrc} visible={scoreboardVisible} />
      <ResultOverlay result={result} selfSrc={selfSrc} visible={resultVisible} />
      <LeaveHold visible={leaveHold.visible} percent={leaveHold.percent} />
    </div>
  )
}
