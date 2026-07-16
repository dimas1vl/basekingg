import { Route, Routes } from 'react-router-dom'
import { cn } from './lib/utils'
import { useVisibility } from './providers/Visibility'
import Home from '@/modules/home/page'
import HHintHud from '@/modules/home/components/HHintHud'
import HudOverlay from '@/modules/hud/HudOverlay'
import NpcBlips from '@/modules/hud/NpcBlips'

export default function App() {
  const { opened, showHHint } = useVisibility()

  return (
    <div className="relative w-screen h-screen overflow-hidden">
      <div
        className={cn(
          'w-full h-full grid place-items-center transition-opacity duration-200',
          opened ? 'opacity-100' : 'opacity-0 pointer-events-none',
        )}
      >
        {opened && (
          <Routes>
            <Route path="/" element={<Home />} />
          </Routes>
        )}
      </div>

      {showHHint && <HHintHud />}

      <HudOverlay />
      <NpcBlips />
    </div>
  )
}
