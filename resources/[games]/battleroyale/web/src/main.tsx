import ReactDOM from 'react-dom/client'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { BrowserRouter } from 'react-router-dom'
import App from './app'
import { VisibilityProvider } from './providers/Visibility'
import { debugData } from './utils/debugData'
import './styles/global.css'

debugData([{ event: 'show', data: true }])

debugData(
  [
    {
      event: 'hud:update',
      data: {
        health: 100,
        armor: 100,
        ammo: 30,
        maxAmmo: 140,
        activeSlot: 1,
        slots: [{ ammo: 1 }, { ammo: null }, { ammo: 3 }, { ammo: 2 }, { ammo: null }],
        speed: 165,
        kills: 4,
      },
    },
    {
      event: 'hud:squad',
      data: [
        { slot: 1, name: 'Dimas1VL',      health: 100, armor: 100, alive: true,  speaking: false, badgeColor: '#cd6f3c' },
        { slot: 3, name: 'BlvRevolution', health: 47,  armor: 0,   alive: true,  speaking: true,  badgeColor: '#4972ca' },
        { slot: 4, name: 'M1rt',          health: 0,   armor: 0,   alive: false, speaking: false, badgeColor: '#bd4c4e' },
        { slot: 5, name: 'EdmFilho',      health: 79,  armor: 100, alive: true,  speaking: false, badgeColor: '#509850' },
      ],
    },
    { event: 'hud:phase',       data: { timer: '00:01', phase: 3, totalPhases: 12, progress: 0.46 } },
    { event: 'hud:meters',      data: { distance: 166, distanceLabel: 'MAR', vehicleSpeed: 134, altitude: 155, heading: 0 } },
    { event: 'hud:safezone',    data: { visible: true, title: 'SAFE ZONE', message: 'A PRÓXIMA ZONA FECHARÁ EM 30 SEGUNDOS' } },
    { event: 'hud:interaction', data: { visible: true, key: 'E', action: 'PEGAR MUNIÇÃO', detail: 'QUANTIDADE', detailValue: 'x30' } },
    { event: 'hud:action',      data: { visible: true, type: 'medkit', text: 'USANDO KIT MEDICO', cancelKey: 'F', progress: 0 } },
  ],
  750,
)

debugData([{ event: 'hud:killfeed', data: { killer: '[KZN] rACCOZr', victim: 'Flaash',       killerIsTeam: true,  victimIsTeam: false } }], 3000)
debugData([{ event: 'hud:killfeed', data: { killer: '[LLL] CORINGA', victim: '[KZN] rACCOZr', killerIsTeam: false, victimIsTeam: true  } }], 4500)
debugData([{ event: 'hud:update',   data: { health: 62, armor: 40, ammo: 18, maxAmmo: 140, activeSlot: 1, slots: [{ ammo: 1 }, { ammo: null }, { ammo: 3 }, { ammo: 2 }, { ammo: null }], speed: 0, kills: 5 } }], 5000)
debugData([{ event: 'hud:meters',   data: { distance: 100, distanceLabel: 'MAR', vehicleSpeed: 45, altitude: 8, heading: 45 } }], 15000)

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
