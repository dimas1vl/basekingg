import { useRef, useState } from 'react'
import { useListener } from '@/hooks/listener'

interface KillState {
  id: number
  color: [number, number, number]
}

export default function KillMarker() {
  const [mark, setMark] = useState<KillState | null>(null)
  const seq = useRef(0)

  useListener<{ color?: [number, number, number] }>('killMarker', (d) => {
    seq.current += 1
    const id = seq.current
    setMark({ id, color: d?.color ?? [255, 255, 255] })
    setTimeout(() => setMark((m) => (m && m.id === id ? null : m)), 520)
  })

  if (!mark) return null
  const c = `rgb(${mark.color[0]}, ${mark.color[1]}, ${mark.color[2]})`
  return (
    <div id="dom-killmark" style={{ color: c }}>
      <span>✕</span>
    </div>
  )
}
