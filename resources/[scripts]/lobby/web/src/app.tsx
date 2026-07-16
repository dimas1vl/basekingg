import { Route, Routes } from 'react-router-dom'
import { cn } from './lib/utils'
import { useVisibility } from './providers/Visibility'
import { LobbyProvider } from './providers/LobbyProvider'
import { ToastProvider } from '@/components/ui'
import { FriendNotificationHandler } from '@/components/friend-notification-handler'
import Layout from '@/components/layout'
import Home from '@/modules/home/page'
import SwitchModePage from '@/modules/home/switchMode/page'
import CustomizablePage from '@/modules/customizable/page'
import ProfilePage from '@/modules/perfil/page'
import StorePage from '@/modules/store/page'
import RankingPage from '@/modules/ranking/page'
import CaixasPage from '@/modules/caixas/page'

export default function App() {
  const { opened } = useVisibility()
  const isDevMode = import.meta.env.DEV

  return (
    <LobbyProvider>
      <ToastProvider>
      <FriendNotificationHandler />
      <div
        className={cn(
          'w-screen h-screen flex transition-opacity duration-200',
          opened ? 'opacity-100' : 'opacity-0 pointer-events-none',
        )}
        style={isDevMode ? { backgroundImage: `url(${new URL('/background.png', import.meta.url).href})`, backgroundSize: 'cover', backgroundPosition: 'center' } : undefined}
      >
        {opened && (
          <div className="w-full h-full">
            <Routes>
              <Route path="/" element={<Layout />}>
                <Route index element={<Home />} />
                <Route path="switch-mode" element={<SwitchModePage />} />
                <Route path="perfil" element={<ProfilePage />} />
                <Route path="store" element={<StorePage />} />
                <Route path="ranking" element={<RankingPage />} />
                <Route path="boxes" element={<CaixasPage />} />
                <Route path="custom" element={<CustomizablePage />} />
                <Route path="*" element={null} />
              </Route>
            </Routes>
          </div>
        )}
      </div>
    </ToastProvider>
    </LobbyProvider>
  )
}
