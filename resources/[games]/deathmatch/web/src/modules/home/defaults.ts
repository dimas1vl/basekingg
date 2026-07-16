import type {
  HudData,
  SquadMember,
  KillEntry,
  PhaseData,
  NotifyData,
  InteractionData,
  ActionData,
  MetersData,
} from '@/types/hud'

export const DEFAULT_HUD: HudData = {
  health: 100,
  armor: 100,
  ammo: 30,
  maxAmmo: 140,
  activeSlot: 1,
  slots: [{ ammo: 1 }, { ammo: 1 }, { ammo: 1 }, { ammo: 1 }, { ammo: 1 }, { ammo: 1 }, { ammo: 1 }],
  speed: 0,
  inVehicle: false,
  kills: 0,
  deaths: 0,
  killStreak: 0,
  players: 1,
}

export const DEFAULT_SQUAD: SquadMember[] = [
  {
    slot: 1,
    name: 'Dimas1VL',
    health: 100,
    armor: 100,
    alive: true,
    speaking: false,
    badgeColor: '#cd6f3c',
  },
  {
    slot: 3,
    name: 'BlvRevolution',
    health: 47,
    armor: 0,
    alive: true,
    speaking: true,
    badgeColor: '#4972ca',
  },
  {
    slot: 4,
    name: 'M1rt',
    health: 0,
    armor: 0,
    alive: false,
    speaking: false,
    badgeColor: '#bd4c4e',
  },
  {
    slot: 5,
    name: 'EdmFilho',
    health: 79,
    armor: 100,
    alive: true,
    speaking: false,
    badgeColor: '#509850',
  },
]

export const DEFAULT_KILLFEED: KillEntry[] = [
  { id: 1, killer: '[KZN] rACCOZr', victim: 'Flaash', killerIsTeam: true, victimIsTeam: false },
  {
    id: 2,
    killer: '[KZN] Dimas1VL',
    victim: '[KZN] BlvRevolution',
    killerIsTeam: true,
    victimIsTeam: true,
  },
  { id: 3, killer: 'LIKIZÃO', victim: '[KZN] EDMFILHO', killerIsTeam: false, victimIsTeam: false },
  {
    id: 4,
    killer: '[LLL] CORINGA',
    victim: '[KZN] rACCOZr',
    killerIsTeam: false,
    victimIsTeam: true,
  },
  { id: 5, killer: '[T1] Faker', victim: 'M1rt', killerIsTeam: false, victimIsTeam: true },
  {
    id: 6,
    killer: '[ROC] Sparkingg',
    victim: 'EDMFILHO',
    killerIsTeam: false,
    victimIsTeam: false,
  },
]

export const DEFAULT_PHASE: PhaseData = { timer: '00:01', phase: 3, totalPhases: 12, progress: 0.46 }

export const DEFAULT_NOTIFY: NotifyData = {
  time: 5,
  title: 'SAFE ZONE',
  description: 'A PRÓXIMA ZONA FECHARÁ EM 30 SEGUNDOS',
}

export const DEFAULT_INTERACTION: InteractionData = {
  visible: true,
  key: 'E',
  action: 'PEGAR MUNIÇÃO',
  detail: 'QUANTIDADE',
  detailValue: 'x30',
}

export const DEFAULT_ACTION: ActionData = {
  visible: true,
  type: 'medkit',
  text: 'USANDO KIT MEDICO',
  cancelKey: 'F',
  progress: 0,
}

export const DEFAULT_METERS: MetersData = {
  distance: 190,
  distanceLabel: 'MAR',
  vehicleSpeed: 110,
  altitude: 155,
  heading: 0,
}
