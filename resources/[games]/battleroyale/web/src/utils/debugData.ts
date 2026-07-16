import { isEnvBrowser } from './misc'

interface DebugEvent<T = unknown> {
  event: string
  data?: T
}

export function debugData<T = unknown>(events: DebugEvent<T>[], timer = 750): void {
  if (import.meta.env.MODE !== 'development' || !isEnvBrowser()) return

  for (const { event, data } of events) {
    setTimeout(() => {
      window.dispatchEvent(new MessageEvent('message', { data: { action: event, data } }))
    }, timer)
  }
}
