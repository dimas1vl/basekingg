import circuitA from '@/components/icons/circuit_a.svg?url'
import circuitB from '@/components/icons/circuit_b.svg?url'

export const TEXTURE = new URL('/card-switchmode.png', import.meta.url).href
export const CIRCUIT_A = circuitA
export const CIRCUIT_B = circuitB

export type ModeData = {
  id: string
  label: string
  color?: string
  hoverColor?: string
  overlayOpacity?: number
  circuit?: string
  hoverCircuit?: string
  hoverCircuitWhite?: boolean
  rotation: number
  selectedBorder?: string
  badge?: string
  video?: string
}

export function normalizeModeId(name: string): string {
  return name
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/\s+/g, '-')
    .replace(/[^a-z0-9-]/g, '')
}

const MODE_VISUALS: Record<string, Partial<ModeData>> = {
  'treinamento':  { rotation: 0.61,  hoverCircuit: CIRCUIT_B },
  'battle-royale':{ rotation: -2.36, hoverCircuit: CIRCUIT_B },
  'mini-games':   { rotation: -0.08, hoverCircuit: CIRCUIT_B },
  'end-game':     { rotation: 1.12,  hoverCircuit: CIRCUIT_B, hoverCircuitWhite: true, color: '#fedb4e', hoverColor: '#f8efff', overlayOpacity: 0.45, selectedBorder: '#fedb4e' },
}

const DEFAULT_VISUAL: Partial<ModeData> = { rotation: 0.5, hoverCircuit: CIRCUIT_B }

export function buildModeData(name: string, isNew?: boolean): ModeData {
  const id = normalizeModeId(name)
  const visual = MODE_VISUALS[id] ?? DEFAULT_VISUAL
  return {
    id,
    label: name.toUpperCase(),
    badge: isNew ? 'NOVIDADE' : undefined,
    rotation: DEFAULT_VISUAL.rotation ?? 0,
    ...visual,
  }
}

// Static fallback used when no server data is available
export const MODES: ModeData[] = [
  { id: 'treinamento',  label: 'TREINAMENTO',  hoverCircuit: CIRCUIT_B, rotation: 0.61  },
  { id: 'battle-royale',label: 'BATTLE ROYALE', hoverCircuit: CIRCUIT_B, rotation: -2.36 },
  { id: 'mini-games',   label: 'MINI GAMES',    hoverCircuit: CIRCUIT_B, rotation: -0.08 },
  { id: 'end-game',     label: 'END GAME',      hoverCircuit: CIRCUIT_B, hoverCircuitWhite: true, rotation: 1.12, color: '#fedb4e', hoverColor: '#f8efff', overlayOpacity: 0.45, selectedBorder: '#fedb4e', badge: 'NOVIDADE' },
]
