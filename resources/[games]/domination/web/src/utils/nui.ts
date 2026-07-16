import { isEnvBrowser } from './misc'
import { fetchData } from './fetchData'

/**
 * Dispara um callback NUI (POST https://<resource>/<event>) sem bloquear a UI.
 * Equivale ao helper `post()` do build antigo: no browser (dev) vira no-op e
 * qualquer erro de rede é engolido — a UI nunca quebra por causa do callback.
 */
export async function nuiPost<T = unknown>(event: string, data?: unknown): Promise<T | void> {
  if (isEnvBrowser()) return
  try {
    return await fetchData<T>(event, data)
  } catch {
    /* noop */
  }
}
