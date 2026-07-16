import { useQueryClient } from '@tanstack/react-query'
import { createContext, useCallback, useContext, useState } from 'react'
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

  useListener('show', () => {
    navigate('/')
    setOpened(true)
    queryClient.clear()
  })

  useListener<{ value: boolean }>('visible', ({ value }) => {
    if (value) {
      navigate('/')
      setOpened(true)
    } else {
      setOpened(false)
    }
  })

  useListener('close', () => setOpened(false))

  const close = useCallback(() => setOpened(false), [])

  return <VisibilityCtx.Provider value={{ opened, close }}>{children}</VisibilityCtx.Provider>
}

export const useVisibility = () => useContext(VisibilityCtx)
