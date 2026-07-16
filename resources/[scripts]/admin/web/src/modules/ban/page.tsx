import { useState } from 'react'
import { Ban as BanIcon, X } from 'lucide-react'
import { useAdmin } from '@/providers/AdminProvider'
import { fetchData } from '@/utils/fetchData'
import { cn } from '@/lib/utils'

const PRESETS = [
  { label: '1 dia', days: 1 },
  { label: '3 dias', days: 3 },
  { label: '7 dias', days: 7 },
  { label: '30 dias', days: 30 },
  { label: 'Permanente', days: 0 },
]

export default function Ban() {
  const { banTarget, closeBan } = useAdmin()
  const [days, setDays] = useState(0)
  const [reason, setReason] = useState('')

  if (!banTarget) return null

  const confirm = () => {
    fetchData('submitBan', {
      targetUserId: banTarget.targetUserId,
      days,
      reason: reason.trim() || 'Sem motivo',
    })
    closeBan()
  }

  return (
    <div className="w-[42rem] overflow-hidden rounded-lg bg-modal shadow-2xl">
      <div className="flex items-center justify-between border-b border-white/10 px-6 py-4">
        <div className="flex items-center gap-2.5">
          <BanIcon size={20} className="text-[#e0566b]" />
          <span className="text-[1.5rem] font-semibold uppercase tracking-wide text-[#f8efff]">
            Banir jogador
          </span>
        </div>
        <button onClick={closeBan} className="text-white/50 transition-colors hover:text-white">
          <X size={20} />
        </button>
      </div>

      <div className="flex flex-col gap-5 p-6">
        <div className="rounded-md border border-white/10 bg-white/[0.03] px-4 py-3">
          <span className="text-[1.1rem] uppercase tracking-wider text-white/40">Alvo</span>
          <p className="text-[1.4rem] font-medium text-[#f8efff]">
            {banTarget.targetName}{' '}
            <span className="text-white/40">
              (user {banTarget.targetUserId} ·{' '}
              {banTarget.targetSrc > 0 ? `online id ${banTarget.targetSrc}` : 'offline'})
            </span>
          </p>
        </div>

        <div className="flex flex-col gap-2">
          <span className="text-[1.1rem] uppercase tracking-wider text-white/40">Duracao</span>
          <div className="flex flex-wrap gap-2">
            {PRESETS.map((preset) => (
              <button
                key={preset.days}
                onClick={() => setDays(preset.days)}
                className={cn(
                  'rounded-md border px-4 py-2 text-[1.2rem] font-medium transition-colors',
                  days === preset.days
                    ? 'border-primary bg-primary/15 text-primary'
                    : 'border-white/10 bg-white/[0.03] text-white/60 hover:border-white/30',
                )}
              >
                {preset.label}
              </button>
            ))}
          </div>
          <input
            type="number"
            min={0}
            value={days}
            onChange={(e) => setDays(Math.max(0, parseInt(e.target.value) || 0))}
            placeholder="Dias (0 = permanente)"
            className="mt-1 w-full rounded-md border border-white/10 bg-transparent px-4 py-2.5 text-[1.2rem] text-[#f8efff] outline-none focus:border-primary/50"
          />
        </div>

        <div className="flex flex-col gap-2">
          <span className="text-[1.1rem] uppercase tracking-wider text-white/40">Motivo</span>
          <textarea
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            rows={3}
            maxLength={255}
            placeholder="Descreva o motivo do banimento..."
            className="w-full resize-none rounded-md border border-white/10 bg-transparent px-4 py-2.5 text-[1.2rem] text-[#f8efff] outline-none focus:border-primary/50"
          />
        </div>

        <div className="flex justify-end gap-3">
          <button
            onClick={closeBan}
            className="rounded-md border border-white/10 px-5 py-2.5 text-[1.2rem] font-medium text-white/60 transition-colors hover:bg-white/5"
          >
            Cancelar
          </button>
          <button
            onClick={confirm}
            className="rounded-md bg-[#e0566b] px-5 py-2.5 text-[1.2rem] font-semibold text-white transition-opacity hover:opacity-90"
          >
            Confirmar ban
          </button>
        </div>
      </div>
    </div>
  )
}
