import { useState } from 'react'
import { Eye, Heart, Shield } from 'lucide-react'
import { useListener } from '@/hooks/listener'
import type { SpecInfo, SpecUpdate } from '@/types/nui'

interface SpecState extends SpecUpdate {
  userId?: number
}

function Bar({ value, max, color }: { value: number; max: number; color: string }) {
  const pct = Math.max(0, Math.min(100, max > 0 ? (value / max) * 100 : 0))
  return (
    <div className="h-2 w-full overflow-hidden rounded-full bg-white/10">
      <div
        className="h-full rounded-full transition-[width] duration-200"
        style={{ width: `${pct}%`, background: color }}
      />
    </div>
  )
}

export default function SpecHud() {
  const [active, setActive] = useState(false)
  const [state, setState] = useState<SpecState | null>(null)

  useListener<SpecInfo>('specStart', (data) => {
    setActive(true)
    setState({ name: data.name, userId: data.userId, health: 0, maxHealth: 100, armor: 0 })
  })

  useListener<SpecUpdate>('specUpdate', (data) => {
    setState((prev) => ({ ...prev, ...data }))
  })

  useListener('specStop', () => {
    setActive(false)
    setState(null)
  })

  if (!active || !state) return null

  return (
    <div className="pointer-events-none fixed bottom-10 left-1/2 z-40 -translate-x-1/2">
      <div className="w-[34rem] rounded-lg bg-modal px-6 py-4 shadow-2xl">
        <div className="mb-3 flex items-center gap-2.5">
          <Eye size={18} className="text-primary" />
          <span className="text-[1.1rem] font-semibold uppercase tracking-widest text-primary">
            Spectando
          </span>
          <span className="ml-auto text-[1.3rem] font-medium text-[#f8efff]">
            {state.name}
            {state.userId ? <span className="text-white/40"> · id {state.userId}</span> : null}
          </span>
        </div>

        <div className="flex flex-col gap-2.5">
          <div className="flex items-center gap-3">
            <Heart size={16} className="shrink-0 text-[#e0566b]" />
            <Bar value={state.health} max={state.maxHealth} color="#e0566b" />
            <span className="w-20 shrink-0 text-right font-mono text-[1.1rem] text-[#f8efff]">
              {state.health}/{state.maxHealth}
            </span>
          </div>
          <div className="flex items-center gap-3">
            <Shield size={16} className="shrink-0 text-[#4f8dff]" />
            <Bar value={state.armor} max={100} color="#4f8dff" />
            <span className="w-20 shrink-0 text-right font-mono text-[1.1rem] text-[#f8efff]">
              {state.armor}/100
            </span>
          </div>
        </div>

        <p className="mt-3 text-center text-[1rem] text-white/40">
          [BACKSPACE] Sair do modo espectador
        </p>
      </div>
    </div>
  )
}
