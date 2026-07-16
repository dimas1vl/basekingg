import { fetchData } from '@/utils/fetchData'
import { useQueryClient } from '@tanstack/react-query'
import { createContext, useCallback, useContext, useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useListener } from '../hooks/listener'

export interface SafeZoneOption { id: string; label: string }

interface VisibilityContextValue {
  opened: boolean
  showHHint: boolean
  preselectedMode: string | null
  safeZones: SafeZoneOption[] | null
  close: () => void
  consumePreselectedMode: () => void
  consumeSafeZones: () => void
}

const VisibilityCtx = createContext<VisibilityContextValue>({
  opened: false,
  showHHint: false,
  preselectedMode: null,
  safeZones: null,
  close: () => {},
  consumePreselectedMode: () => {},
  consumeSafeZones: () => {},
})

export function VisibilityProvider({ children }: { children: React.ReactNode }) {
  const [opened, setOpened] = useState(false)
  const [showHHint, setShowHHint] = useState(false)
  const [preselectedMode, setPreselectedMode] = useState<string | null>(null)
  const [safeZones, setSafeZones] = useState<SafeZoneOption[] | null>(null)
  const navigate = useNavigate()
  const queryClient = useQueryClient()

  useListener('show', () => {
    navigate('/')
    setOpened(true)
    setPreselectedMode(null)
    setSafeZones(null)
    queryClient.clear()
  })

  useListener<{ mode: string; zones?: SafeZoneOption[] }>('show-mode', (data) => {
    navigate('/')
    if (data && data.mode === 'safezone') {
      setSafeZones(Array.isArray(data.zones) ? data.zones : [])
      setPreselectedMode(null)
    } else {
      setPreselectedMode((data && data.mode) || null)
      setSafeZones(null)
    }
    setOpened(true)
    queryClient.clear()
  })

  useListener('show-h', () => setShowHHint(true))
  useListener('hide-h', () => setShowHHint(false))

  const close = useCallback(() => {
    setOpened(false)
    setPreselectedMode(null)
    setSafeZones(null)
    fetchData('close')
  }, [])

  const consumePreselectedMode = useCallback(() => setPreselectedMode(null), [])
  const consumeSafeZones = useCallback(() => setSafeZones(null), [])

  useListener('close', close)

  useEffect(() => {
    if (!opened) return
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') close()
    }
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [opened, close])

  return (
    <VisibilityCtx.Provider value={{ opened, showHHint, preselectedMode, safeZones, close, consumePreselectedMode, consumeSafeZones }}>
      {children}
    </VisibilityCtx.Provider>
  )
}

export const useVisibility = () => useContext(VisibilityCtx)
