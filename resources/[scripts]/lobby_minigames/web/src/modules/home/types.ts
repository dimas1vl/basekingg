export type Room = {
  id: string
  owner: string
  map: string
  players: number
  maxPlayers: number
  isPrivate: boolean
}

export type GameMode = {
  id: string
  name: string
  icon: 'balaclava' | 'building'
  openRooms: number | null
}

export type GameModeCount = {
  id: string
  openRooms: number | null
}

export type CreateRoomData = {
  map: string
  maxPlayers: number
  isPrivate: boolean
  password?: string
}

export type PanelMode = 'view' | 'create' | null
export type Screen = 'gamemode' | 'rooms'
