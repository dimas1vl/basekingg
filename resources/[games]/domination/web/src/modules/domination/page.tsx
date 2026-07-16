import { useEffect, useRef, useState } from 'react'
import { useListener } from '@/hooks/listener'
import { useVisibility } from '@/providers/Visibility'
import { cn } from '@/lib/utils'
import { useSettings } from '@/store/settings'
import type { CapturePayload, RewardPayload, StatusPayload } from '@/types/domination'

const VULN_MS = 10000

const HINTS: Array<[string, string]> = [
  ['F1', 'ABRIR HUB'],
  ['F2', 'ARMAS'],
  ['F3', 'CARROS'],
  ['G', 'SPAWN VEÍCULO'],
  ['F5', 'SPAWNS'],
  ['F6', 'CONFIG'],
  ['F10', 'PRODUTOS'],
  ['TAB', 'RANKING'],
]

function rgbOf(c?: number[]): string {
  if (c && c.length >= 3) return `rgb(${c[0] | 0},${c[1] | 0},${c[2] | 0})`
  return '#fedb4e'
}

function clampPct(n?: number): number {
  return Math.max(0, Math.min(100, n || 0))
}

/* ===================== Barra de captura (dominação) ===================== */
function CaptureBar() {
  const [cap, setCap] = useState<CapturePayload>({ visible: false })
  const enabled = useSettings((s) => s.settings.hud.progressBar)

  useListener<CapturePayload>('capture', (d) => setCap(d ?? { visible: false }))

  const col = rgbOf(cap.color)
  const pct = clampPct(cap.pct)

  return (
    <div id="dom-capture" className={cn(enabled && cap.visible && 'shown', cap.contested && 'contested')}>
      <div className="dc-title">
        <span className="dc-verb">{cap.contested ? 'CONTESTANDO' : 'DOMINANDO'}</span>{' '}
        <span className="dc-zone">{cap.zone || ''}</span>
      </div>
      <div className="dc-row">
        <span className="dc-team" style={{ color: col }}>
          {cap.team || ''}
        </span>
        <span className="dc-members">
          <svg viewBox="0 0 24 24" fill="currentColor">
            <circle cx="12" cy="7" r="3.4" />
            <path d="M5 21c0-4.4 3-7 7-7s7 2.6 7 7z" />
          </svg>
          <span>{cap.members || 0}</span>
        </span>
      </div>
      <div className="dc-bar">
        <i style={{ width: `${pct}%`, background: col }} />
      </div>
      <div className="dc-pct">{pct}%</div>
    </div>
  )
}

/* ===================== Prompt de bandeira ===================== */
function FlagPrompt() {
  const [visible, setVisible] = useState(false)
  useListener<{ visible: boolean }>('flag:prompt', (d) => setVisible(!!d?.visible))

  return (
    <div id="dom-flagprompt" className={cn(visible && 'shown')}>
      <span className="fp-key">E</span>
      <span className="fp-txt">
        Pegar <b>Bandeira</b>
      </span>
    </div>
  )
}

/* ===================== Popups de recompensa ===================== */
interface Reward {
  id: number
  cls: 'money' | 'xp'
  value: number
}

let rewardSeq = 0

function RewardPopups() {
  const [rewards, setRewards] = useState<Reward[]>([])

  useListener<RewardPayload>('dom:reward', (d) => {
    if (!d) return
    const added: Reward[] = []
    if ((d.money || 0) > 0) added.push({ id: ++rewardSeq, cls: 'money', value: d.money! })
    if ((d.xp || 0) > 0) added.push({ id: ++rewardSeq, cls: 'xp', value: d.xp! })
    if (!added.length) return
    setRewards((prev) => [...prev, ...added])
    added.forEach((r) => {
      setTimeout(() => setRewards((prev) => prev.filter((x) => x.id !== r.id)), 2300)
    })
  })

  return (
    <div id="dom-reward">
      {rewards.map((r) => (
        <div key={r.id} className={`rw ${r.cls}`}>
          {r.cls === 'money' ? `+${r.value} $` : `+${r.value} XP`} <small>Dominação</small>
        </div>
      ))}
    </div>
  )
}

/* ===================== Feed de zonas (início/conclusão de dominação) ===================== */
interface ZoneFeedEntry {
  id: number
  kind: 'start' | 'captured'
  team: string
  zone: string
}

let zoneFeedSeq = 0

function ZoneFeed() {
  const [entries, setEntries] = useState<ZoneFeedEntry[]>([])
  const enabled = useSettings((s) => s.settings.hud.announces)

  useListener<{ kind?: string; team?: string; zone?: string }>('zonefeed', (d) => {
    if (!enabled || !d || !d.team || !d.zone) return
    const id = ++zoneFeedSeq
    const entry: ZoneFeedEntry = {
      id,
      kind: d.kind === 'captured' ? 'captured' : 'start',
      team: d.team,
      zone: d.zone,
    }
    setEntries((prev) => [...prev, entry].slice(-5))
    setTimeout(() => setEntries((prev) => prev.filter((e) => e.id !== id)), 8000)
  })

  if (!enabled) return null

  return (
    <div id="dom-zonefeed">
      {entries.map((e) => (
        <div className="zf-line" key={e.id}>
          <svg className="zf-icon" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
            <path d="M4 4h16a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H9l-5 4V5a1 1 0 0 1 1-1z" />
          </svg>
          <span className="zf-txt">
            O time <b className="zf-team">{e.team}</b>{' '}
            {e.kind === 'captured' ? 'dominou a zona' : 'iniciou a dominação da zona'}{' '}
            <b className="zf-zone">{e.zone}</b>
          </span>
        </div>
      ))}
    </div>
  )
}

/* ===================== Hints + chip de zona segura ===================== */
function HudExtras() {
  const { opened } = useVisibility()
  const hideHints = useSettings((s) => s.settings.hud.hideHints)
  const [status, setStatus] = useState<{ active: boolean; kind: 'ghost' | 'danger'; dangerEnd: number }>({
    active: false,
    kind: 'ghost',
    dangerEnd: 0,
  })
  const [, setTick] = useState(0)
  const tickRef = useRef(setTick)
  tickRef.current = setTick

  useListener<StatusPayload>('status', (d) => {
    const active = !!d?.visible
    const kind = (d?.kind as 'ghost' | 'danger') || 'ghost'
    const ms = typeof d?.ms === 'number' ? d.ms : VULN_MS
    setStatus({ active, kind, dangerEnd: active && kind === 'danger' ? Date.now() + ms : 0 })
  })

  // tick de 250ms só enquanto há contagem regressiva de vulnerabilidade
  useEffect(() => {
    if (!status.active || status.kind !== 'danger') return
    const id = window.setInterval(() => tickRef.current((n) => n + 1), 250)
    return () => window.clearInterval(id)
  }, [status.active, status.kind, status.dangerEnd])

  if (!opened) return null

  const danger = status.kind === 'danger'
  const inSafe = status.active && status.kind === 'ghost'
  const chipVisible = status.active && (danger ? Date.now() < status.dangerEnd : true)
  let chipText = 'VOCÊ ESTÁ NA ZONA SEGURA'
  if (danger) {
    const secs = Math.max(0, Math.ceil((status.dangerEnd - Date.now()) / 1000))
    chipText = `INVULNERÁVEL · ${secs}s`
  }

  return (
    <div id="dom-hud-extras">
      {chipVisible && (
        <div id="dom-sz-chip" className={danger ? 'danger' : 'ghost'}>
          {chipText}
        </div>
      )}
      <div id="dom-hints-row" className={inSafe && !hideHints ? 'shown' : 'hidden'}>
        {HINTS.map(([k, a]) => (
          <div className="hint" key={k}>
            <div className="hint-key">{k}</div>
            <span className="hint-lbl">{a}</span>
          </div>
        ))}
      </div>
    </div>
  )
}

/* ===================== Reviver aliado ===================== */
function ReviveOverlay() {
  const [st, setSt] = useState<{ visible: boolean; holding: boolean; pct: number }>({
    visible: false,
    holding: false,
    pct: 0,
  })

  useListener<{ visible?: boolean; holding?: boolean; pct?: number }>('revive', (d) => {
    if (!d || !d.visible) {
      setSt({ visible: false, holding: false, pct: 0 })
      return
    }
    setSt({ visible: true, holding: !!d.holding, pct: typeof d.pct === 'number' ? d.pct : 0 })
  })

  if (!st.visible) return null

  return (
    <div id="dom-revive">
      <div className="rv-row">
        <span className="rv-key">E</span>
        <span className="rv-txt">{st.holding ? 'REVIVENDO ALIADO...' : 'REVIVER ALIADO'}</span>
      </div>
      {st.holding && (
        <div className="rv-bar">
          <i style={{ width: `${Math.round(clampPct(st.pct * 100))}%` }} />
        </div>
      )}
    </div>
  )
}

export default function DominationOverlays() {
  return (
    <>
      <HudExtras />
      <CaptureBar />
      <FlagPrompt />
      <RewardPopups />
      <ZoneFeed />
      <ReviveOverlay />
    </>
  )
}
