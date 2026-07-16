import { CalendarClock, RotateCcw, ShieldOff, User } from 'lucide-react'
import type { PanelBan } from '@/types/nui'

interface BanCardProps {
  ban: PanelBan
  onUnban: (userId: number) => void
}

export default function BanCard({ ban, onUnban }: BanCardProps) {
  return (
    <div className="rounded-lg border border-white/10 bg-white/[0.02] px-4 py-3">
      <div className="flex items-center gap-4">
        <div className="grid h-11 w-11 shrink-0 place-items-center rounded-full bg-[#e0566b]/15 text-[#e0566b]">
          <ShieldOff size={20} />
        </div>

        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-2">
            <span className="truncate text-[1.4rem] font-semibold text-[#f8efff]">{ban.name}</span>
            <span className="rounded bg-white/10 px-2 py-0.5 text-[1rem] text-white/55">
              ID {ban.userId}
            </span>
            {ban.permanent && (
              <span className="rounded bg-[#e0566b]/15 px-2 py-0.5 text-[1rem] font-semibold text-[#e0566b]">
                PERMANENTE
              </span>
            )}
          </div>
          <div className="mt-1 flex flex-wrap items-center gap-x-4 gap-y-0.5 text-[1.1rem] text-white/50">
            <span className="text-white/70">Motivo: {ban.reason}</span>
            <span className="flex items-center gap-1.5">
              <User size={13} /> {ban.staffName}
            </span>
            <span className="flex items-center gap-1.5">
              <CalendarClock size={13} /> {ban.createdAt}
            </span>
            <span className="text-white/40">Expira: {ban.expiresAt}</span>
          </div>
        </div>

        <button
          onClick={() => onUnban(ban.userId)}
          className="flex shrink-0 items-center gap-2 rounded-md bg-primary/15 px-4 py-2.5 text-[1.2rem] font-semibold text-primary transition-colors hover:bg-primary/25"
        >
          <RotateCcw size={16} />
          Desbanir
        </button>
      </div>
    </div>
  )
}
