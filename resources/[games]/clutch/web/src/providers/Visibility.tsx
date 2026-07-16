import { createContext, useContext, useState, ReactNode } from 'react'
import { useListener } from '@/hooks/listener'

interface VisibilityContextValue {
  visible: boolean
}

const VisibilityCtx = createContext<VisibilityContextValue>({ visible: false })

export function VisibilityProvider({ children }: { children: ReactNode }) {
  const [visible, setVisible] = useState(false)

  useListener<boolean>('visible', (data) => {
    setVisible(!!data)
  })

  return (
    <VisibilityCtx.Provider value={{ visible }}>
      {children}
    </VisibilityCtx.Provider>
  )
}

export const useVisibility = () => useContext(VisibilityCtx)
