import { useState, useEffect, useRef } from 'react'
import { useListener } from '@/hooks/listener'
import { getWeaponImage } from '@/config/weapons'
import { imgVector1, imgUnion, imgVector3, imgMaskGroup, imgVector4, imgVector5, imgUnion2 } from './assets'
import TeammateMarkers from './TeammateMarkers'
import SpectatePanel from './SpectatePanel'

const FONT = 'Termina, Rajdhani, Inter, system-ui, sans-serif'
const COLOR_BG     = 'rgba(29, 28, 38, 0.92)'
const COLOR_BG_SOFT = 'rgba(29, 28, 38, 0.75)'
const COLOR_ACCENT = '#c8fe4e'
const COLOR_ACCENT_BORDER = '#e8ffb5'
const COLOR_LIGHT  = '#f8efff'
const COLOR_DANGER = '#ff6b6b'
const COLOR_MUTED  = 'rgba(248,239,255,0.55)'

interface MatchInfo {
  variant?: string
  selfSrc?: number
  isInMatch?: boolean
}

interface WeaponSlot {
  slot: number
  label: string
  weapon: string
}

interface WeaponsPayload {
  slots: WeaponSlot[]
  selected: number
}

interface HudData {
  hp: number
  hpMax: number
  armor: number
  armorMax: number
  ammo: number
  maxAmmo: number
  weapon?: string | null
  frozen: boolean
  freezeMs: number
}

interface ScoreboardEntry {
  src: number
  name: string
  score: number
  alive: boolean
}

interface RoundInfo {
  roundNumber: number
  mapName: string
  variant: string
  scoreLimit: number
  clutchSrc?: number | null
  scoreboard: ScoreboardEntry[]
}

interface RoundResult {
  roundNumber: number
  winnerSrc?: number | null
  winnerName?: string | null
  newClutchSrc?: number | null
  newClutchName?: string | null
  scoreboard: ScoreboardEntry[]
  showMs: number
}

interface MatchResult {
  winnerSrc?: number | null
  winnerName?: string | null
  winnerScore: number
  scoreboard: ScoreboardEntry[]
  reason: string
  forfeiterSrc?: number | null
  showMs: number
}

interface KillFeedEntry {
  id: number
  killerSrc?: number | null
  killerName?: string | null
  victimSrc: number
  victimName: string
  weapon?: number | null
}

interface ZoneState {
  radius: number
  startRadius: number
  endRadius: number
  elapsedMs: number
  shrinkMs: number
}

interface LeaveHold {
  visible: boolean
  percent: number
}

const DEFAULT_HUD: HudData = {
  hp: 100, hpMax: 200, armor: 0, armorMax: 100,
  ammo: 0, maxAmmo: 0, weapon: null, frozen: false, freezeMs: 0,
}

let killFeedSeq = 0

export default function HudPage() {
  const [matchInfo,   setMatchInfo]   = useState<MatchInfo>({})
  const [weapons,     setWeapons]     = useState<WeaponsPayload>({ slots: [], selected: 1 })
  const [hud,         setHud]         = useState<HudData>(DEFAULT_HUD)
  const [scoreboard,  setScoreboard]  = useState<ScoreboardEntry[]>([])
  const [roundInfo,   setRoundInfo]   = useState<RoundInfo | null>(null)
  const [killFeed,    setKillFeed]    = useState<KillFeedEntry[]>([])
  const [roundResult, setRoundResult] = useState<RoundResult | null>(null)
  const [matchResult, setMatchResult] = useState<MatchResult | null>(null)
  const [zone,        setZone]        = useState<ZoneState | null>(null)
  const [leaveHold,   setLeaveHold]   = useState<LeaveHold>({ visible: false, percent: 0 })
  const [isClutch,    setIsClutch]    = useState(false)
  const [fightStarted, setFightStarted] = useState(false)
  const [freezeDeadline, setFreezeDeadline] = useState<number | null>(null)
  const [, setFreezeTick] = useState(0)
  const roundResultTimer = useRef<ReturnType<typeof setTimeout> | null>(null)
  const matchResultTimer = useRef<ReturnType<typeof setTimeout> | null>(null)

  useListener<{ active: boolean; ms: number }>('freeze', (data) => {
    if (!data) return
    if (data.active && Number(data.ms) > 0) {
      setFreezeDeadline(Date.now() + Number(data.ms))
    } else {
      setFreezeDeadline(null)
    }
  })

  useEffect(() => {
    if (!freezeDeadline) return
    const id = setInterval(() => setFreezeTick((t) => t + 1), 100)
    return () => clearInterval(id)
  }, [freezeDeadline])
  useListener<MatchInfo>('matchInfo', (data) => data && setMatchInfo(data))
  useListener<WeaponsPayload>('weapons', (data) => data && setWeapons(data))
  useListener<{ selected: number; weapon: string }>('weapon', (data) => {
    if (data) setWeapons((prev) => ({ ...prev, selected: data.selected }))
  })
  useListener<HudData>('hud', (data) => data && setHud(data))
  useListener<ScoreboardEntry[]>('scoreboard', (data) => Array.isArray(data) && setScoreboard(data))
  useListener<RoundInfo>('roundInfo', (data) => {
    if (!data) return
    setRoundInfo(data)
    setRoundResult(null)
    setFightStarted(false)
    if (Array.isArray(data.scoreboard)) setScoreboard(data.scoreboard)
  })
  useListener<{ isClutch: boolean; freezeMs: number }>('roleUpdate', (data) => {
    if (!data) return
    setIsClutch(!!data.isClutch)
  })
  useListener('fightStart', () => setFightStarted(true))
  useListener<KillFeedEntry>('killFeed', (data) => {
    if (!data) return
    const entry: KillFeedEntry = { ...data, id: ++killFeedSeq }
    setKillFeed((prev) => [entry, ...prev].slice(0, 5))
    setTimeout(() => {
      setKillFeed((prev) => prev.filter((e) => e.id !== entry.id))
    }, 4500)
  })
  useListener<RoundResult>('roundResult', (data) => {
    if (!data) return
    setRoundResult(data)
    setFightStarted(false)
    if (Array.isArray(data.scoreboard)) setScoreboard(data.scoreboard)
    if (roundResultTimer.current) clearTimeout(roundResultTimer.current)
    roundResultTimer.current = setTimeout(() => setRoundResult(null), data.showMs || 3000)
  })
  useListener<MatchResult>('matchResult', (data) => {
    if (!data) return
    setMatchResult(data)
    if (Array.isArray(data.scoreboard)) setScoreboard(data.scoreboard)
    if (matchResultTimer.current) clearTimeout(matchResultTimer.current)
    matchResultTimer.current = setTimeout(() => setMatchResult(null), data.showMs || 8000)
  })
  useListener<ZoneState>('zoneUpdate', (data) => data && setZone(data))
  useListener<LeaveHold>('leaveHold', (data) => data && setLeaveHold(data))

  useEffect(() => () => {
    if (roundResultTimer.current) clearTimeout(roundResultTimer.current)
    if (matchResultTimer.current) clearTimeout(matchResultTimer.current)
  }, [])

  const selfSrc = matchInfo.selfSrc
  const me = scoreboard.find((p) => p.src === selfSrc)
  const opponents = scoreboard.filter((p) => p.src !== selfSrc)
  const scoreLimit = roundInfo?.scoreLimit ?? 10
  const clutchSrc = roundInfo?.clutchSrc ?? null

  const remainingFreezeMs = freezeDeadline ? Math.max(0, freezeDeadline - Date.now()) : 0
  const showFreezeOverlay = !fightStarted && remainingFreezeMs > 0

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        color: COLOR_LIGHT,
        fontFamily: FONT,
        pointerEvents: 'none',
        userSelect: 'none',
      }}
    >
      <TopHud
        roundInfo={roundInfo}
        matchInfo={matchInfo}
        scoreboard={scoreboard}
        scoreLimit={scoreLimit}
        clutchSrc={clutchSrc}
        isClutch={isClutch}
      />

      <KillFeedList feed={killFeed} selfSrc={selfSrc} />

      {showFreezeOverlay && (
        <FreezeOverlay ms={remainingFreezeMs} />
      )}

      <WeaponHotbar hud={hud} weapons={weapons} leaveHold={leaveHold} zone={zone} />
      <WeaponInfoCard hud={hud} />
      <TeammateMarkers />
      <SpectatePanel />

      {roundResult && <RoundResultBanner result={roundResult} selfSrc={selfSrc} />}
      {matchResult && <MatchResultBanner result={matchResult} selfSrc={selfSrc} />}
    </div>
  )
}

function PlayerPanel({
  player,
  isSelf,
  isClutchPlayer,
  scoreLimit,
  side,
}: {
  player?: ScoreboardEntry
  isSelf?: boolean
  isClutchPlayer?: boolean
  scoreLimit: number
  side: 'left' | 'right'
}) {
  if (!player) return null
  const accent = isSelf ? COLOR_ACCENT : COLOR_DANGER
  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: side === 'left' ? 'flex-start' : 'flex-end',
        gap: 5,
        minWidth: 130,
        padding: '4px 2px',
      }}
    >
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: 8,
          flexDirection: side === 'left' ? 'row' : 'row-reverse',
        }}
      >
        <span
          style={{
            fontSize: 24,
            fontWeight: 800,
            color: accent,
            fontVariantNumeric: 'tabular-nums',
            lineHeight: 1,
            fontFamily: 'Termina, sans-serif',
          }}
        >
          {player.score}
        </span>
        <span
          style={{
            fontSize: 12,
            fontWeight: 700,
            letterSpacing: '0.05em',
            color: player.alive ? COLOR_LIGHT : COLOR_MUTED,
            textDecoration: player.alive ? 'none' : 'line-through',
            whiteSpace: 'nowrap',
            maxWidth: 140,
            overflow: 'hidden',
            textOverflow: 'ellipsis',
          }}
        >
          {player.name}
        </span>
        {isClutchPlayer && (
          <span
            style={{
              fontSize: 8,
              fontWeight: 700,
              letterSpacing: '0.1em',
              padding: '2px 5px',
              background: COLOR_DANGER,
              color: '#1d1c26',
              lineHeight: 1,
            }}
          >
            CLUTCH
          </span>
        )}
      </div>
      <RoundDots score={player.score} max={scoreLimit} accent={accent} />
    </div>
  )
}

function RoundDots({ score, max, accent }: { score: number; max: number; accent: string }) {
  const dots = []
  for (let i = 0; i < max; i++) {
    const filled = i < score
    dots.push(
      <span
        key={i}
        style={{
          width: 6,
          height: 6,
          borderRadius: '50%',
          background: filled ? accent : 'rgba(248,239,255,0.13)',
          boxShadow: filled ? `0 0 4px ${accent}80` : 'none',
          display: 'inline-block',
          transition: 'background 0.2s ease, box-shadow 0.2s ease',
        }}
      />
    )
  }
  return <div style={{ display: 'flex', gap: 3, alignItems: 'center' }}>{dots}</div>
}

function TopHud({
  roundInfo,
  matchInfo,
  scoreboard,
  scoreLimit,
  clutchSrc,
  isClutch,
}: {
  roundInfo: RoundInfo | null
  matchInfo: MatchInfo
  scoreboard: ScoreboardEntry[]
  scoreLimit: number
  clutchSrc: number | null
  isClutch: boolean
}) {
  if (!roundInfo) return null
  const variantLabel = (matchInfo.variant || roundInfo.variant || '').toUpperCase()
  const selfSrc      = matchInfo.selfSrc

  let leftPlayers:  ScoreboardEntry[] = []
  let rightPlayers: ScoreboardEntry[] = []
  let leftLabel  = ''
  let rightLabel = ''

  if (matchInfo.variant === '1v2' && clutchSrc != null) {
    leftPlayers  = scoreboard.filter((p) => p.src === clutchSrc)
    rightPlayers = scoreboard.filter((p) => p.src !== clutchSrc)
    leftLabel    = 'CLUTCH'
    rightLabel   = 'DUO'
  } else {
    const meIdx = selfSrc != null ? scoreboard.findIndex((p) => p.src === selfSrc) : -1
    if (meIdx >= 0) {
      leftPlayers  = [scoreboard[meIdx]]
      rightPlayers = scoreboard.filter((_, i) => i !== meIdx)
    } else {
      leftPlayers  = scoreboard.slice(0, 1)
      rightPlayers = scoreboard.slice(1)
    }
  }

  return (
    <div
      style={{
        position: 'absolute',
        top: 24,
        left: '50%',
        transform: 'translateX(-50%)',
        display: 'flex',
        alignItems: 'flex-start',
        gap: 22,
      }}
    >
      <TeamColumn
        label={leftLabel}
        players={leftPlayers}
        scoreLimit={scoreLimit}
        side="left"
        selfSrc={selfSrc}
        clutchSrc={clutchSrc}
      />

      <div
        style={{
          display: 'flex',
          flexDirection: 'column',
          gap: 6,
          alignItems: 'center',
        }}
      >
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 12,
            padding: '10px 18px',
            background: COLOR_BG,
            borderLeft:  `3px solid ${COLOR_ACCENT_BORDER}`,
            borderRight: `3px solid ${COLOR_ACCENT_BORDER}`,
          }}
        >
          <span
            style={{
              background: COLOR_ACCENT,
              color: '#1d1c26',
              fontWeight: 700,
              fontSize: 11,
              padding: '3px 10px',
              letterSpacing: '0.1em',
            }}
          >
            CLUTCH · {variantLabel}
          </span>
          <span style={{ fontSize: 12, fontWeight: 600, letterSpacing: '0.05em', color: COLOR_MUTED }}>
            ROUND {roundInfo.roundNumber}
          </span>
          <span style={{ fontSize: 12, fontWeight: 700, letterSpacing: '0.07em', color: COLOR_LIGHT }}>
            {roundInfo.mapName}
          </span>
        </div>
        <div
          style={{
            fontSize: 9,
            letterSpacing: '0.18em',
            color: COLOR_MUTED,
            fontWeight: 700,
          }}
        >
          PRIMEIRO A {scoreLimit} {scoreLimit === 1 ? 'ROUND' : 'ROUNDS'}{matchInfo.variant === '1v2' ? (isClutch ? ' · VOCÊ É O CLUTCH' : ' · VOCÊ É DUO') : ''}
        </div>
      </div>

      <TeamColumn
        label={rightLabel}
        players={rightPlayers}
        scoreLimit={scoreLimit}
        side="right"
        selfSrc={selfSrc}
        clutchSrc={clutchSrc}
      />
    </div>
  )
}

function TeamColumn({
  label,
  players,
  scoreLimit,
  side,
  selfSrc,
  clutchSrc,
}: {
  label: string
  players: ScoreboardEntry[]
  scoreLimit: number
  side: 'left' | 'right'
  selfSrc?: number
  clutchSrc: number | null
}) {
  if (players.length === 0) return null
  const teamAccent = label === 'CLUTCH' ? COLOR_DANGER : (label === 'DUO' ? COLOR_ACCENT : COLOR_MUTED)
  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        gap: 10,
        alignItems: side === 'left' ? 'flex-end' : 'flex-start',
        minWidth: 150,
      }}
    >
      {label && (
        <span
          style={{
            fontSize: 9,
            letterSpacing: '0.22em',
            fontWeight: 800,
            color: teamAccent,
            padding: '2px 6px',
            borderLeft:  side === 'left'  ? 'none'                      : `2px solid ${teamAccent}`,
            borderRight: side === 'right' ? 'none'                      : `2px solid ${teamAccent}`,
            lineHeight: 1,
          }}
        >
          {label}
        </span>
      )}
      {players.map((p) => (
        <PlayerPanel
          key={p.src}
          player={p}
          isSelf={selfSrc != null && p.src === selfSrc}
          isClutchPlayer={p.src === clutchSrc}
          scoreLimit={scoreLimit}
          side={side}
        />
      ))}
    </div>
  )
}

function ZoneTopBar({ zone }: { zone: ZoneState | null }) {
  if (!zone || zone.shrinkMs <= 0 || zone.startRadius <= 0) return null
  const remainingPct = Math.min(1, Math.max(0,
    zone.startRadius > zone.endRadius
      ? (zone.radius - zone.endRadius) / (zone.startRadius - zone.endRadius)
      : 0
  ))
  return (
    <div
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 10,
        width: '100%',
        height: 22,
        padding: '0 12px',
        background: COLOR_BG,
        borderLeft:  `3px solid ${COLOR_DANGER}`,
        borderRight: `3px solid ${COLOR_DANGER}`,
        boxSizing: 'border-box',
      }}
    >
      <span
        style={{
          fontSize: 10,
          fontWeight: 700,
          letterSpacing: '0.12em',
          color: COLOR_DANGER,
          whiteSpace: 'nowrap',
        }}
      >
        ZONA
      </span>
      <div
        style={{
          flex: 1,
          height: 4,
          background: 'rgba(248,239,255,0.1)',
          position: 'relative',
          overflow: 'hidden',
        }}
      >
        <div
          style={{
            position: 'absolute',
            left: 0,
            top: 0,
            height: '100%',
            width: `${remainingPct * 100}%`,
            background: COLOR_DANGER,
            transition: 'width 0.4s linear',
          }}
        />
      </div>
      <span
        style={{
          fontSize: 11,
          fontWeight: 700,
          color: COLOR_DANGER,
          fontVariantNumeric: 'tabular-nums',
          whiteSpace: 'nowrap',
          minWidth: 44,
          textAlign: 'right',
        }}
      >
        {Math.round(zone.radius)}M
      </span>
    </div>
  )
}

function KillFeedList({ feed, selfSrc }: { feed: KillFeedEntry[]; selfSrc?: number }) {
  return (
    <div
      style={{
        position: 'absolute',
        top: 220,
        right: 24,
        display: 'flex',
        flexDirection: 'column',
        gap: 4,
        alignItems: 'flex-end',
      }}
    >
      {feed.map((entry) => {
        const isSelfKiller = entry.killerSrc === selfSrc
        const isSelfVictim = entry.victimSrc === selfSrc
        return (
          <div
            key={entry.id}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 8,
              padding: '4px 10px',
              background: COLOR_BG,
              borderLeft: `3px solid ${isSelfKiller ? COLOR_ACCENT : isSelfVictim ? COLOR_DANGER : 'rgba(248,239,255,0.3)'}`,
              fontSize: 11,
              fontWeight: 600,
              letterSpacing: '0.05em',
            }}
          >
            <span style={{ color: isSelfKiller ? COLOR_ACCENT : COLOR_LIGHT }}>
              {entry.killerName || 'ZONA'}
            </span>
            <span style={{ color: COLOR_MUTED }}>›</span>
            <span style={{ color: isSelfVictim ? COLOR_DANGER : COLOR_LIGHT, textDecoration: 'line-through', opacity: 0.85 }}>
              {entry.victimName}
            </span>
          </div>
        )
      })}
    </div>
  )
}

function FreezeOverlay({ ms }: { ms: number }) {
  const seconds = Math.ceil(ms / 1000)
  return (
    <div
      style={{
        position: 'absolute',
        top: '40%',
        left: '50%',
        transform: 'translate(-50%, -50%)',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: 8,
      }}
    >
      <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: '0.2em', color: COLOR_ACCENT }}>
        PREPARE-SE
      </div>
      <div
        style={{
          fontSize: 72,
          fontWeight: 800,
          color: COLOR_ACCENT,
          textShadow: '0 4px 24px rgba(0,0,0,0.6)',
          fontVariantNumeric: 'tabular-nums',
          lineHeight: 1,
        }}
      >
        {seconds}
      </div>
    </div>
  )
}

function ControlHint({ keyLabel, action }: { keyLabel: string; action: string }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexShrink: 0 }}>
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          height: 18,
          minWidth: 26,
          padding: '0 6px',
          background: COLOR_ACCENT,
          color: '#1d1c26',
          fontWeight: 700,
          fontSize: 10,
          letterSpacing: '0.08em',
          lineHeight: 1,
        }}
      >
        {keyLabel}
      </div>
      <span style={{ fontSize: 10, fontWeight: 500, letterSpacing: '0.08em', color: COLOR_LIGHT, whiteSpace: 'nowrap' }}>
        {action}
      </span>
    </div>
  )
}

function WeaponHotbar({ hud, weapons, leaveHold, zone }: { hud: HudData; weapons: WeaponsPayload; leaveHold: LeaveHold; zone: ZoneState | null }) {
  const hpPct    = hud.hpMax    > 0 ? Math.max(0, Math.min(100, (hud.hp    / hud.hpMax)    * 100)) : 0
  const armorPct = hud.armorMax > 0 ? Math.max(0, Math.min(100, (hud.armor / hud.armorMax) * 100)) : 0
  const slotCount  = weapons.slots.length
  const slotsLabel = slotCount > 1 ? `1-${slotCount}` : slotCount === 1 ? '1' : '1-8'

  return (
    <div
      style={{
        position: 'absolute',
        bottom: 35,
        left: '50%',
        transform: 'translateX(-50%)',
        display: 'flex',
        flexDirection: 'column',
        gap: 6,
        width: 480,
      }}
    >
      <ZoneTopBar zone={zone} />

      {leaveHold.visible && (
        <div style={{ height: 4, background: COLOR_BG_SOFT, overflow: 'hidden' }}>
          <div
            style={{
              height: '100%',
              background: COLOR_ACCENT,
              width: `${leaveHold.percent}%`,
              transition: 'width 0.05s linear',
            }}
          />
        </div>
      )}

      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-around',
          gap: 14,
          width: '100%',
          height: 28,
          padding: '0 14px',
          background: COLOR_BG,
          borderLeft:  `3px solid ${COLOR_ACCENT_BORDER}`,
          borderRight: `3px solid ${COLOR_ACCENT_BORDER}`,
          boxSizing: 'border-box',
        }}
      >
        <ControlHint keyLabel="F" action="SAIR DA PARTIDA" />
        <ControlHint keyLabel={slotsLabel} action="ARMAS" />
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 4, width: '100%' }}>
        <div style={{ height: 6, background: COLOR_BG_SOFT, overflow: 'hidden', position: 'relative' }}>
          <div
            style={{
              position: 'absolute',
              left: 0,
              top: 0,
              height: 6,
              width: `${armorPct}%`,
              background: COLOR_LIGHT,
              transition: 'width 0.2s ease-out',
            }}
          />
        </div>
        <div
          style={{
            position: 'relative',
            height: 18,
            background: COLOR_BG_SOFT,
            borderLeft:  `3px solid ${COLOR_ACCENT_BORDER}`,
            borderRight: `3px solid ${COLOR_ACCENT_BORDER}`,
            overflow: 'hidden',
            boxSizing: 'border-box',
          }}
        >
          <div
            style={{
              position: 'absolute',
              left: 0,
              top: 0,
              height: 18,
              width: `${hpPct}%`,
              background: COLOR_ACCENT,
              transition: 'width 0.3s ease-out',
            }}
          />
          <div
            style={{
              position: 'absolute',
              left: -68,
              top: -151,
              width: 577,
              height: 776,
              pointerEvents: 'none',
              opacity: 0.4,
            }}
          >
            <div style={{ transform: 'scaleY(-1) rotate(180deg)', width: '100%', height: '100%' }}>
              <img alt="" src={imgVector1} style={{ display: 'block', width: '100%', height: '100%' }} />
            </div>
          </div>
          <div
            style={{
              position: 'absolute',
              top: '50%',
              left: '50%',
              transform: 'translate(-50%, -50%)',
              display: 'flex',
              alignItems: 'center',
              gap: 2,
              mixBlendMode: 'difference',
              color: COLOR_ACCENT,
              fontWeight: 700,
              fontSize: 10,
              fontVariantNumeric: 'tabular-nums',
            }}
          >
            <img alt="" src={imgUnion} style={{ width: 10, height: 10, display: 'block' }} />
            <span>{Math.round(hud.hp)}</span>
          </div>
        </div>
      </div>
    </div>
  )
}

function WeaponInfoCard({ hud }: { hud: HudData }) {
  const ammoStr   = String(hud.ammo)
  const isInfinite = !hud.maxAmmo || hud.maxAmmo > 9000
  return (
    <div
      style={{
        position: 'absolute',
        bottom: 40,
        right: 35,
        height: 44,
        width: 211,
      }}
    >
      <div style={{ position: 'absolute', left: 0, top: -1, width: 211, height: 47 }}>
        <img alt="" src={imgVector3} style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', display: 'block' }} />
      </div>
      <div style={{ position: 'absolute', left: 0, top: -1, width: 211, height: 47 }}>
        <img alt="" src={imgMaskGroup} style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', display: 'block' }} />
      </div>
      <div style={{ position: 'absolute', left: -2, top: -3, width: 215, height: 51 }}>
        <img alt="" src={imgVector4} style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', display: 'block' }} />
      </div>

      <div
        style={{
          position: 'absolute',
          right: 18,
          top: '50%',
          transform: 'translateY(-50%)',
          display: 'flex',
          alignItems: 'center',
          gap: 6,
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 2, color: COLOR_LIGHT, fontSize: 12 }}>
            <span style={{ fontWeight: 700, fontFamily: 'Termina, sans-serif' }}>{ammoStr}</span>
            <span style={{ fontWeight: 500, opacity: 0.55 }}>/</span>
            <span style={{ fontWeight: 500, opacity: 0.55, fontSize: isInfinite ? 16 : 12, fontVariantNumeric: 'tabular-nums' }}>
              {isInfinite ? '∞' : hud.maxAmmo}
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', width: 12, height: 13 }}>
            <div style={{ transform: 'rotate(-90deg)' }}>
              <img alt="" src={imgVector5} style={{ width: 13, height: 12, display: 'block' }} />
            </div>
          </div>
        </div>
        <div style={{ position: 'relative', height: 44, width: 83 }}>
          <div
            style={{
              position: 'absolute',
              right: 0,
              top: 'calc(50% - 0.04px)',
              transform: 'translateY(-50%)',
              width: 82.573,
              height: 27.911,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <div style={{ transform: 'scaleY(-1) rotate(180deg)', width: '100%', height: '100%' }}>
              <img
                alt=""
                src={getWeaponImage(hud.weapon || undefined)}
                style={{ width: '100%', height: '100%', objectFit: 'contain', display: 'block' }}
              />
            </div>
          </div>
        </div>
      </div>

      <div style={{ position: 'absolute', left: 160, top: -5, width: 25, height: 10 }}>
        <img alt="" src={imgUnion2} style={{ display: 'block', width: '100%', height: '100%' }} />
      </div>
    </div>
  )
}

function RoundResultBanner({ result, selfSrc }: { result: RoundResult; selfSrc?: number }) {
  const isWinner = result.winnerSrc != null && result.winnerSrc === selfSrc
  const isNewClutch = result.newClutchSrc != null && result.newClutchSrc === selfSrc
  return (
    <div
      style={{
        position: 'absolute',
        top: '32%',
        left: '50%',
        transform: 'translate(-50%, -50%)',
        textAlign: 'center',
        padding: '14px 28px',
        background: COLOR_BG,
        borderLeft:  `3px solid ${isWinner ? COLOR_ACCENT_BORDER : COLOR_DANGER}`,
        borderRight: `3px solid ${isWinner ? COLOR_ACCENT_BORDER : COLOR_DANGER}`,
      }}
    >
      <div style={{ fontSize: 10, letterSpacing: '0.2em', fontWeight: 700, color: COLOR_MUTED }}>
        ROUND {result.roundNumber}
      </div>
      <div
        style={{
          fontSize: 24,
          fontWeight: 800,
          color: isWinner ? COLOR_ACCENT : COLOR_LIGHT,
          marginTop: 4,
          letterSpacing: '0.05em',
        }}
      >
        {result.winnerName ? `${result.winnerName} CLUTCH +1` : 'EMPATE'}
      </div>
      {result.newClutchName && (
        <div style={{ fontSize: 11, color: COLOR_DANGER, marginTop: 6, letterSpacing: '0.1em', fontWeight: 600 }}>
          {isNewClutch ? 'VOCE ASSUMIU O CLUTCH' : `NOVO CLUTCH: ${result.newClutchName}`}
        </div>
      )}
    </div>
  )
}

function MatchResultBanner({ result, selfSrc }: { result: MatchResult; selfSrc?: number }) {
  const isForfeit    = result.forfeiterSrc != null
  const youForfeited = isForfeit && result.forfeiterSrc === selfSrc
  const youGotWO     = isForfeit && !youForfeited
  const youWonScore  = !isForfeit && result.winnerSrc != null && result.winnerSrc === selfSrc

  let title:    string
  let subtitle: string | null = null
  let color:    string

  if (youGotWO) {
    title    = 'VITÓRIA W.O.'
    subtitle = 'OPONENTE DESISTIU'
    color    = COLOR_ACCENT
  } else if (youWonScore) {
    title = 'VITÓRIA'
    color = COLOR_ACCENT
  } else if (youForfeited) {
    title    = 'DERROTA'
    subtitle = 'VOCÊ DESISTIU'
    color    = COLOR_DANGER
  } else {
    title = 'DERROTA'
    color = COLOR_DANGER
  }

  return (
    <div
      style={{
        position: 'absolute',
        inset: 0,
        background: 'rgba(0,0,0,0.55)',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 16,
      }}
    >
      <div
        style={{
          fontSize: 13,
          letterSpacing: '0.4em',
          fontWeight: 700,
          color,
        }}
      >
        {title}
      </div>
      {subtitle && (
        <div
          style={{
            fontSize: 11,
            letterSpacing: '0.3em',
            fontWeight: 600,
            color: COLOR_MUTED,
            marginTop: -8,
          }}
        >
          {subtitle}
        </div>
      )}
      <div
        style={{
          fontSize: 56,
          fontWeight: 900,
          letterSpacing: '0.05em',
          color: COLOR_LIGHT,
        }}
      >
        {result.winnerName || '—'}
      </div>
      {!isForfeit && (
        <div style={{ fontSize: 16, fontWeight: 600, color: COLOR_ACCENT, fontVariantNumeric: 'tabular-nums' }}>
          {result.winnerScore} PONTOS
        </div>
      )}
      <div
        style={{
          display: 'flex',
          flexDirection: 'column',
          gap: 4,
          minWidth: 280,
          padding: '12px 20px',
          background: COLOR_BG,
          borderLeft:  `3px solid ${COLOR_ACCENT_BORDER}`,
          borderRight: `3px solid ${COLOR_ACCENT_BORDER}`,
        }}
      >
        {result.scoreboard.map((p) => (
          <div key={p.src} style={{ display: 'flex', justifyContent: 'space-between', fontSize: 13 }}>
            <span style={{ fontWeight: p.src === selfSrc ? 700 : 500 }}>{p.name}</span>
            <span style={{ fontWeight: 700, color: COLOR_ACCENT, fontVariantNumeric: 'tabular-nums' }}>{p.score}</span>
          </div>
        ))}
      </div>
    </div>
  )
}
