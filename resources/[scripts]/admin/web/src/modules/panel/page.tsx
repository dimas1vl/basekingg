import { useCallback, useEffect, useMemo, useState } from 'react'
import { RefreshCw, Search, ShieldAlert, Sparkles, Users, X } from 'lucide-react'
import { useAdmin } from '@/providers/AdminProvider'
import { fetchData } from '@/utils/fetchData'
import { cn } from '@/lib/utils'
import type {
  InventarioItem,
  InventarioFilters,
  PanelBan,
  PanelPlayer,
} from '@/types/nui'
import PlayerCard, { type PlayerActionPayload } from './PlayerCard'
import BanCard from './BanCard'
import InventarioTab from './InventarioTab'

type Tab = 'online' | 'bans' | 'lobby_inventory'

const MOCK_PLAYERS: PanelPlayer[] = [
  { src: 1, userId: 1, name: 'Mirtin', role: 'admin', xp: 5400, gems: 120, premium: 1, mode: 'Lobby' },
  { src: 2, userId: 7, name: 'Joao', role: 'user', xp: 320, gems: 0, premium: 0, mode: 'casual / deathmatch' },
  { src: 3, userId: 12, name: 'Maria', role: 'spec', xp: 90, gems: 5, premium: 0, mode: 'Em partida' },
]

const MOCK_BANS: PanelBan[] = [
  {
    userId: 9,
    name: 'Trapaceiro',
    reason: 'Uso de cheats',
    staffId: 1,
    staffName: 'Mirtin',
    createdAt: '23/05/2026 14:30',
    expiresAt: 'Permanente',
    permanent: true,
  },
]

const MOCK_INVENTARIO: InventarioItem[] = [
  {
    id: 'tops_red_hoodie_01',
    name: 'Hoodie Vermelho',
    category: 'clothes',
    subcategory: 'tops',
    rarity: 'common',
    purchasable: true,
    price: 100,
    metadata: { kind: 'component', slot_id: 11, drawable: 5, texture: 0 },
  },
  {
    id: 'pistol_skin_gold',
    name: 'Pistola Dourada',
    category: 'weapon_skin',
    rarity: 'legendary',
    purchasable: false,
    metadata: { weapon_hash: 'WEAPON_PISTOL', tint: 1 },
  },
]

export default function Panel() {
  const { close, openBan, openPlayerInventario } = useAdmin()
  const [tab, setTab] = useState<Tab>('online')
  const [players, setPlayers] = useState<PanelPlayer[]>([])
  const [bans, setBans] = useState<PanelBan[]>([])
  const [catalog, setCatalog] = useState<InventarioItem[]>([])
  const [loading, setLoading] = useState(false)
  const [search, setSearch] = useState('')
  const [inventarioFilters, setInventarioFilters] = useState<InventarioFilters>({})

  const loadPlayers = useCallback(async () => {
    setLoading(true)
    const data = await fetchData<PanelPlayer[]>('getPlayers', undefined, MOCK_PLAYERS)
    setPlayers(Array.isArray(data) ? data : [])
    setLoading(false)
  }, [])

  const loadBans = useCallback(async () => {
    setLoading(true)
    const data = await fetchData<PanelBan[]>('getBans', undefined, MOCK_BANS)
    setBans(Array.isArray(data) ? data : [])
    setLoading(false)
  }, [])

  const loadCatalog = useCallback(
    async (filters: InventarioFilters) => {
      setLoading(true)
      const data = await fetchData<InventarioItem[]>(
        'getInventarioCatalog',
        filters,
        MOCK_INVENTARIO,
      )
      setCatalog(Array.isArray(data) ? data : [])
      setLoading(false)
    },
    [],
  )

  const refresh = useCallback(() => {
    if (tab === 'online') loadPlayers()
    else if (tab === 'bans') loadBans()
    else loadCatalog(inventarioFilters)
  }, [tab, loadPlayers, loadBans, loadCatalog, inventarioFilters])

  useEffect(() => {
    refresh()
  }, [refresh])

  // Keep the online list reasonably fresh.
  useEffect(() => {
    if (tab !== 'online') return
    const id = setInterval(loadPlayers, 5000)
    return () => clearInterval(id)
  }, [tab, loadPlayers])

  const handleAction = useCallback(
    (payload: PlayerActionPayload) => {
      fetchData('panelAction', payload)
      // tp/spec change the admin's own view, so close the panel.
      if (payload.action === 'tpto' || payload.action === 'spec') {
        close()
      } else if (['kick', 'unban', 'setRole', 'setStat'].includes(payload.action)) {
        setTimeout(refresh, 500)
      }
    },
    [close, refresh],
  )

  const handleGrant = useCallback((targetUserId: number, itemId: string) => {
    fetchData('panelAction', {
      action: 'grantInventario',
      targetId: targetUserId,
      itemId,
    })
  }, [])

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase()
    if (!q) return players
    return players.filter(
      (p) => p.name.toLowerCase().includes(q) || String(p.userId).includes(q),
    )
  }, [players, search])

  return (
    <div className="flex h-[80vh] w-[78rem] flex-col overflow-hidden rounded-xl bg-modal shadow-2xl">
      {/* Header */}
      <div className="flex items-center justify-between border-b border-white/10 px-7 py-5">
        <div className="flex items-center gap-3">
          <ShieldAlert size={24} className="text-primary" />
          <span className="text-[1.8rem] font-bold uppercase tracking-wide text-[#f8efff]">
            Painel Admin
          </span>
        </div>
        <button onClick={close} className="text-white/50 transition-colors hover:text-white">
          <X size={22} />
        </button>
      </div>

      {/* Tabs + controls */}
      <div className="flex items-center gap-3 border-b border-white/10 px-7 py-3">
        <button
          onClick={() => setTab('online')}
          className={cn(
            'flex items-center gap-2 rounded-md px-4 py-2 text-[1.3rem] font-medium transition-colors',
            tab === 'online' ? 'bg-primary/15 text-primary' : 'text-white/55 hover:text-white',
          )}
        >
          <Users size={18} />
          Jogadores ({players.length})
        </button>
        <button
          onClick={() => setTab('bans')}
          className={cn(
            'flex items-center gap-2 rounded-md px-4 py-2 text-[1.3rem] font-medium transition-colors',
            tab === 'bans' ? 'bg-primary/15 text-primary' : 'text-white/55 hover:text-white',
          )}
        >
          <ShieldAlert size={18} />
          Banidos ({bans.length})
        </button>
        <button
          onClick={() => setTab('lobby_inventory')}
          className={cn(
            'flex items-center gap-2 rounded-md px-4 py-2 text-[1.3rem] font-medium transition-colors',
            tab === 'lobby_inventory'
              ? 'bg-primary/15 text-primary'
              : 'text-white/55 hover:text-white',
          )}
        >
          <Sparkles size={18} />
          Inventarioos ({catalog.length})
        </button>

        <div className="ml-auto flex items-center gap-2">
          {tab === 'online' && (
            <div className="flex items-center gap-2 rounded-md border border-white/10 bg-white/[0.03] px-3 py-2">
              <Search size={15} className="text-white/40" />
              <input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Buscar nome ou ID..."
                className="w-44 bg-transparent text-[1.2rem] text-[#f8efff] outline-none placeholder:text-white/30"
              />
            </div>
          )}
          <button
            onClick={refresh}
            title="Atualizar"
            className="grid h-10 w-10 place-items-center rounded-md border border-white/10 bg-white/[0.03] text-white/60 transition-colors hover:border-primary/50 hover:text-primary"
          >
            <RefreshCw size={17} className={cn(loading && 'animate-spin')} />
          </button>
        </div>
      </div>

      {/* Body */}
      <div className="flex flex-col gap-2.5 overflow-y-auto overflow-x-hidden px-7 py-5">
        {tab === 'online' ? (
          filtered.length === 0 ? (
            <p className="py-10 text-center text-[1.3rem] text-white/35">
              {loading ? 'Carregando...' : 'Nenhum jogador online.'}
            </p>
          ) : (
            filtered.map((p) => (
              <PlayerCard
                key={p.userId}
                player={p}
                onAction={handleAction}
                onBan={(pl) =>
                  openBan({ targetSrc: pl.src, targetUserId: pl.userId, targetName: pl.name })
                }
                onInventario={(pl) =>
                  openPlayerInventario({ userId: pl.userId, name: pl.name })
                }
              />
            ))
          )
        ) : tab === 'bans' ? (
          bans.length === 0 ? (
            <p className="py-10 text-center text-[1.3rem] text-white/35">
              {loading ? 'Carregando...' : 'Nenhum jogador banido.'}
            </p>
          ) : (
            bans.map((b) => (
              <BanCard
                key={b.userId}
                ban={b}
                onUnban={(userId) => handleAction({ action: 'unban', targetId: userId })}
              />
            ))
          )
        ) : (
          <InventarioTab
            catalog={catalog}
            loading={loading}
            filters={inventarioFilters}
            onFiltersChange={setInventarioFilters}
            onGrant={handleGrant}
          />
        )}
      </div>
    </div>
  )
}
