import ReactDOM from 'react-dom/client'
import App from './app'
import { VisibilityProvider } from './providers/Visibility'
import { debugData } from './utils/debugData'
import './styles/global.css'

debugData([{ event: 'visible', data: true }], 100)

debugData([
  { event: 'matchInfo', data: { variant: '1v2', selfSrc: 12, isInMatch: true } },
  { event: 'weapons', data: { slots: [
    { slot: 1, label: 'PISTOL',   weapon: 'WEAPON_PISTOL_MK2' },
    { slot: 2, label: 'SMG',      weapon: 'WEAPON_MICROSMG' },
    { slot: 3, label: 'RIFLE',    weapon: 'WEAPON_ASSAULTRIFLE' },
    { slot: 4, label: 'SNIPER',   weapon: 'WEAPON_SNIPERRIFLE' },
    { slot: 5, label: 'SHOTGUN',  weapon: 'WEAPON_PUMPSHOTGUN' },
    { slot: 6, label: 'CARBINE',  weapon: 'WEAPON_CARBINERIFLE' },
    { slot: 7, label: 'MARKSMAN', weapon: 'WEAPON_MARKSMANRIFLE' },
    { slot: 8, label: 'KNIFE',    weapon: 'WEAPON_KNIFE' },
  ], selected: 3 } },
  { event: 'roundInfo', data: { roundNumber: 3, mapName: 'GOLF', variant: '1v2', scoreLimit: 10, clutchSrc: 12, scoreboard: [
    { src: 12, name: 'MIRT0',   score: 5, alive: true },
    { src: 14, name: 'RACCO',   score: 2, alive: true },
    { src: 16, name: 'DIMAS1',  score: 1, alive: true },
  ] } },
  { event: 'scoreboard', data: [
    { src: 12, name: 'MIRT0',  score: 5, alive: true },
    { src: 14, name: 'RACCO',  score: 2, alive: true },
    { src: 16, name: 'DIMAS1', score: 1, alive: true },
  ] },
  { event: 'hud', data: { hp: 180, hpMax: 200, armor: 100, armorMax: 100, ammo: 29, maxAmmo: 200, weapon: 'WEAPON_ASSAULTRIFLE', frozen: false, freezeMs: 0 } },
  { event: 'zoneUpdate', data: { radius: 87, startRadius: 200, endRadius: 5, elapsedMs: 32000, shrinkMs: 60000 } },
], 400)

ReactDOM.createRoot(document.getElementById('root')!).render(
  <VisibilityProvider>
    <App />
  </VisibilityProvider>,
)
