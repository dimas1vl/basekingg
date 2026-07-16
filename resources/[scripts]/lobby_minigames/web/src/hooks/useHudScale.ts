import { useState, useLayoutEffect } from 'react'

const BASE_W = 1920
const BASE_H = 1080

function compute() {
  const s = Math.min(window.innerWidth / BASE_W, window.innerHeight / BASE_H)
  return {
    scale: s,
    offsetX: (window.innerWidth - BASE_W * s) / 2,
    offsetY: (window.innerHeight - BASE_H * s) / 2,
  }
}

export function useHudScale() {
  const [state, setState] = useState(compute)

  useLayoutEffect(() => {
    const update = () => setState(compute())
    update()
    window.addEventListener('resize', update)
    return () => window.removeEventListener('resize', update)
  }, [])

  return state
}
