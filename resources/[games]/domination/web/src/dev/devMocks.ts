import { isEnvBrowser } from '@/utils/misc'

// Mocks de desenvolvimento — só rodam no browser (yarn dev), nunca no jogo.
// Cada `send` despacha uma mensagem NUI CRUA, na mesma forma que o Lua envia
// (campos no topo, ou aninhados em `data`), para a pré-visualização refletir
// fielmente o protocolo real. Os menus (HUB/loja/etc.) NÃO abrem sozinhos;
// para testar, dispare no console, ex.:
//   window.dispatchEvent(new MessageEvent('message',{data:{action:'shop:visible',value:true}}))

type NuiMessage = { action: string; [key: string]: unknown }

// Timings (ms a partir do load). Em 2 fases porque o HUD (Home) só monta — e só
// registra seus listeners — depois que `show` liga a visibilidade. Por isso a
// visibilidade vai primeiro (SHOW_AT) e os dados depois (DATA_AT), quando o
// Home já está montado e ouvindo. Senão os dados chegariam antes do listener.
const SHOW_AT = 300
const DATA_AT = 900

function send(msg: NuiMessage, at: number) {
  setTimeout(() => window.dispatchEvent(new MessageEvent('message', { data: msg })), at)
}

// --- Fase 1: visibilidade (liga o HUD) ---
function visibility() {
  send({ action: 'show' }, SHOW_AT)
  send({ action: 'visible', value: true }, SHOW_AT)
}

// --- Fase 2: dados do HUD ---
function hud() {
  send({
    action: 'hud',
    data: {
      hp: 100, armor: 100,
      kills: 4, deaths: 4, streak: 4, players: 0,
      ammo: 30, maxAmmo: 140, weapon: 'WEAPON_CARBINERIFLE_MK2',
      inVehicle: false, speed: 0, heading: 155, progress: 0.5,
    },
  }, DATA_AT)
  send({
    action: 'weapons',
    data: {
      slots: [
        { slot: 1, label: 'CARBINE MK2', weapon: 'WEAPON_CARBINERIFLE_MK2' },
        { slot: 2, label: '' },
        { slot: 3, label: 'PISTOL MK2', weapon: 'WEAPON_PISTOL_MK2' },
        { slot: 4, label: 'KNIFE', weapon: 'WEAPON_KNIFE' },
      ],
      selected: 1,
    },
  }, DATA_AT)
  send({ action: 'notify', title: 'NOTIFICAÇÃO', description: 'ALGUMA NOTIFY', time: 99999 }, DATA_AT)
  send({ action: 'killFeed', selfSrc: 1, data: { killerSrc: 1, killerName: '[KZN] rACCOZr', victimSrc: 2, victimName: 'Flaash' } }, DATA_AT + 1500)
  send({ action: 'killFeed', selfSrc: 1, data: { killerSrc: 3, killerName: 'LIKIZÃO', victimSrc: 1, victimName: '[KZN] EDMFILHO' } }, DATA_AT + 3000)
}

// --- Fase 2: overlays da dominação ---
function domination() {
  send({ action: 'status', visible: true, kind: 'ghost', label: 'CENTRO' }, DATA_AT)
  send({ action: 'capture', visible: true, zone: 'CENTRO', team: 'KZN', members: 3, pct: 46, color: [254, 219, 78], contested: false }, DATA_AT)
  send({ action: 'dom:reward', xp: 40, money: 250 }, DATA_AT + 3500)
  send({ action: 'zonefeed', kind: 'start', team: 'CABRAS', zone: 'Motoclube Sul' }, DATA_AT + 1000)
  send({ action: 'zonefeed', kind: 'start', team: 'S7NC', zone: 'Ammu Porto' }, DATA_AT + 2000)
  send({ action: 'zonefeed', kind: 'captured', team: 'msc', zone: 'Estacionamento Praia' }, DATA_AT + 2800)
}

// --- Fase 2: estado (loja/nível/XP) ---
function state() {
  send({
    action: 'shop',
    data: {
      level: 7,
      gems: 125400,
      xpIntoLevel: 9000,
      xpPerLevel: 15000,
      categories: [
        {
          key: 'rifle',
          label: 'RIFLES',
          weapons: [
            { id: 'bullpup', label: 'BULLPUP RIFLE', icon: 'bullpup-rifle-icon', level: 1, price: 0, owned: true, equipped: true, locked: false },
            { id: 'advanced', label: 'ADVANCED RIFLE', icon: 'advanced-rifle-icon', level: 1, price: 100, owned: false, equipped: false, locked: false },
            { id: 'special_carbine', label: 'SPECIAL CARBINE', icon: 'special-carbine-icon', level: 20, price: 12000, owned: false, equipped: false, locked: true },
          ],
        },
        {
          key: 'smg',
          label: 'SMGS',
          weapons: [
            { id: 'micro_smg', label: 'MICRO SMG', icon: 'micro-smg-icon', level: 1, price: 0, owned: true, equipped: true, locked: false },
            { id: 'smg', label: 'SMG', icon: 'smg-icon', level: 15, price: 8000, owned: false, equipped: false, locked: false },
          ],
        },
      ],
    },
  }, DATA_AT)
}

// --- Fase 2: dados dos menus (não abrem sozinhos) ---
function menus() {
  send({
    action: 'vehicles',
    data: {
      level: 7,
      gems: 125400,
      imageBase: '',
      categories: [
        {
          key: 'sport',
          label: 'ESPORTIVOS',
          vehicles: [
            { id: 'kuruma', label: 'KURUMA', image: 'kuruma', level: 1, price: 0, requires: '', action: 'spawn', favorite: true },
            { id: 'elegy', label: 'ELEGY RH8', image: 'elegy', level: 10, price: 8000, requires: '', action: 'buy', favorite: false },
            { id: 'banshee', label: 'BANSHEE', image: 'banshee', level: 25, price: 0, requires: '', action: 'locked', favorite: false },
          ],
        },
      ],
    },
  }, DATA_AT)

  send({ action: 'spawns', data: { zones: [{ id: 'a', label: 'CENTRO' }, { id: 'b', label: 'AEROPORTO' }, { id: 'c', label: 'PRAIA' }], current: 'a' } }, DATA_AT)

  send({
    action: 'team',
    data: {
      hasTeam: true,
      id: 1,
      name: 'KZN ESPORTS',
      premium: true,
      discord: 'https://discord.gg/kzn',
      maxMembers: 10,
      memberCount: 3,
      onlineCount: 2,
      counts: { lider: 1, gerente: 1, sublider: 1 },
      caps: { gerente: 1, sublider: 2, recrutador: 3 },
      roleLabels: { lider: 'LÍDER', gerente: 'GERENTE', sublider: 'SUB LÍDER', recrutador: 'RECRUTADOR', membro: 'MEMBRO' },
      myRole: 'lider',
      perms: { invite: true, kick: true, promote: true, setDiscord: true },
      members: [
        { id: 1, name: 'Dimas1VL', role: 'lider', online: true, lastLogin: null },
        { id: 7, name: 'BlvRevolution', role: 'gerente', online: true, lastLogin: null },
        { id: 12, name: 'EdmFilho', role: 'membro', online: false, lastLogin: '2026-06-20T18:30:00' },
      ],
    },
  }, DATA_AT)
}

/** Carrega todos os mocks de dev (no-op fora de development/browser). */
export function startDevMocks() {
  if (import.meta.env.MODE !== 'development' || !isEnvBrowser()) return
  visibility()
  hud()
  domination()
  state()
  menus()
}
