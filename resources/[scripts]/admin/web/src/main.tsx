import ReactDOM from 'react-dom/client'
import App from './app'
import { AdminProvider } from './providers/AdminProvider'
import { debugData } from './utils/debugData'
import './styles/global.css'

// Local browser preview helpers (only run with `npm run dev`).
debugData([
  { event: 'notify', data: { type: 'success', message: 'Comando executado com sucesso.', duration: 5 } },
])
debugData([{ event: 'openPanel' }], 1000)
debugData(
  [{ event: 'specStart', data: { name: 'Joao', userId: 7 } }],
  1500,
)
debugData(
  [{ event: 'specUpdate', data: { name: 'Joao', health: 160, maxHealth: 200, armor: 75 } }],
  1800,
)

ReactDOM.createRoot(document.getElementById('root')!).render(
  <AdminProvider>
    <App />
  </AdminProvider>,
)
