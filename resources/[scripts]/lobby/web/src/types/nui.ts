export type PlayerData = {
  id: string
  name: string
  avatar: string
  banner: string
  team: string
  coins: number
  points: number
  premium: number
  wins: number
  loss: number
  kills: number
  deaths: number
}

export type UserInfoPayload = {
  id?: number
  name?: string
  xp?: number
  gems?: number
  role?: string
  banner?: number
  premium?: number
  wins?: number
  loss?: number
  kills?: number
  deaths?: number
  badges?: unknown[]
}

export type Friend = {
  id: string
  name: string
  team: string
  avatar: string
  banner: string
  online: boolean
}

export type SquadMember = {
  id: string
  name: string
  avatar: string
  isLeader: boolean
}

export type NewsItem = {
  id: string
  image: string
  title: string
  date: string
  description: string
}

export type SelectedMode = {
  category: string
  submode: string
}

export type GameVariant = {
  id: string
  label: string
  target: string
}

export type GameSubType = {
  premium?: boolean
  inactive?: boolean
  variants?: GameVariant[]
}

export type GameModeServer = {
  new?: boolean
  sub_types?: Record<string, GameSubType>
}

export type GameModesPayload = Record<string, GameModeServer>

export type PendingRequest = {
  userId: number
  name: string
}

export type PendingRequests = {
  incoming: PendingRequest[]
  outgoing: PendingRequest[]
}

export type FriendNotification = {
  type: 'request_received' | 'request_accepted' | 'request_declined' | 'invite_declined'
  fromName: string
  fromUserId: number
}

export type SquadInvite = {
  fromUserId: number
  fromName: string
  fromAvatar: string
}

export type ShowPayload = {
  player: PlayerData
  friends: Friend[]
  squad: SquadMember[]
  news: NewsItem[]
  online: number
  selectedMode: SelectedMode
  gamemodes?: GameModesPayload
}
