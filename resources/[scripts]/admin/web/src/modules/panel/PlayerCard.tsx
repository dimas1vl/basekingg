import { useState } from 'react'
import {
  Ban,
  Eye,
  Home,
  LocateFixed,
  LogOut,
  Magnet,
  Settings2,
  Shirt,
  ShieldCheck,
  Snowflake,
} from 'lucide-react'
import { cn } from '@/lib/utils'
import type { PanelPlayer, PlayerRole } from '@/types/nui'

export interface PlayerActionPayload {
  action: string
  targetId: number
  reason?: string
  role?: PlayerRole
  field?: 'xp' | 'gems'
  value?: number
  itemId?: string
}

interface PlayerCardProps {
  player: PanelPlayer
  onAction: (payload: PlayerActionPayload) => void
  onBan: (player: PanelPlayer) => void
  onInventario: (player: PanelPlayer) => void
}

const ROLE_STYLE: Record<PlayerRole, string> = {
  admin: 'bg-primary/15 text-primary',
  spec: 'bg-[#e0a73a]/15 text-[#e0a73a]',
  user: 'bg-white/10 text-white/60',
}

function IconBtn({
  title,
  onClick,
  className,
  children,
}: {
  title: string
  onClick: () => void
  className?: string
  children: React.ReactNode
}) {
  return (
    <div className="group/tip relative">
      <button
        onClick={onClick}
        className={cn(
          'grid h-9 w-9 place-items-center rounded-md border border-white/10 bg-white/[0.03] text-white/70 transition-colors hover:border-primary/50 hover:text-primary',
          className,
        )}
      >
        {children}
      </button>

      {/* Styled hover tooltip explaining the action. Anchored to the right so it
          grows into the panel and never triggers a horizontal scrollbar. */}
      <span className="pointer-events-none absolute bottom-full right-0 z-30 mb-2 -translate-y-1 whitespace-nowrap rounded-md bg-[#0c0c0c] px-2.5 py-1.5 text-[1rem] font-medium text-[#f8efff] opacity-0 shadow-lg ring-1 ring-white/10 transition-all duration-150 group-hover/tip:translate-y-0 group-hover/tip:opacity-100">
        {title}
        <span className="absolute right-4 top-full border-[0.4rem] border-transparent border-t-[#0c0c0c]" />
      </span>
    </div>
  )
}

export default function PlayerCard({ player, onAction, onBan, onInventario }: PlayerCardProps) {
  const [managing, setManaging] = useState(false)
  const [role, setRole] = useState<PlayerRole>(player.role)
  const [xp, setXp] = useState(String(player.xp))
  const [gems, setGems] = useState(String(player.gems))

  const act = (action: string, extra?: Partial<PlayerActionPayload>) =>
    onAction({ action, targetId: player.userId, ...extra })

  return (
    <div className="rounded-lg border border-white/10 bg-white/[0.02]">
      <div className="flex items-center gap-4 px-4 py-3">
        <div className="grid h-11 w-11 shrink-0 place-items-center rounded-full bg-primary/15 text-[1.6rem] font-bold text-primary">
          {player.name.charAt(0).toUpperCase()}
        </div>

        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-2">
            <span className="truncate text-[1.4rem] font-semibold text-[#f8efff]">
              {player.name}
            </span>
            <span
              className={cn(
                'rounded px-2 py-0.5 text-[0.95rem] font-semibold uppercase',
                ROLE_STYLE[player.role],
              )}
            >
              {player.role}
            </span>
          </div>
          <div className="mt-0.5 flex flex-wrap items-center gap-x-3 gap-y-0.5 text-[1.1rem] text-white/45">
            <span>ID {player.userId}</span>
            <span>XP {player.xp}</span>
            <span>Gems {player.gems}</span>
            <span className="rounded bg-white/5 px-2 py-0.5 text-white/70">{player.mode}</span>
          </div>
        </div>

        <div className="flex shrink-0 items-center gap-1.5">
          <IconBtn title="Teleportar ate o jogador" onClick={() => act('tpto')}>
            <LocateFixed size={17} />
          </IconBtn>
          <IconBtn title="Puxar jogador ate voce" onClick={() => act('tptome')}>
            <Magnet size={17} />
          </IconBtn>
          <IconBtn title="Espectar jogador" onClick={() => act('spec')}>
            <Eye size={17} />
          </IconBtn>
          <IconBtn title="Congelar / descongelar" onClick={() => act('freeze')}>
            <Snowflake size={17} />
          </IconBtn>
          <IconBtn title="God mode (vida + colete)" onClick={() => act('god')}>
            <ShieldCheck size={17} />
          </IconBtn>
          <IconBtn title="Enviar para o lobby" onClick={() => act('setarlobby')}>
            <Home size={17} />
          </IconBtn>
          <IconBtn
            title="Expulsar do servidor"
            onClick={() => act('kick')}
            className="hover:border-[#e0a73a]/60 hover:text-[#e0a73a]"
          >
            <LogOut size={17} />
          </IconBtn>
          <IconBtn
            title="Skins / Inventarioos"
            onClick={() => onInventario(player)}
            className="hover:border-[#c084fc]/60 hover:text-[#c084fc]"
          >
            <Shirt size={17} />
          </IconBtn>
          <IconBtn
            title="Banir jogador"
            onClick={() => onBan(player)}
            className="hover:border-[#e0566b]/60 hover:text-[#e0566b]"
          >
            <Ban size={17} />
          </IconBtn>
          <IconBtn
            title="Gerenciar (cargo, XP, gems)"
            onClick={() => setManaging((v) => !v)}
            className={cn(managing && 'border-primary/50 text-primary')}
          >
            <Settings2 size={17} />
          </IconBtn>
        </div>
      </div>

      {managing && (
        <div className="flex flex-wrap items-end gap-4 border-t border-white/10 px-4 py-3">
          <div className="flex flex-col gap-1">
            <span className="text-[1rem] uppercase tracking-wider text-white/40">Cargo</span>
            <div className="flex items-center gap-2">
              <select
                value={role}
                onChange={(e) => setRole(e.target.value as PlayerRole)}
                className="rounded-md border border-white/10 bg-[#151515] px-3 py-2 text-[1.2rem] text-[#f8efff] outline-none"
              >
                <option value="user">user</option>
                <option value="admin">admin</option>
                <option value="spec">spec</option>
              </select>
              <button
                onClick={() => act('setRole', { role })}
                className="rounded-md bg-primary/15 px-3 py-2 text-[1.1rem] font-semibold text-primary hover:bg-primary/25"
              >
                Salvar
              </button>
            </div>
          </div>

          <div className="flex flex-col gap-1">
            <span className="text-[1rem] uppercase tracking-wider text-white/40">XP</span>
            <div className="flex items-center gap-2">
              <input
                type="number"
                min={0}
                value={xp}
                onChange={(e) => setXp(e.target.value)}
                className="w-28 rounded-md border border-white/10 bg-transparent px-3 py-2 text-[1.2rem] text-[#f8efff] outline-none focus:border-primary/50"
              />
              <button
                onClick={() => act('setStat', { field: 'xp', value: parseInt(xp) || 0 })}
                className="rounded-md bg-primary/15 px-3 py-2 text-[1.1rem] font-semibold text-primary hover:bg-primary/25"
              >
                Salvar
              </button>
            </div>
          </div>

          <div className="flex flex-col gap-1">
            <span className="text-[1rem] uppercase tracking-wider text-white/40">Gems</span>
            <div className="flex items-center gap-2">
              <input
                type="number"
                min={0}
                value={gems}
                onChange={(e) => setGems(e.target.value)}
                className="w-28 rounded-md border border-white/10 bg-transparent px-3 py-2 text-[1.2rem] text-[#f8efff] outline-none focus:border-primary/50"
              />
              <button
                onClick={() => act('setStat', { field: 'gems', value: parseInt(gems) || 0 })}
                className="rounded-md bg-primary/15 px-3 py-2 text-[1.1rem] font-semibold text-primary hover:bg-primary/25"
              >
                Salvar
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
