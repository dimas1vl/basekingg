import { fetchData } from '@/utils/fetchData'
import { useQueryClient } from '@tanstack/react-query'
import { createContext, useCallback, useContext, useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useListener } from '../hooks/listener'

interface VisibilityContextValue {
  opened: boolean
  close: () => void
}

const VisibilityCtx = createContext<VisibilityContextValue>({
  opened: false,
  close: () => {},
})

export function VisibilityProvider({ children }: { children: React.ReactNode }) {
  const [opened, setOpened] = useState(false)
  const navigate = useNavigate()
  const queryClient = useQueryClient()

  useListener('open', () => {
    navigate('/')
    setOpened(true)
    queryClient.clear()
  })

  const close = useCallback(() => {
    setOpened(false)
    fetchData('close')
  }, [])

  useListener('close', close)

  useEffect(() => {
    if (!opened) return

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') close()
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [opened, close])

  return <VisibilityCtx.Provider value={{ opened, close }}>{children}</VisibilityCtx.Provider>
}

export const useVisibility = () => useContext(VisibilityCtx)
