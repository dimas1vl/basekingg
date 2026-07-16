import { useCallback, useEffect, useMemo, useState } from 'react'
import { CheckCircle2, RotateCcw, Shirt, Sparkles, X } from 'lucide-react'
import { useAdmin } from '@/providers/AdminProvider'
import { fetchData } from '@/utils/fetchData'
import { cn } from '@/lib/utils'
import type { InventarioRarity, PlayerInventarioEntry } from '@/types/nui'

const RARITY_STYLE: Record<InventarioRarity, string> = {
  common: 'bg-white/10 text-white/70 border-white/15',
  rare: 'bg-[#3b82f6]/15 text-[#60a5fa] border-[#3b82f6]/30',
  epic: 'bg-[#a855f7]/15 text-[#c084fc] border-[#a855f7]/30',
  legendary: 'bg-[#f59e0b]/15 text-[#fbbf24] border-[#f59e0b]/30',
  mythic: 'bg-[#ef4444]/15 text-[#fb7185] border-[#ef4444]/30',
}

const CATEGORY_LABEL: Record<string, string> = {
  clothes: 'Roupas',
  weapon_skin: 'Skins de arma',
  vehicle_skin: 'Skins de veiculo',
  parachute: 'Paraquedas',
}

const MOCK: PlayerInventarioEntry[] = []

export default function PlayerInventarioModal() {
  const { inventarioTarget, closePlayerInventario } = useAdmin()
  const [entries, setEntries] = useState<PlayerInventarioEntry[]>([])
  const [loading, setLoading] = useState(false)
  const [pending, setPending] = useState<string | null>(null)

  const target = inventarioTarget

  const load = useCallback(async () => {
    if (!target) return
    setLoading(true)
    const data = await fetchData<PlayerInventarioEntry[]>(
      'getPlayerInventario',
      target.userId,
      MOCK,
    )
    setEntries(Array.isArray(data) ? data : [])
    setLoading(false)
  }, [target])

  useEffect(() => {
    if (target) load()
    else setEntries([])
  }, [target, load])

  const grouped = useMemo(() => {
    const map = new Map<string, PlayerInventarioEntry[]>()
    for (const e of entries) {
      const arr = map.get(e.item.category) ?? []
      arr.push(e)
      map.set(e.item.category, arr)
    }
    return Array.from(map.entries()).sort(([a], [b]) => a.localeCompare(b))
  }, [entries])

  if (!target) return null

  const revoke = async (itemId: string) => {
    setPending(itemId)
    await fetchData('panelAction', {
      action: 'revokeInventario',
      targetId: target.userId,
      itemId,
    })
    setPending(null)
    // refresh after a short delay so server-side state settles
    setTimeout(load, 300)
  }

  return (
    <div className="flex h-[80vh] w-[68rem] flex-col overflow-hidden rounded-xl bg-modal shadow-2xl">
      {/* Header */}
      <div className="flex items-center justify-between border-b border-white/10 px-6 py-4">
        <div className="flex items-center gap-3">
          <Shirt size={22} className="text-[#c084fc]" />
          <div className="flex flex-col">
            <span className="text-[1.55rem] font-bold uppercase tracking-wide text-[#f8efff]">
              Inventarioos de {target.name}
            </span>
            <span className="text-[1.05rem] text-white/40">User ID {target.userId}</span>
          </div>
        </div>
        <button
          onClick={closePlayerInventario}
          className="text-white/50 transition-colors hover:text-white"
        >
          <X size={20} />
        </button>
      </div>

      {/* Body */}
      <div className="flex flex-col gap-5 overflow-y-auto overflow-x-hidden px-6 py-5">
        {entries.length === 0 ? (
          <p className="py-10 text-center text-[1.3rem] text-white/35">
            {loading ? 'Carregando inventario...' : 'Este jogador nao possui itens.'}
          </p>
        ) : (
          grouped.map(([category, items]) => (
            <section key={category} className="flex flex-col gap-2">
              <h3 className="text-[1.2rem] font-semibold uppercase tracking-wider text-white/55">
                {CATEGORY_LABEL[category] ?? category}{' '}
                <span className="text-white/30">({items.length})</span>
              </h3>
              <div className="grid grid-cols-1 gap-2.5 md:grid-cols-2">
                {items.map((e) => (
                  <div
                    key={e.item.id}
                    className={cn(
                      'rounded-lg border bg-white/[0.02] px-3.5 py-3 transition-colors',
                      e.equipped ? 'border-primary/40' : 'border-white/10',
                    )}
                  >
                    <div className="flex items-center gap-3">
                      <div className="grid h-11 w-11 shrink-0 place-items-center overflow-hidden rounded-md border border-white/10 bg-white/[0.03]">
                        {e.item.image ? (
                          <img
                            src={e.item.image}
                            alt={e.item.name}
                            className="h-full w-full object-cover"
                          />
                        ) : (
                          <Sparkles size={18} className="text-white/35" />
                        )}
                      </div>
                      <div className="min-w-0 flex-1">
                        <div className="flex items-center gap-2">
                          <p className="truncate text-[1.25rem] font-semibold text-[#f8efff]">
                            {e.item.name}
                          </p>
                          {e.equipped && (
                            <span className="flex items-center gap-1 rounded bg-primary/15 px-1.5 py-0.5 text-[0.95rem] font-semibold text-primary">
                              <CheckCircle2 size={11} /> EQUIPADO
                            </span>
                          )}
                        </div>
                        <div className="mt-0.5 flex flex-wrap items-center gap-x-2.5 gap-y-0.5 text-[1.05rem] text-white/45">
                          <span>{e.item.id}</span>
                          <span
                            className={cn(
                              'rounded border px-1.5 py-0 text-[0.95rem] font-semibold uppercase',
                              RARITY_STYLE[e.item.rarity],
                            )}
                          >
                            {e.item.rarity}
                          </span>
                          <span className="rounded bg-white/5 px-1.5 py-0">
                            origem: {e.source}
                          </span>
                          {e.sourceRef && (
                            <span className="text-white/35">ref: {e.sourceRef}</span>
                          )}
                          {e.acquiredAt && (
                            <span className="text-white/35">{e.acquiredAt}</span>
                          )}
                        </div>
                      </div>

                      <button
                        disabled={pending === e.item.id}
                        onClick={() => revoke(e.item.id)}
                        className={cn(
                          'flex shrink-0 items-center gap-1.5 rounded-md border border-[#e0566b]/40 bg-[#e0566b]/10 px-3 py-1.5 text-[1.1rem] font-semibold text-[#e0566b] transition-colors hover:bg-[#e0566b]/20',
                          pending === e.item.id && 'opacity-50',
                        )}
                      >
                        <RotateCcw size={14} />
                        {pending === e.item.id ? 'Revogando...' : 'Revogar'}
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </section>
          ))
        )}
      </div>
    </div>
  )
}
