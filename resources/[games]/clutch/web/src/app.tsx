import { useVisibility } from './providers/Visibility'
import HudPage from './modules/hud/HudPage'

export default function App() {
  const { visible } = useVisibility()
  return (
    <div
      style={{
        opacity: visible ? 1 : 0,
        pointerEvents: visible ? 'auto' : 'none',
        transition: 'opacity 0.2s linear',
        width: '100%',
        height: '100%',
      }}
    >
      <HudPage />
    </div>
  )
}
