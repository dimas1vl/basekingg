import { useState, useEffect } from 'react'
import { useListener } from '@/hooks/listener'
import { isEnvBrowser } from '@/utils/misc'
import type {
  HudData,
  HudSlot,
  SquadMember,
  KillEntry,
  PhaseData,
  SafeZoneData,
  InteractionData,
  ActionData,
  MetersData,
  MatchAliveData,
  PregameShortcuts,
} from '@/types/hud'
import {
  DEFAULT_HUD,
  DEFAULT_SQUAD,
  DEFAULT_KILLFEED,
  DEFAULT_PHASE,
  DEFAULT_SAFEZONE,
  DEFAULT_INTERACTION,
  DEFAULT_ACTION,
  DEFAULT_METERS,
  DEFAULT_MATCH_ALIVE,
} from './defaults'
import WeaponHotbar from './components/WeaponHotbar'
import SquadPanel from './components/SquadPanel'
import WeaponInfo from './components/WeaponInfo'
import StatsBar from './components/StatsBar'
import VerticalMeters from './components/VerticalMeters'
import KillFeed from './components/KillFeed'
import SafeZoneAlert from './components/SafeZoneAlert'
import CompassBar from './components/CompassBar'
import InteractionPrompt from './components/InteractionPrompt'
import ActionBars from './components/ActionBars'
import ShortcutsBar from './components/ShortcutsBar'
import Airdrop from '@/modules/airdrop/page'

export default function Home() {
  const [hud, setHud] = useState<HudData>(DEFAULT_HUD)
  const [squad, setSquad] = useState<SquadMember[]>(DEFAULT_SQUAD)
  const [killFeed, setKillFeed] = useState<KillEntry[]>(DEFAULT_KILLFEED)
  const [phase, setPhase] = useState<PhaseData>(DEFAULT_PHASE)
  const [safeZone, setSafeZone] = useState<SafeZoneData>(DEFAULT_SAFEZONE)
  const [interaction, setInteraction] = useState<InteractionData>(DEFAULT_INTERACTION)
  const [action, setAction] = useState<ActionData>(DEFAULT_ACTION)
  const [meters, setMeters] = useState<MetersData>(DEFAULT_METERS)
  const [matchAlive, setMatchAlive] = useState<MatchAliveData>(DEFAULT_MATCH_ALIVE)
  const [shortcuts, setShortcuts] = useState<PregameShortcuts>({ visible: false, passive: false })
  const [leaveVisible, setLeaveVisible] = useState(false)
  const [leavePct, setLeavePct] = useState(0)
  const [isWarmup, setIsWarmup] = useState(false)
  const [minimapFrame, setMinimapFrame] = useState<{ x: number; y: number; w: number; h: number } | null>(null)

  useListener<Partial<HudData>>('hud:update', (data) => setHud((prev) => ({ ...prev, ...data })))
  useListener<SquadMember[]>('hud:squad', setSquad)
  useListener<{ slots: Array<HudSlot | false> }>('hud:hotbar', (data) => {
    if (data && data.slots) setHud((prev) => ({ ...prev, slots: data.slots }))
  })
  useListener<{ index?: string; ammo?: { current: number; max: number } }>('hud:weapon', (data) => {
    if (data && data.ammo) {
      setHud((prev) => ({ ...prev, ammo: data.ammo!.current, maxAmmo: data.ammo!.max }))
    }
  })
  useListener<Omit<KillEntry, 'id'>>('hud:killfeed', (entry) => {
    const id = Date.now()
    setKillFeed((prev) => [{ ...entry, id }, ...prev].slice(0, 6))
    setTimeout(() => setKillFeed((prev) => prev.filter((k) => k.id !== id)), 8000)
  })
  useListener<PhaseData>('hud:phase', setPhase)
  useListener<SafeZoneData>('hud:safezone', setSafeZone)
  useListener<InteractionData>('hud:interaction', setInteraction)
  useListener<ActionData>('hud:action', setAction)
  useListener<Partial<MetersData>>('hud:meters', (data) => setMeters((prev) => ({ ...prev, ...data })))
  useListener<MatchAliveData>('hud:matchAlive', setMatchAlive)
  useListener<{ x: number; y: number; w: number; h: number }>('hud:minimapFrame', setMinimapFrame)
  useListener<PregameShortcuts>('hud:shortcuts', setShortcuts)
  useListener<{ visible: boolean; percent: number }>('hud:leaveHold', (data) => {
    if (!data) return
    setLeaveVisible(!!data.visible)
    setLeavePct(Math.max(0, Math.min(100, Number(data.percent) || 0)))
  })
  useListener<boolean>('hud:warmup', setIsWarmup)

  useEffect(() => {
    if (!isEnvBrowser()) return

    setMatchAlive({ players: 24, squads: 8 })

    const KILLERS = ['[XXX] Tryhardao', '[ZZZ] SniperBR', 'Desconhecido', '[MMM] L4nce']
    const VICTIMS = ['[KZN] rACCOZr', '[KZN] EdmFilho', 'RandomEnemy', 'NomeSemTag']
    let tick = 0
    let altDir = 1
    let spdDir = 1
    let distDir = -1

    const sim = setInterval(() => {
      tick++

      setPhase((p) => {
        const total = parseInt(p.timer.split(':')[0]) * 60 + parseInt(p.timer.split(':')[1]) + 1
        return {
          ...p,
          timer: `${String(Math.floor(total / 60)).padStart(2, '0')}:${String(total % 60).padStart(2, '0')}`,
          progress: Math.min(1, p.progress + 0.002),
        }
      })

      setMeters((p) => {
        let alt = p.altitude + altDir * (2 + Math.random() * 4)
        if (alt >= 300) { alt = 300; altDir = -1 }
        else if (alt <= 30) { alt = 30; altDir = 1 }

        let spd = p.vehicleSpeed + spdDir * (6 + Math.random() * 12)
        if (spd >= 200) { spd = 200; spdDir = -1 }
        else if (spd <= 20) { spd = 20; spdDir = 1 }

        let dist = p.distance + distDir * (20 + Math.random() * 25)
        if (dist >= 500) { dist = 500; distDir = -1 }
        else if (dist <= 0) { dist = 0; distDir = 1 }

        const heading = ((p.heading + 1.2) % 360 + 360) % 360

        return {
          ...p,
          altitude:     Math.round(alt),
          vehicleSpeed: Math.max(0, Math.round(spd)),
          distance:     Math.round(dist),
          heading:      Math.round(heading),
        }
      })

      if (tick % 4 === 0) {
        setHud((p) => {
          const dmg = Math.random() > 0.6
          const heal = !dmg && p.health < 80
          const delta = dmg
            ? -(5 + Math.floor(Math.random() * 18))
            : heal
              ? Math.floor(Math.random() * 12 + 3)
              : 0
          const speed = p.speed + (Math.random() - 0.45) * 25
          const ammo = Math.max(0, p.ammo - (dmg ? Math.floor(Math.random() * 4) : 0))
          return {
            ...p,
            health: Math.max(0, Math.min(100, p.health + delta)),
            armor: Math.max(0, Math.min(100, p.armor - (dmg ? Math.floor(Math.random() * 5) : 0))),
            speed: Math.max(0, Math.min(280, speed)),
            ammo,
          }
        })
      }

      setAction((p) => {
        if (!p.visible || p.type !== 'medkit') return p
        const next = p.progress + 0.05
        return next >= 1
          ? { ...p, progress: 0 }
          : { ...p, progress: next }
      })

      if (tick % 8 === 0) {
        const killerTeam = Math.random() > 0.5
        const victimTeam = !killerTeam && Math.random() > 0.4
        const id = Date.now()
        const entry: KillEntry = {
          id,
          killer: killerTeam
            ? `[KZN] ${KILLERS[tick % KILLERS.length]}`
            : KILLERS[tick % KILLERS.length],
          victim: victimTeam
            ? VICTIMS[tick % VICTIMS.length]
            : `[ENM] ${VICTIMS[(tick + 1) % VICTIMS.length]}`,
          killerIsTeam: killerTeam,
          victimIsTeam: victimTeam,
        }
        setKillFeed((prev) => [entry, ...prev].slice(0, 6))
        if (killerTeam) setHud((p) => ({ ...p, kills: p.kills + 1 }))
        setTimeout(() => setKillFeed((prev) => prev.filter((k) => k.id !== id)), 8000)
      }

      if (tick % 3 === 0) {
        setSquad((prev) =>
          prev.map((m) => (m.alive ? { ...m, speaking: Math.random() > 0.65 } : m)),
        )
      }
    }, 200)

    return () => clearInterval(sim)
  }, [])

  return (
    <div className="absolute inset-0 overflow-hidden">
      <CompassBar heading={meters.heading} />
      {!isWarmup && (
        <StatsBar
          alivePlayers={matchAlive.players}
          aliveSquads={matchAlive.squads}
          kills={hud.kills}
          phase={phase}
          minimapFrame={minimapFrame}
        />
      )}
      <KillFeed entries={killFeed} />
      {safeZone.visible && <SafeZoneAlert title={safeZone.title} message={safeZone.message} />}
      {meters.visible && (
        <VerticalMeters
          distance={meters.distance}
          distanceLabel={meters.distanceLabel}
          vehicleSpeed={meters.vehicleSpeed}
        />
      )}
      <InteractionPrompt interaction={interaction} />
      <ActionBars action={action} />
      <ShortcutsBar {...shortcuts} leaveVisible={leaveVisible} leavePct={leavePct} />
      <SquadPanel squad={squad} />
      {!isWarmup && (
        <WeaponHotbar
          health={hud.health}
          armor={hud.armor}
          slots={hud.slots}
          activeSlot={hud.activeSlot}
        />
      )}
      {!isWarmup && (
        <WeaponInfo
          ammo={hud.ammo}
          maxAmmo={hud.maxAmmo}
          activeSlot={hud.activeSlot}
          speed={hud.speed}
          slots={hud.slots}
        />
      )}
      <Airdrop />
    </div>
  )
}
