import { Route, Routes } from 'react-router-dom'
import { cn } from './lib/utils'
import { useVisibility } from './providers/Visibility'
import { useHudScale } from './hooks/useHudScale'
import Home from '@/modules/home/page'
import DominationOverlays from '@/modules/domination/page'
import HubOverlay from '@/modules/hub/page'
import ShopOverlay from '@/modules/shop/page'
import SpawnOverlays from '@/modules/spawn/page'
import VehiclesOverlay from '@/modules/vehicles/page'
import SettingsOverlays from '@/modules/settings/page'

export default function App() {
  const { opened } = useVisibility()
  const scale = useHudScale()

  return (
    <>
      <div
        className={cn(
          'relative w-screen h-screen overflow-hidden transition-opacity duration-200',
          opened ? 'opacity-100' : 'opacity-0 pointer-events-none',
        )}
      >
        <div
          style={{
            width:           1920,
            height:          1080,
            transform:       `scale(${scale.x}, ${scale.y})`,
            transformOrigin: 'top left',
            position:        'absolute',
            top:             0,
            left:            0,
          }}
        >
          <Routes>
            <Route path="/" element={<Home />} />
          </Routes>
        </div>
      </div>

      {/* Overlays da Dominação — independentes da visibilidade do HUD, cada um
          controla sua própria exibição via mensagens NUI. */}
      <DominationOverlays />
      <HubOverlay />
      <ShopOverlay />
      <SpawnOverlays />
      <VehiclesOverlay />
      <SettingsOverlays />
    </>
  )
}
