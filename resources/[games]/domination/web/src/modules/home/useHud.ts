import { useRef, useState } from 'react'
import { useListener } from '@/hooks/listener'
import type { HudData, KillEntry } from '@/types/hud'
import { DEFAULT_HUD } from './defaults'
import type {
  HudPayload,
  WeaponsPayload,
  WeaponPayload,
  KillFeedPayload,
  HudStatePayload,
  NotifyPayload,
  NotifyState,
} from './types'

const EMPTY_NOTIFY: NotifyState = { visible: false, title: '', description: '' }

/**
 * Concentra todo o estado e os listeners NUI do HUD num único lugar.
 * A página (`page.tsx`) só consome o objeto retornado e monta o layout.
 */
export function useHud() {
  const [hud, setHud] = useState<HudData>(DEFAULT_HUD)
  const [killFeed, setKillFeed] = useState<KillEntry[]>([])
  const [heading, setHeading] = useState(0)
  const [level, setLevel] = useState(1)
  const [xpInto, setXpInto] = useState(0)
  const [xpPer, setXpPer] = useState(1)
  const [notify, setNotify] = useState<NotifyState>(EMPTY_NOTIFY)
  const [reloading, setReloading] = useState(false)
  const [progress, setProgress] = useState(0)

  const killSeq = useRef(0)

  // status do jogador (vida, munição, kills, velocidade, heading, progresso da rodada)
  useListener<{ data: HudPayload }>('hud', ({ data }) => {
    if (!data) return
    if (typeof data.heading === 'number') setHeading(data.heading)
    if (typeof data.progress === 'number') setProgress(data.progress)
    if (typeof data.level === 'number') setLevel(data.level)
    if (typeof data.xpInto === 'number') setXpInto(data.xpInto)
    if (typeof data.xpPer === 'number') setXpPer(data.xpPer)
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

  useListener<{ data: { heading?: number } }>('hud:meters', ({ data }) => {
    if (data && typeof data.heading === 'number') setHeading(data.heading)
  })

  // slots do loadout
  useListener<{ data: WeaponsPayload }>('weapons', ({ data }) => {
    if (!data) return
    const slots = (data.slots ?? []).map((s) => ({ ammo: 1 as number | null, weapon: s.weapon, label: s.label }))
    setHud((prev) => ({
      ...prev,
      slots: slots.length > 0 ? slots : prev.slots,
      activeSlot: data.selected ?? prev.activeSlot,
      activeWeapon: slots[(data.selected ?? 1) - 1]?.weapon ?? prev.activeWeapon,
    }))
  })

  // troca de arma/slot
  useListener<WeaponPayload>('weapon', ({ selected, weapon }) => {
    setHud((prev) => ({
      ...prev,
      activeSlot: selected ?? prev.activeSlot,
      activeWeapon: weapon ?? prev.slots[(selected ?? 1) - 1]?.weapon ?? prev.activeWeapon,
    }))
  })

  // nível/XP (vêm do estado da loja — Dom.state)
  useListener<{ data: HudStatePayload }>('shop', ({ data }) => {
    if (!data) return
    if (typeof data.level === 'number') setLevel(data.level)
    if (typeof data.xpIntoLevel === 'number') setXpInto(data.xpIntoLevel)
    if (typeof data.xpPerLevel === 'number') setXpPer(data.xpPerLevel)
  })

  // kill feed
  useListener<{ data: KillFeedPayload; selfSrc?: number }>('killFeed', ({ data, selfSrc }) => {
    if (!data) return
    killSeq.current += 1
    const id = killSeq.current
    const entry: KillEntry = {
      id,
      killer: data.killerName ?? 'Desconhecido',
      victim: data.victimName ?? 'Player',
      killerIsTeam: data.killerSrc != null && data.killerSrc === selfSrc,
      victimIsTeam: data.victimSrc === selfSrc,
    }
    setKillFeed((prev) => [entry, ...prev].slice(0, 6))
    setTimeout(() => setKillFeed((prev) => prev.filter((k) => k.id !== id)), 8000)
  })

  // notificação no HUD
  useListener<NotifyPayload>('notify', (d) => {
    if (!d) return
    setNotify({ visible: true, title: d.title || '', description: d.description || '' })
    const ms = (typeof d.time === 'number' ? d.time : 5) * 1000
    setTimeout(() => setNotify((n) => ({ ...n, visible: false })), ms)
  })

  // indicador de recarga
  useListener<{ visible: boolean }>('reload', ({ visible }) => setReloading(!!visible))

  return { hud, killFeed, heading, level, xpInto, xpPer, notify, reloading, progress }
}
