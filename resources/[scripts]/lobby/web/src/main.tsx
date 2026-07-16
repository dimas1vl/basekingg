import ReactDOM from 'react-dom/client'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { BrowserRouter } from 'react-router-dom'
import App from './app'
import { VisibilityProvider } from './providers/Visibility'
import { debugData } from './utils/debugData'
import './styles/global.css'
import { ShowPayload } from './types/nui'

const AVATAR_URL = new URL('/avatar.png', import.meta.url).href
const BANNER_PERFIL_URL = new URL('/banner-perfil.png', import.meta.url).href
const BANNER_NEWS_URL = new URL('/banner-newslatter.png', import.meta.url).href

debugData<ShowPayload>([
  {
    event: 'show',
    data: {
      player: {
        id: '1',
        name: 'AndreCota6',
        avatar: AVATAR_URL,
        banner: BANNER_PERFIL_URL,
        team: 'KINGG',
        coins: 15000,
        points: 48200,
        premium: 1,
        wins: 134,
        loss: 89,
        kills: 2041,
        deaths: 670,
      },
      friends: [
        {
          id: '1',
          name: 'Jogador001',
          team: 'KINGG',
          avatar: AVATAR_URL,
          banner: BANNER_PERFIL_URL,
          online: true,
        },
        {
          id: '2',
          name: 'xSniper77',
          team: 'RUSH',
          avatar: AVATAR_URL,
          banner: BANNER_PERFIL_URL,
          online: true,
        },
        {
          id: '3',
          name: 'DevNull',
          team: '',
          avatar: AVATAR_URL,
          banner: BANNER_PERFIL_URL,
          online: false,
        },
      ],
      squad: [
        { id: '1', name: 'AndreCota6', avatar: AVATAR_URL, isLeader: true },
        { id: '2', name: 'Jogador001', avatar: AVATAR_URL, isLeader: false },
      ],
      news: [
        {
          id: '1',
          image: BANNER_NEWS_URL,
          title: 'Temporada 3 chegou!',
          date: '28/04/2026',
          description: 'Nova temporada com novos modos, skins e eventos exclusivos.',
        },
        {
          id: '2',
          image: BANNER_NEWS_URL,
          title: 'Patch 3.1 — Balanceamento',
          date: '25/04/2026',
          description: 'Ajustes de armas, correções de bugs e melhorias de desempenho.',
        },
      ],
      online: 1247,
      selectedMode: { category: 'battle-royale', submode: 'casual' },
    },
  },
])

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      refetchOnReconnect: false,
      refetchOnMount: false,
    },
  },
})

ReactDOM.createRoot(document.getElementById('root')!).render(
  <QueryClientProvider client={queryClient}>
    <BrowserRouter>
      <VisibilityProvider>
        <App />
      </VisibilityProvider>
    </BrowserRouter>
  </QueryClientProvider>,
)
