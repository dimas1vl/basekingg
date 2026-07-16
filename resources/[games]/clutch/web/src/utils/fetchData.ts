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

  return resp.json()
}
