import { useListener } from '@/hooks/listener'
import { useToast } from '@/components/ui'
import type { FriendNotification } from '@/types/nui'

const NOTIFICATION_MESSAGES: Record<FriendNotification['type'], (name: string) => string> = {
  request_received: (name) => `${name} te enviou um pedido de amizade`,
  request_accepted: (name) => `${name} aceitou seu pedido de amizade`,
  request_declined: () => 'Seu pedido de amizade foi recusado',
  invite_declined: (name) => `${name} recusou o convite para o squad`,
}

export function FriendNotificationHandler() {
  const { addToast } = useToast()

  useListener<FriendNotification>('friendNotification', (notification) => {
    const getMessage = NOTIFICATION_MESSAGES[notification.type]
    if (!getMessage) return
    const variant = notification.type === 'request_accepted' ? 'success' : 'info'
    addToast(getMessage(notification.fromName), variant)
  })

  return null
}
