import { create } from 'zustand'

export type Rgb = [number, number, number]
export type FootstepMode = 'all' | 'noown' | 'noteam'
export type SfxKey = 'saque' | 'hit' | 'kill' | 'ping'

export interface SfxConf {
  effect: string
  volume: number
}

export interface DomSettings {
  hud: {
    hotbar: string[]
    announces: boolean
    progressBar: boolean
    dmgMarker: boolean
    dmgColor: Rgb
    killMarker: boolean
    killColor: Rgb
    hideHealth: boolean
    hideWeapon: boolean
    hideMinimap: boolean
    hideKillfeed: boolean
    hideCompass: boolean
    hideStats: boolean
    hideHints: boolean
    hideHotbar: boolean
    hideLevel: boolean
  }
  audio: {
    saque: SfxConf
    hit: SfxConf
    kill: SfxConf
    ping: SfxConf
    ambient: boolean
    footsteps: FootstepMode
  }
  game: {
    timeOverride: boolean
    hour: number
    minute: number
    weatherOverride: boolean
    weather: string
  }
}

export const DEFAULT_SETTINGS: DomSettings = {
  hud: {
    hotbar: ['fuzil', 'sub', 'pistola', 'faca'],
    announces: true,
    progressBar: true,
    dmgMarker: true,
    dmgColor: [255, 80, 80],
    killMarker: true,
    killColor: [255, 255, 255],
    hideHealth: false,
    hideWeapon: false,
    hideMinimap: false,
    hideKillfeed: false,
    hideCompass: false,
    hideStats: false,
    hideHints: false,
    hideHotbar: false,
    hideLevel: false,
  },
  audio: {
    saque: { effect: 'default', volume: 70 },
    hit: { effect: 'default', volume: 70 },
    kill: { effect: 'default', volume: 70 },
    ping: { effect: 'default', volume: 70 },
    ambient: false,
    footsteps: 'noteam',
  },
  game: {
    timeOverride: false,
    hour: 12,
    minute: 0,
    weatherOverride: false,
    weather: 'EXTRASUNNY',
  },
}

export const CATEGORY_LABELS: Record<string, string> = {
  fuzil: 'FUZIL',
  sub: 'SUB',
  pistola: 'PISTOLA',
  faca: 'FACA',
}

export const SFX_OPTIONS = ['default', 'op1', 'op2', 'op3', 'op4']

export const FOOTSTEP_OPTIONS: { value: FootstepMode; label: string }[] = [
  { value: 'noteam', label: 'Não ouvir equipe (incl. você)' },
  { value: 'noown', label: 'Não ouvir o seu' },
  { value: 'all', label: 'Ouvir todos' },
]

export const WEATHER_OPTIONS: { value: string; label: string }[] = [
  { value: 'EXTRASUNNY', label: 'Ensolarado+' },
  { value: 'CLEAR', label: 'Limpo' },
  { value: 'CLOUDS', label: 'Nublado' },
  { value: 'OVERCAST', label: 'Encoberto' },
  { value: 'SMOG', label: 'Neblina urbana' },
  { value: 'FOGGY', label: 'Névoa' },
  { value: 'RAIN', label: 'Chuva' },
  { value: 'THUNDER', label: 'Tempestade' },
  { value: 'CLEARING', label: 'Clareando' },
  { value: 'SNOW', label: 'Neve' },
  { value: 'BLIZZARD', label: 'Nevasca' },
  { value: 'SNOWLIGHT', label: 'Neve leve' },
  { value: 'XMAS', label: 'Natal' },
  { value: 'HALLOWEEN', label: 'Halloween' },
]

interface SettingsStore {
  settings: DomSettings
  setSettings: (s: DomSettings) => void
}

export const cloneSettings = (s: DomSettings): DomSettings => JSON.parse(JSON.stringify(s)) as DomSettings

function deepMergeDefaults(s: Partial<DomSettings> | undefined): DomSettings {
  const base = cloneSettings(DEFAULT_SETTINGS)
  if (!s) return base
  return {
    hud: { ...base.hud, ...(s.hud ?? {}) },
    audio: {
      ...base.audio,
      ...(s.audio ?? {}),
      saque: { ...base.audio.saque, ...(s.audio?.saque ?? {}) },
      hit: { ...base.audio.hit, ...(s.audio?.hit ?? {}) },
      kill: { ...base.audio.kill, ...(s.audio?.kill ?? {}) },
      ping: { ...base.audio.ping, ...(s.audio?.ping ?? {}) },
    },
    game: { ...base.game, ...(s.game ?? {}) },
  }
}

export const useSettings = create<SettingsStore>((set) => ({
  settings: DEFAULT_SETTINGS,
  setSettings: (s) => set({ settings: deepMergeDefaults(s) }),
}))
