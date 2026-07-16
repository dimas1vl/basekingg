import { cn } from './lib/utils'
import { useAdmin } from './providers/AdminProvider'
import Toaster from './components/Toaster'
import SpecHud from './components/SpecHud'
import Cds from '@/modules/cds/page'
import Ban from '@/modules/ban/page'
import Panel from '@/modules/panel/page'
import PlayerInventarioModal from '@/modules/panel/PlayerInventarioModal'
import Tpcds from '@/modules/tpcds/page'
import ZonePoints from '@/modules/zonepoints/page'

export default function App() {
  const { view, banTarget, inventarioTarget, close, closeBan, closePlayerInventario } = useAdmin()
  const baseOpen = view !== 'none'
  const focusOpen = baseOpen || !!banTarget || !!inventarioTarget

  return (
    <>
      {/* Always-on overlays (no NUI focus) */}
      <Toaster />
      <SpecHud />

      {/* Focused screens */}
      <div
        className={cn(
          'fixed inset-0 transition-opacity duration-200',
          focusOpen ? 'opacity-100' : 'pointer-events-none opacity-0',
        )}
      >
        {/* Base view (cds / panel) */}
        <div
          onMouseDown={(e) => {
            if (e.target === e.currentTarget) close()
          }}
          className="grid h-full w-full place-items-center bg-black/55"
        >
          {view === 'cds' && <Cds />}
          {view === 'panel' && <Panel />}
          {view === 'tpcds' && <Tpcds />}
          {view === 'zonepoints' && <ZonePoints />}
        </div>

        {/* Ban modal overlay (can sit on top of the panel) */}
        {banTarget && (
          <div
            onMouseDown={(e) => {
              if (e.target === e.currentTarget) closeBan()
            }}
            className="absolute inset-0 grid place-items-center bg-black/60"
          >
            <Ban />
          </div>
        )}

        {/* Player inventario modal overlay (sits on top of the panel) */}
        {inventarioTarget && (
          <div
            onMouseDown={(e) => {
              if (e.target === e.currentTarget) closePlayerInventario()
            }}
            className="absolute inset-0 grid place-items-center bg-black/60"
          >
            <PlayerInventarioModal />
          </div>
        )}
      </div>
    </>
  )
}
