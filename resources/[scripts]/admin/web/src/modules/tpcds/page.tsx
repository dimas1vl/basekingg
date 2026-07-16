import { useEffect, useRef, useState } from 'react'
import { MapPin, X } from 'lucide-react'
import { useAdmin } from '@/providers/AdminProvider'
import { fetchData } from '@/utils/fetchData'

const HELP_LINES = [
  'X Y Z',
  'X Y Z H',
  'X, Y, Z',
  'vec3(X, Y, Z)',
  'vec4(X, Y, Z, H)',
]

export default function Tpcds() {
  const { close } = useAdmin()
  const [input, setInput] = useState('')
  const [busy, setBusy] = useState(false)
  const inputRef = useRef<HTMLTextAreaElement | null>(null)

  useEffect(() => {
    inputRef.current?.focus()
  }, [])

  const submit = async () => {
    if (busy) return
    const text = input.trim()
    if (text === '') return

    setBusy(true)
    try {
      const res = await fetchData<{ ok: boolean }>('tpcds:teleport', { input: text })
      if (res?.ok) {
        close()
      }
    } finally {
      setBusy(false)
    }
  }

  const onKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      submit()
    }
  }

  return (
    <div className="w-[44rem] overflow-hidden rounded-lg bg-modal shadow-2xl">
      <div className="flex items-center justify-between border-b border-white/10 px-6 py-4">
        <div className="flex items-center gap-2.5">
          <MapPin size={20} className="text-primary" />
          <span className="text-[1.5rem] font-semibold uppercase tracking-wide text-[#f8efff]">
            Teleportar para Coordenada
          </span>
        </div>
        <button onClick={close} className="text-white/50 transition-colors hover:text-white">
          <X size={20} />
        </button>
      </div>

      <div className="flex flex-col gap-3 p-6">
        <label className="text-[1rem] font-medium uppercase tracking-wider text-white/45">
          Coordenadas (cole ou digite)
        </label>

        <textarea
          ref={inputRef}
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={onKeyDown}
          placeholder="vec4(-1520.19, -2721.81, 13.94, 311.3)"
          rows={3}
          className="resize-none rounded-md border border-white/10 bg-white/[0.04] px-4 py-3 font-mono text-[1.2rem] text-[#f8efff] outline-none transition-colors focus:border-primary/60"
          autoFocus
          spellCheck={false}
        />

        <div className="flex flex-col gap-1 text-[0.95rem] text-white/45">
          <span className="font-medium uppercase tracking-wider">Formatos aceitos</span>
          <div className="flex flex-wrap gap-x-3 gap-y-1 font-mono">
            {HELP_LINES.map((l) => (
              <span key={l} className="text-white/55">{l}</span>
            ))}
          </div>
        </div>

        <div className="mt-2 flex items-center justify-end gap-2">
          <button
            onClick={close}
            className="rounded-md border border-white/10 px-5 py-2.5 text-[1.1rem] font-medium uppercase tracking-wider text-white/75 transition-colors hover:bg-white/[0.06]"
          >
            Cancelar
          </button>
          <button
            onClick={submit}
            disabled={busy || input.trim() === ''}
            className="rounded-md border border-primary/60 bg-primary px-5 py-2.5 text-[1.1rem] font-semibold uppercase tracking-wider text-[#1d1c26] transition-opacity hover:opacity-90 disabled:opacity-40"
          >
            {busy ? 'Teleportando…' : 'Teleportar'}
          </button>
        </div>
      </div>
    </div>
  )
}
