import { createContext, useContext, useState } from 'react'
import { useListener } from '@/hooks/listener'
import { debugData } from '@/utils/debugData'
import type {
  Friend,
  FriendNotification,
  GameModesPayload,
  NewsItem,
  PendingRequests,
  PlayerData,
  SelectedMode,
  ShowPayload,
  SquadInvite,
  SquadMember,
  UserInfoPayload,
} from '@/types/nui'

const AVATAR_URL = new URL('/avatar.png', import.meta.url).href
const BANNER_PERFIL_URL = new URL('/banner-perfil.png', import.meta.url).href
const BANNER_NEWS_URL = new URL('/banner-newslatter.png', import.meta.url).href

type LobbyState = {
  player: PlayerData | null
  friends: Friend[]
  squad: SquadMember[]
  news: NewsItem[]
  online: number
  selectedMode: SelectedMode
  gamemodes: GameModesPayload
  pendingRequests: PendingRequests
  squadInvites: SquadInvite[]
}

const DEFAULT_GAMEMODES: GameModesPayload = {
  'Treinamento': {
    sub_types: {
      'Drive-Bye': {},
      'Mata-Mata': {
        variants: [
          { id: 'fuzil',   label: 'FUZIL',   target: 'mata-mata-fuzil'   },
          { id: 'pistola', label: 'PISTOLA', target: 'mata-mata-pistola' },
        ],
      },
      'Rolamento com Bots + Tracking': {},
      'Laboratorio': {},
    },
  },
  'Battle Royale': {
    sub_types: {
      'Casual': {
        variants: [
          { id: 'solo', label: 'SOLO', target: 'casual' },
          { id: 'duo', label: 'DUO', target: 'casual' },
        ],
      },
      'Casual SQUAD': {},
      'Competitivo': {},
      'Classificatória': {},
      'Premium SQUAD': { premium: true },
    },
  },
  'Mini Games': {
    sub_types: {
      'Clutch': {
        variants: [
          { id: '1x2', label: '1X2', target: 'clutch-1x2' },
          { id: '2x4', label: '2X4', target: 'clutch-2x4' },
          { id: '3x5', label: '3X5', target: 'clutch-3x5' },
        ],
      },
      'Gang': {},
      'Prédio': {
        variants: [
          { id: '1x1', label: '1X1', target: 'predio-1x1' },
          { id: '2x2', label: '2X2', target: 'predio-2x2' },
          { id: '3x3', label: '3X3', target: 'predio-3x3' },
          { id: '4x4', label: '4X4', target: 'predio-4x4' },
          { id: '5x5', label: '5X5', target: 'predio-5x5' },
        ],
      },
      'Dominação': {},
    },
  },
  'End Game': { new: true, sub_types: { 'Casual': {} } },
}

const defaultState: LobbyState = {
  player: null,
  friends: [],
  squad: [],
  news: [],
  online: 0,
  selectedMode: { category: 'battle-royale', submode: 'casual' },
  gamemodes: DEFAULT_GAMEMODES,
  pendingRequests: { incoming: [], outgoing: [] },
  squadInvites: [],
}

debugData<ShowPayload>([{
  event: 'show',
  data: {
    player: {
      id: '1', name: 'AndreCota6', avatar: AVATAR_URL, banner: BANNER_PERFIL_URL,
      team: 'KINGG', coins: 15000, points: 48200, premium: 1,
      wins: 134, loss: 89, kills: 2041, deaths: 670,
    },
    friends: [
      { id: '1', name: 'Jogador001', team: 'KINGG', avatar: AVATAR_URL, banner: BANNER_PERFIL_URL, online: true },
      { id: '2', name: 'xSniper77',  team: 'RUSH',  avatar: AVATAR_URL, banner: BANNER_PERFIL_URL, online: true },
      { id: '3', name: 'DevNull',    team: '',       avatar: AVATAR_URL, banner: BANNER_PERFIL_URL, online: false },
    ],
    squad: [
      { id: '1', name: 'AndreCota6', avatar: AVATAR_URL, isLeader: true },
      { id: '2', name: 'Jogador001', avatar: AVATAR_URL, isLeader: false },
    ],
    news: [
      { id: '1', image: BANNER_NEWS_URL, title: 'Temporada 3 chegou!', date: '28/04/2026', description: 'Nova temporada com novos modos, skins e eventos exclusivos.' },
      { id: '2', image: BANNER_NEWS_URL, title: 'Patch 3.1 — Balanceamento', date: '25/04/2026', description: 'Ajustes de armas, correções de bugs e melhorias de desempenho.' },
    ],
    online: 1247,
    selectedMode: { category: 'battle-royale', submode: 'casual' },
    gamemodes: DEFAULT_GAMEMODES,
  },
}])

type LobbyContextValue = LobbyState & {
  setSelectedMode: (mode: SelectedMode) => void
  removeSquadInvite: (fromUserId: number) => void
}

const LobbyCtx = createContext<LobbyContextValue>({
  ...defaultState,
  setSelectedMode: () => {},
  removeSquadInvite: () => {},
})

export function LobbyProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<LobbyState>(defaultState)

  useListener<ShowPayload>('show', (payload) => {
    if (!payload?.player) return
    setState({
      player: payload.player,
      friends: payload.friends ?? [],
      squad: payload.squad ?? [],
      news: payload.news ?? [],
      online: payload.online ?? 0,
      selectedMode: payload.selectedMode ?? defaultState.selectedMode,
      gamemodes: payload.gamemodes ?? defaultState.gamemodes,
      pendingRequests: defaultState.pendingRequests,
      squadInvites: [],
    })
  })

  useListener<GameModesPayload>('updateGamemodes', (gamemodes) =>
    setState((p) => ({ ...p, gamemodes })),
  )

  useListener<{ coins: number }>('updateCoins', ({ coins }) =>
    setState((p) => ({ ...p, player: p.player ? { ...p.player, coins } : null })),
  )

  useListener<{ points: number }>('updatePoints', ({ points }) =>
    setState((p) => ({ ...p, player: p.player ? { ...p.player, points } : null })),
  )

  useListener<Friend[]>('updateFriends', (friends) => setState((p) => ({ ...p, friends })))

  useListener<SquadMember[]>('updateSquad', (squad) => setState((p) => ({ ...p, squad })))

  useListener<{ online: number }>('updateOnline', ({ online }) =>
    setState((p) => ({ ...p, online })),
  )

  useListener<NewsItem[]>('updateNews', (news) => setState((p) => ({ ...p, news })))

  useListener<PendingRequests>('updatePendingRequests', (pendingRequests) =>
    setState((p) => ({ ...p, pendingRequests })),
  )

  useListener<SquadInvite>('squadInvite', (invite) =>
    setState((p) => ({
      ...p,
      squadInvites: [...p.squadInvites, invite],
    })),
  )

  useListener<SelectedMode>('updateSelectedMode', (selectedMode) =>
    setState((p) => ({ ...p, selectedMode })),
  )

  useListener<UserInfoPayload>('setUserInfo', (info) =>
    setState((p) => ({
      ...p,
      player: {
        id: String(info.id ?? p.player?.id ?? ''),
        name: info.name ?? p.player?.name ?? '',
        avatar: p.player?.avatar ?? AVATAR_URL,
        banner: p.player?.banner ?? BANNER_PERFIL_URL,
        team: info.role ?? p.player?.team ?? '',
        coins: Number(info.gems ?? p.player?.coins ?? 0),
        points: Number(info.xp ?? p.player?.points ?? 0),
        premium: Number(info.premium ?? p.player?.premium ?? 0),
        wins: Number(info.wins ?? p.player?.wins ?? 0),
        loss: Number(info.loss ?? p.player?.loss ?? 0),
        kills: Number(info.kills ?? p.player?.kills ?? 0),
        deaths: Number(info.deaths ?? p.player?.deaths ?? 0),
      },
    })),
  )

  const setSelectedMode = (selectedMode: SelectedMode) =>
    setState((p) => ({ ...p, selectedMode }))

  const removeSquadInvite = (fromUserId: number) =>
    setState((p) => ({
      ...p,
      squadInvites: p.squadInvites.filter((i) => i.fromUserId !== fromUserId),
    }))

  return (
    <LobbyCtx.Provider value={{ ...state, setSelectedMode, removeSquadInvite }}>
      {children}
    </LobbyCtx.Provider>
  )
}

export const useLobby = () => useContext(LobbyCtx)
