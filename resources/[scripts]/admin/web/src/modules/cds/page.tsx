import { useMemo, useState } from 'react'
import { Check, Copy, MapPin, X } from 'lucide-react'
import { useAdmin } from '@/providers/AdminProvider'
import { copyToClipboard } from '@/utils/clipboard'
import type { CdsPayload } from '@/types/nui'

const f = (n: number) => (Number.isFinite(n) ? n.toFixed(2) : '0.00')
const f1 = (n: number) => (Number.isFinite(n) ? n.toFixed(1) : '0.0')

function buildEntries(c: CdsPayload) {
  return [
    { label: 'vec4', value: `vec4(${f(c.x)}, ${f(c.y)}, ${f(c.z)}, ${f1(c.h)})` },
    { label: 'vec3', value: `vec3(${f(c.x)}, ${f(c.y)}, ${f(c.z)})` },
    { label: 'coords', value: `x = ${f(c.x)}, y = ${f(c.y)}, z = ${f(c.z)}, h = ${f1(c.h)}` },
    { label: 'x', value: `${f(c.x)}` },
    { label: 'y', value: `${f(c.y)}` },
    { label: 'z', value: `${f(c.z)}` },
    { label: 'h', value: `${f1(c.h)}` },
  ]
}

function CopyRow({ label, value }: { label: string; value: string }) {
  const [copied, setCopied] = useState(false)

  const handleCopy = async () => {
    const ok = await copyToClipboard(value)
    if (!ok) return
    setCopied(true)
    setTimeout(() => setCopied(false), 1200)
  }

  return (
    <button
      onClick={handleCopy}
      className="group flex items-center justify-between gap-4 rounded-md border border-white/10 bg-white/[0.03] px-4 py-3 transition-colors hover:border-primary/50 hover:bg-white/[0.06]"
    >
      <div className="flex flex-col items-start gap-0.5 text-left">
        <span className="text-[1rem] font-medium uppercase tracking-wider text-white/40">
          {label}
        </span>
        <span className="font-mono text-[1.3rem] text-[#f8efff]">{value}</span>
      </div>
      {copied ? (
        <Check size={18} className="shrink-0 text-primary" />
      ) : (
        <Copy size={18} className="shrink-0 text-white/40 group-hover:text-primary" />
      )}
    </button>
  )
}

export default function Cds() {
  const { cds, close } = useAdmin()
  const entries = useMemo(() => (cds ? buildEntries(cds) : []), [cds])

  if (!cds) return null

  return (
    <div className="w-[44rem] overflow-hidden rounded-lg bg-modal shadow-2xl">
      <div className="flex items-center justify-between border-b border-white/10 px-6 py-4">
        <div className="flex items-center gap-2.5">
          <MapPin size={20} className="text-primary" />
          <span className="text-[1.5rem] font-semibold uppercase tracking-wide text-[#f8efff]">
            Coordenadas (CDS)
          </span>
        </div>
        <button onClick={close} className="text-white/50 transition-colors hover:text-white">
          <X size={20} />
        </button>
      </div>

      <div className="flex flex-col gap-2 p-6">
        <p className="mb-1 text-[1.1rem] text-white/45">
          Clique em qualquer linha para copiar o formato para a area de transferencia.
        </p>
        {entries.map((entry) => (
          <CopyRow key={entry.label} label={entry.label} value={entry.value} />
        ))}
      </div>
    </div>
  )
}
