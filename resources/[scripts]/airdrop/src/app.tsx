import { Route, Routes } from 'react-router-dom'
import { cn } from './lib/utils'
import { useVisibility } from './providers/Visibility'
import Airdrop from '@/modules/airdrop/page'

export default function App() {
  const { opened } = useVisibility()

  return (
    <div
      className={cn(
        'w-screen h-screen grid place-items-center transition-opacity duration-200',
        opened ? 'opacity-100' : 'opacity-0 pointer-events-none',
      )}
    >
      {opened && (
        <Routes>
          <Route path="/" element={<Airdrop />} />
        </Routes>
      )}
    </div>
  )
}
