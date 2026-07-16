// Payloads das mensagens NUI que alimentam o HUD (Home).
// Espelham exatamente o que o resource de dominação envia
// (client/cl_respawn.lua -> 'hud', cl_loadout.lua -> 'weapons'/'weapon'/'shop').

/** `hud` — status do jogador (enviado ~4x/s pela thread de HUD). */
export interface HudPayload {
  hp: number
  armor: number
  kills: number
  deaths: number
  streak: number
  players: number
  ammo?: number
  maxAmmo?: number
  weapon?: string
  inVehicle?: boolean
  speed?: number
  heading?: number // bússola (0-359) — precisa ser enviado pelo Lua
  progress?: number // barra inferior da rodada (0-1)
  level?: number
  xpInto?: number
  xpPer?: number
}

/** `weapons` — slots do loadout. */
export interface WeaponsPayload {
  slots: Array<{ slot: number; label: string; weapon?: string }>
  selected: number
}

/** `weapon` — troca de slot ativa. */
export interface WeaponPayload {
  selected: number
  weapon?: string
}

/** `killFeed` — uma kill (kill feed do canto superior direito). */
export interface KillFeedPayload {
  killerSrc?: number | null
  killerName?: string | null
  victimSrc: number
  victimName: string
}

/** `shop`/state — usado aqui só para nível/XP da barra inferior. */
export interface HudStatePayload {
  level?: number
  xpIntoLevel?: number
  xpPerLevel?: number
}

/** `notify` — caixa NOTIFICAÇÃO. */
export interface NotifyPayload {
  title?: string
  description?: string
  time?: number // segundos visível (default 5)
}

/** Estado de notificação no HUD. */
export interface NotifyState {
  visible: boolean
  title: string
  description: string
}
