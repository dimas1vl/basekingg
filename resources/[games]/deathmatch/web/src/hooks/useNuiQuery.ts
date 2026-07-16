import { useQuery, type UseQueryOptions } from '@tanstack/react-query'
import { fetchData } from '@/utils/fetchData'

interface UseNuiQueryOptions<T> extends Omit<UseQueryOptions<T>, 'queryKey' | 'queryFn'> {
  event: string
  data?: unknown
  mockData?: T
}

export function useNuiQuery<T = unknown>(options: UseNuiQueryOptions<T>) {
  const { event, data, mockData, ...queryOptions } = options

  return useQuery<T>({
    queryKey: [event, data],
    queryFn: () => fetchData<T>(event, data, mockData),
    ...queryOptions,
  })
}
