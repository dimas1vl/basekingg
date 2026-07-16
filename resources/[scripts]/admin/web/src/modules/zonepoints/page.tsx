import { useMemo, useState } from 'react'
import { Check, Copy, Hexagon, X } from 'lucide-react'
import { useAdmin } from '@/providers/AdminProvider'
import { copyToClipboard } from '@/utils/clipboard'

const f = (n: number) => (Number.isFinite(n) ? n.toFixed(2) : '0.00')

export default function ZonePoints() {
  const { zonePoints, zoneRadius, close } = useAdmin()
  const [copied, setCopied] = useState(false)

  const isRadius = !!zoneRadius

  const text = useMemo(() => {
    if (zoneRadius) {
      const c = zoneRadius.center
      return `coords = vec4(${f(c.x)}, ${f(c.y)}, ${f(c.z)}, ${f(zoneRadius.height)}), radius = ${f(zoneRadius.radius)}`
    }
    if (!zonePoints || zonePoints.length === 0) return '{\n}'
    const lines = zonePoints.map((p) => `    vec3(${f(p.x)}, ${f(p.y)}, ${f(p.z)}),`)
    return `{\n${lines.join('\n')}\n}`
  }, [zonePoints, zoneRadius])

  if (!zonePoints && !zoneRadius) return null

  const handleCopy = async () => {
    const ok = await copyToClipboard(text)
    if (!ok) return
    setCopied(true)
    setTimeout(() => setCopied(false), 1200)
  }

  return (
    <div className="flex max-h-[80vh] w-[44rem] flex-col overflow-hidden rounded-lg bg-modal shadow-2xl">
      <div className="flex items-center justify-between border-b border-white/10 px-6 py-4">
        <div className="flex items-center gap-2.5">
          <Hexagon size={20} className="text-primary" />
          <span className="text-[1.5rem] font-semibold uppercase tracking-wide text-[#f8efff]">
            {isRadius ? 'Zona (Radius)' : `Pontos da Zona (${zonePoints?.length ?? 0})`}
          </span>
        </div>
        <button onClick={close} className="text-white/50 transition-colors hover:text-white">
          <X size={20} />
        </button>
      </div>

      <div className="flex flex-col gap-3 overflow-hidden p-6">
        <div className="flex items-center justify-between gap-4">
          <p className="text-[1.1rem] text-white/45">
            {isRadius
              ? 'Copie o centro e o raio para usar no seu script.'
              : 'Copie a lista de pontos para usar no seu script.'}
          </p>
          <button
            onClick={handleCopy}
            className="flex shrink-0 items-center gap-2 rounded-md border border-white/10 bg-white/[0.03] px-3 py-2 text-[1.1rem] text-white/70 transition-colors hover:border-primary/50 hover:bg-white/[0.06] hover:text-primary"
          >
            {copied ? <Check size={16} className="text-primary" /> : <Copy size={16} />}
            {copied ? 'Copiado' : 'Copiar tudo'}
          </button>
        </div>
        <pre className="max-h-[55vh] overflow-auto rounded-md border border-white/10 bg-black/40 p-4 font-mono text-[1.2rem] leading-relaxed text-[#f8efff]">
          {text}
        </pre>
      </div>
    </div>
  )
}
