import { EventEmitter } from 'events'
import { useEffect, useRef } from 'react'

type NuiHandler<T = unknown> = (data: T) => void

const emitter = new EventEmitter()

window.addEventListener('message', (event) => {
  const { action, data } = event.data ?? {}
  if (typeof action === 'string') {
    emitter.emit(action, data)
  }
})

export function useListener<T = unknown>(event: string, handler: NuiHandler<T>) {
  const handlerRef = useRef(handler)
  handlerRef.current = handler

  useEffect(() => {
    const listener = (data: T) => handlerRef.current(data)
    emitter.addListener(event, listener)
    return () => {
      emitter.removeListener(event, listener)
    }
  }, [event])
}
