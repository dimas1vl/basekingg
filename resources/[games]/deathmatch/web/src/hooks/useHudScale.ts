import { useState, useEffect } from 'react'

const BASE_W = 1920
const BASE_H = 1080

export function useHudScale() {
  const [scale, setScale] = useState(() => ({
    x: window.innerWidth  / BASE_W,
    y: window.innerHeight / BASE_H,
  }))

  useEffect(() => {
    const update = () =>
      setScale({
        x: window.innerWidth  / BASE_W,
        y: window.innerHeight / BASE_H,
      })

    window.addEventListener('resize', update)
    return () => window.removeEventListener('resize', update)
  }, [])

  return scale
}
