import { createContext, useCallback, useContext, useState } from 'react'
import { cn } from '@/lib/utils'

type ToastVariant = 'success' | 'info' | 'error'

type ToastItem = {
  id: number
  message: string
  variant: ToastVariant
}

type ToastContextValue = {
  addToast: (message: string, variant?: ToastVariant) => void
}

const ToastCtx = createContext<ToastContextValue>({ addToast: () => {} })

let nextId = 0

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [toasts, setToasts] = useState<ToastItem[]>([])

  const addToast = useCallback((message: string, variant: ToastVariant = 'info') => {
    const id = ++nextId
    setToasts((prev) => [...prev, { id, message, variant }])
    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== id))
    }, 4000)
  }, [])

  return (
    <ToastCtx.Provider value={{ addToast }}>
      {children}
      <div className="fixed top-[9rem] right-[5rem] flex flex-col gap-[0.8rem] z-50 pointer-events-none">
        {toasts.map((t) => (
          <div
            key={t.id}
            className={cn(
              'pointer-events-auto bg-[rgba(29,28,38,0.95)] px-[1.8rem] py-[1rem] border-l-4 border-solid animate-[slideIn_0.3s_ease-out]',
              t.variant === 'success' && 'border-[#c8fe4e]',
              t.variant === 'info' && 'border-[#f8efff]',
              t.variant === 'error' && 'border-[#ff4e4e]',
            )}
          >
            <span
              className={cn(
                "font-['Termina',sans-serif] text-[1.2rem] font-medium whitespace-nowrap",
                t.variant === 'success' && 'text-[#c8fe4e]',
                t.variant === 'info' && 'text-[#f8efff]',
                t.variant === 'error' && 'text-[#ff4e4e]',
              )}
            >
              {t.message}
            </span>
          </div>
        ))}
      </div>
    </ToastCtx.Provider>
  )
}

export const useToast = () => useContext(ToastCtx)
