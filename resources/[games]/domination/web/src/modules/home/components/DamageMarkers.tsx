import { useRef, useState } from 'react'
import { useListener } from '@/hooks/listener'

interface Mark {
  id: number
  amount: number
  x: number
  y: number
  color: [number, number, number]
}

interface DamagePayload {
  amount: number
  x: number
  y: number
  color?: [number, number, number]
}

export default function DamageMarkers() {
  const [marks, setMarks] = useState<Mark[]>([])
  const seq = useRef(0)

  useListener<DamagePayload>('damageMarker', (d) => {
    if (!d || typeof d.amount !== 'number') return
    seq.current += 1
    const id = seq.current
    const mark: Mark = {
      id,
      amount: d.amount,
      x: typeof d.x === 'number' ? d.x : 0.5,
      y: typeof d.y === 'number' ? d.y : 0.5,
      color: d.color ?? [255, 80, 80],
    }
    setMarks((prev) => [...prev, mark].slice(-14))
    setTimeout(() => setMarks((prev) => prev.filter((m) => m.id !== id)), 900)
  })

  return (
    <div id="dom-dmg-layer">
      {marks.map((m) => (
        <span
          key={m.id}
          className="dom-dmg"
          style={{
            left: `${m.x * 100}%`,
            top: `${m.y * 100}%`,
            color: `rgb(${m.color[0]}, ${m.color[1]}, ${m.color[2]})`,
          }}
        >
          -{m.amount}
        </span>
      ))}
    </div>
  )
}
