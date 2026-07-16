import { useMutation, type UseMutationOptions } from '@tanstack/react-query'
import { fetchData } from '@/utils/fetchData'

interface UseNuiMutationOptions<TResponse, TPayload>
  extends Omit<UseMutationOptions<TResponse, Error, TPayload>, 'mutationFn'> {
  event: string
}

export function useNuiMutation<TResponse = unknown, TPayload = unknown>(
  options: UseNuiMutationOptions<TResponse, TPayload>,
) {
  const { event, ...mutationOptions } = options

  return useMutation<TResponse, Error, TPayload>({
    mutationFn: (payload) => fetchData<TResponse>(event, payload),
    ...mutationOptions,
  })
}
