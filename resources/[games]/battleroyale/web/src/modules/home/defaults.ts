import type {
  HudData,
  SquadMember,
  KillEntry,
  PhaseData,
  SafeZoneData,
  InteractionData,
  ActionData,
  MetersData,
  MatchAliveData,
} from '@/types/hud'

export const DEFAULT_HUD: HudData = {
  health: 0,
  armor: 0,
  ammo: 0,
  maxAmmo: 0,
  activeSlot: 0,
  slots: [false, false, false, false, false],
  speed: 0,
  kills: 0,
}

export const DEFAULT_SQUAD: SquadMember[] = []

export const DEFAULT_KILLFEED: KillEntry[] = []

export const DEFAULT_PHASE: PhaseData = { timer: '00:00', phase: 0, totalPhases: 0, progress: 0 }

export const DEFAULT_SAFEZONE: SafeZoneData = {
  visible: false,
  title: '',
  message: '',
}

export const DEFAULT_INTERACTION: InteractionData = {
  visible: false,
  key: '',
  action: '',
  detail: '',
  detailValue: '',
}

export const DEFAULT_ACTION: ActionData = {
  visible: false,
  type: null,
  text: '',
  cancelKey: '',
  progress: 0,
}

export const DEFAULT_MATCH_ALIVE: MatchAliveData = { players: 0, squads: 0 }

export const DEFAULT_METERS: MetersData = {
  visible: false,
  distance: 0,
  distanceLabel: '',
  vehicleSpeed: 0,
  altitude: 0,
  heading: 0,
}
