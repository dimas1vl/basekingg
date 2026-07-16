import { createContext, useCallback, useContext, useEffect, useRef, useState } from 'react'
import { useListener } from '@/hooks/listener'
import { fetchData } from '@/utils/fetchData'
import type {
  AdminView,
  BanPayload,
  CdsPayload,
  InventarioTarget,
  ZonePoint,
  ZoneRadius,
  ZonePointsPayload,
} from '@/types/nui'

interface AdminContextValue {
  view: AdminView
  cds: CdsPayload | null
  banTarget: BanPayload | null
  inventarioTarget: InventarioTarget | null
  zonePoints: ZonePoint[] | null
  zoneRadius: ZoneRadius | null
  openBan: (payload: BanPayload) => void
  closeBan: () => void
  openPlayerInventario: (payload: InventarioTarget) => void
  closePlayerInventario: () => void
  close: () => void
}

const AdminCtx = createContext<AdminContextValue>({
  view: 'none',
  cds: null,
  banTarget: null,
  inventarioTarget: null,
  zonePoints: null,
  zoneRadius: null,
  openBan: () => {},
  closeBan: () => {},
  openPlayerInventario: () => {},
  closePlayerInventario: () => {},
  close: () => {},
})

export function AdminProvider({ children }: { children: React.ReactNode }) {
  const [view, setView] = useState<AdminView>('none')
  const [cds, setCds] = useState<CdsPayload | null>(null)
  const [banTarget, setBanTarget] = useState<BanPayload | null>(null)
  const [inventarioTarget, setInventarioTarget] = useState<InventarioTarget | null>(null)
  const [zonePoints, setZonePoints] = useState<ZonePoint[] | null>(null)
  const [zoneRadius, setZoneRadius] = useState<ZoneRadius | null>(null)
  const wasOpen = useRef(false)

  useListener<CdsPayload>('openCds', (data) => {
    setCds(data)
    setView('cds')
  })

  useListener<ZonePointsPayload>('openZonePoints', (data) => {
    if (data?.center && typeof data.radius === 'number') {
      setZoneRadius({ center: data.center, radius: data.radius, height: data.height ?? 0 })
      setZonePoints(null)
    } else {
      setZonePoints(data?.points ?? [])
      setZoneRadius(null)
    }
    setView('zonepoints')
  })

  useListener('openPanel', () => setView('panel'))

  useListener('openTpcds', () => setView('tpcds'))

  useListener<BanPayload>('openBan', (data) => setBanTarget(data))

  // Lua dropped focus on its own.
  useListener('close', () => {
    setView('none')
    setBanTarget(null)
    setInventarioTarget(null)
  })

  // Release NUI focus exactly when every focused screen is closed.
  useEffect(() => {
    if (view === 'none' && !banTarget && !inventarioTarget) {
      if (wasOpen.current) {
        wasOpen.current = false
        fetchData('close')
      }
    } else {
      wasOpen.current = true
    }
  }, [view, banTarget, inventarioTarget])

  const openBan = useCallback((payload: BanPayload) => setBanTarget(payload), [])
  const closeBan = useCallback(() => setBanTarget(null), [])

  const openPlayerInventario = useCallback(
    (payload: InventarioTarget) => setInventarioTarget(payload),
    [],
  )
  const closePlayerInventario = useCallback(() => setInventarioTarget(null), [])

  // Closes the topmost focused screen (overlays first, then the base view).
  const close = useCallback(() => {
    if (inventarioTarget) {
      setInventarioTarget(null)
      return
    }
    if (banTarget) {
      setBanTarget(null)
      return
    }
    setView('none')
  }, [inventarioTarget, banTarget])

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') close()
    }
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [close])

  return (
    <AdminCtx.Provider
      value={{
        view,
        cds,
        banTarget,
        inventarioTarget,
        zonePoints,
        zoneRadius,
        openBan,
        closeBan,
        openPlayerInventario,
        closePlayerInventario,
        close,
      }}
    >
      {children}
    </AdminCtx.Provider>
  )
}

export const useAdmin = () => useContext(AdminCtx)
