import { isEnvBrowser } from './misc'

export async function fetchData<T = unknown>(event: string, data?: unknown, mockData?: T): Promise<T> {
  if (isEnvBrowser() && mockData !== undefined) {
    return mockData
  }

  const resourceName = (window as any).GetParentResourceName?.() ?? 'nui-app'

  const resp = await fetch(`https://${resourceName}/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data ?? {}),
  })

  const text = await resp.text()
  if (!text) return undefined as unknown as T
  try {
    return JSON.parse(text) as T
  } catch {
    return undefined as unknown as T
  }
}
