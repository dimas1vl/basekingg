import { useCallback, useEffect, useState } from 'react'
import { AlertTriangle, BadgeCheck, Info, Star, XCircle } from 'lucide-react'
import { useListener } from '@/hooks/listener'
import type { NotifyPayload, NotifyType } from '@/types/nui'

interface Toast extends NotifyPayload {
  id: number
}

const PRESETS: Record<NotifyType, { title: string; color: string; Icon: typeof Info }> = {
  success: { title: 'Sucesso', color: '#3ad17a', Icon: BadgeCheck },
  error: { title: 'Erro', color: '#e0566b', Icon: XCircle },
  info: { title: 'Informacao', color: '#4f8dff', Icon: Info },
  warning: { title: 'Atencao', color: '#e0a73a', Icon: AlertTriangle },
  importante: { title: 'Importante', color: '#c8fe4e', Icon: Star },
}

let counter = 0

function ToastCard({ toast, onDone }: { toast: Toast; onDone: (id: number) => void }) {
  const preset = PRESETS[toast.type] ?? PRESETS.info
  const { Icon } = preset

  useEffect(() => {
    const timeout = setTimeout(() => onDone(toast.id), toast.duration * 1000)
    return () => clearTimeout(timeout)
  }, [toast.id, toast.duration, onDone])

  return (
    <div
      className="animate-toast-in flex w-[28rem] items-center gap-3 overflow-hidden rounded-md bg-modal py-3 pl-4 pr-5 shadow-lg"
      style={{ borderLeft: `0.3rem solid ${preset.color}` }}
    >
      <Icon size={22} color={preset.color} className="shrink-0" />
      <div className="flex flex-col">
        <span className="text-[1.2rem] font-semibold" style={{ color: preset.color }}>
          {preset.title}
        </span>
        <span className="text-[1.2rem] leading-tight text-[#f8efff]">{toast.message}</span>
      </div>
    </div>
  )
}

export default function Toaster() {
  const [toasts, setToasts] = useState<Toast[]>([])

  useListener<NotifyPayload>('notify', (data) => {
    if (!data?.message) return
    counter += 1
    const toast: Toast = {
      id: counter,
      type: data.type ?? 'info',
      message: data.message,
      duration: data.duration ?? 5,
    }
    setToasts((prev) => [...prev, toast])
  })

  const handleDone = useCallback((id: number) => {
    setToasts((prev) => prev.filter((t) => t.id !== id))
  }, [])

  return (
    <div className="pointer-events-none fixed right-6 top-6 z-50 flex flex-col gap-2">
      {toasts.map((toast) => (
        <ToastCard key={toast.id} toast={toast} onDone={handleDone} />
      ))}
    </div>
  )
}
