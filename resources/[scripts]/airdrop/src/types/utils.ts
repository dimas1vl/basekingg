export type NuiEvent<T = unknown> = {
  action: string
  data: T
}

export type FetchResponse<T = unknown> = {
  ok: boolean
  data: T
  message?: string
}
