import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Check, X, UserPlus, Swords, UserMinus } from 'lucide-react'
import { DividerIcon, NoFriendsIcon, SlashesIcon } from '@/components/icons'
import { ButtonHero, PerfilView, Preencher, SearchInput, SwitchMode, useToast } from '@/components/ui'
import { useLobby } from '@/providers/LobbyProvider'
import { fetchData } from '@/utils/fetchData'
import { NewsSlider } from './news-slider'

export default function Home() {
  const navigate = useNavigate()
  const { player, friends, squad, news, selectedMode, pendingRequests, squadInvites, removeSquadInvite } = useLobby()
  const { addToast } = useToast()
  const [fillSlot, setFillSlot] = useState(false)
  const [search, setSearch] = useState('')

  useEffect(() => {
    fetchData('fetchFriends')
  }, [])

  const isInSquad = squad.length > 1
  const isLeader = !isInSquad || squad.some((m) => m.id === player?.id && m.isLeader)

  const handleJoinQueue = () => {
    if (!isLeader) return
    fetchData('joinQueue', {
      category: selectedMode.category,
      submode: selectedMode.submode,
      fillSlot,
    })
  }

  const handleLeaveSquad = async () => {
    const res = await fetchData<{ ok: boolean }>('leaveSquad')
    if (res?.ok) {
      addToast('Você saiu do squad', 'info')
    }
  }

  const handleSendRequest = async () => {
    const nickname = search.trim()
    if (!nickname) return
    const res = await fetchData<{ ok: boolean; error?: string }>('sendFriendRequest', { nickname })
    if (res?.ok) {
      addToast('Pedido de amizade enviado!', 'success')
      setSearch('')
    } else {
      addToast(res?.error ?? 'Erro ao enviar pedido', 'error')
    }
  }

  const handleAcceptRequest = async (userId: number) => {
    const res = await fetchData<{ ok: boolean; error?: string }>('acceptFriendRequest', { userId })
    if (res?.ok) {
      addToast('Pedido aceito!', 'success')
    } else {
      addToast(res?.error ?? 'Erro ao aceitar pedido', 'error')
    }
  }

  const handleDeclineRequest = async (userId: number) => {
    const res = await fetchData<{ ok: boolean; error?: string }>('declineFriendRequest', { userId })
    if (res?.ok) {
      addToast('Pedido recusado', 'info')
    } else {
      addToast(res?.error ?? 'Erro ao recusar pedido', 'error')
    }
  }

  const handleInviteToSquad = async (friendId: string) => {
    const res = await fetchData<{ ok: boolean; error?: string }>('inviteToSquad', { friendId: Number(friendId) })
    if (res?.ok) {
      addToast('Convite enviado!', 'success')
    } else {
      addToast(res?.error ?? 'Erro ao convidar', 'error')
    }
  }

  const handleRemoveFriend = async (friendId: string) => {
    const res = await fetchData<{ ok: boolean; error?: string }>('removeFriend', { friendId: Number(friendId) })
    if (res?.ok) {
      addToast('Amigo removido', 'info')
    } else {
      addToast(res?.error ?? 'Erro ao remover amigo', 'error')
    }
  }

  const handleAcceptSquadInvite = async (fromUserId: number) => {
    const res = await fetchData<{ ok: boolean; error?: string }>('acceptSquadInvite', { fromUserId })
    if (res?.ok) {
      removeSquadInvite(fromUserId)
      addToast('Você entrou no squad!', 'success')
    } else {
      addToast(res?.error ?? 'Erro ao aceitar convite', 'error')
    }
  }

  const handleDeclineSquadInvite = async (fromUserId: number) => {
    await fetchData('declineSquadInvite', { fromUserId })
    removeSquadInvite(fromUserId)
    addToast('Convite recusado', 'info')
  }

  const filteredFriends = search.trim()
    ? friends.filter((f) => f.name.toLowerCase().includes(search.trim().toLowerCase()))
    : friends

  const onlineFriends = filteredFriends.filter((f) => f.online)
  const offlineFriends = filteredFriends.filter((f) => !f.online)
  const sortedFriends = [...onlineFriends, ...offlineFriends]

  const hasIncoming = pendingRequests.incoming.length > 0
  const hasSquadInvites = squadInvites.length > 0
  const hasFriends = sortedFriends.length > 0
  const hasContent = hasIncoming || hasSquadInvites || hasFriends

  return (
    <div className="flex items-start justify-between w-full h-full px-[5rem] py-[1.8rem] overflow-hidden">
      <div className="flex flex-col w-[41rem] shrink-0">
        <NewsSlider items={news} />
        <DividerIcon width="100%" className="shrink-0 text-[#9D0DE9]" />
      </div>

      <div className="flex flex-col justify-between w-[41rem] shrink-0 h-full min-h-0">
        <div className="flex flex-col min-h-0 flex-1">
          <div className="flex flex-col shrink-0">
            <div className="bg-[rgba(29,28,38,0.95)] p-[1.8rem]">
              <div className="flex h-[4.2rem] items-center justify-between border-t-2 border-r-2 border-b-2 border-l-8 border-solid border-[#c8fe4e] pl-[1.6rem] pr-[1.2rem]">
                <span className="text-[1.4rem] text-[#c8fe4e] whitespace-nowrap">SEU PERFIL</span>
                <SlashesIcon width={30} height={12} className="text-[#c8fe4e]" />
              </div>
            </div>
            <PerfilView
              username={player?.name ?? ''}
              team={player?.team ?? ''}
              avatarSrc={player?.avatar ?? new URL('/avatar.png', import.meta.url).href}
              backgroundSrc={player?.banner ?? new URL('/banner-perfil.png', import.meta.url).href}
              variant="default"
              onClick={() => navigate('/perfil')}
            />
          </div>

          <div className="flex flex-col min-h-0 flex-1">
            <div className="bg-[rgba(29,28,38,0.95)] px-[1.8rem] py-[1.2rem] shrink-0">
              <div className="flex h-[3.2rem] items-center justify-between border-l-8 border-solid border-[#f8efff] pl-[1.6rem] pr-[1.2rem]">
                <span className="text-[1.4rem] text-[#f8efff] whitespace-nowrap">LISTA DE AMIGOS</span>
                <SlashesIcon width={30} height={12} className="text-[#f8efff]" />
              </div>
            </div>
            <div className="bg-[rgba(29,28,38,0.85)] flex flex-col gap-[1.2rem] px-[1.8rem] py-[0.8rem] min-h-0 flex-1">
              <div className="h-px w-full bg-[#f8efff] opacity-5 shrink-0" />
              <div className="flex gap-[0.6rem] shrink-0">
                <SearchInput
                  className="flex-1"
                  placeholder="ADICIONAR AMIGO"
                  value={search}
                  onChange={setSearch}
                  onKeyDown={(e) => { if (e.key === 'Enter') handleSendRequest() }}
                />
                <button
                  className="flex items-center justify-center size-[4.2rem] border border-solid border-[rgba(200,254,78,0.4)] bg-[rgba(200,254,78,0.08)] cursor-pointer shrink-0 transition-colors hover:bg-[rgba(200,254,78,0.2)]"
                  onClick={handleSendRequest}
                >
                  <UserPlus size={18} className="text-[#c8fe4e]" />
                </button>
              </div>

              <div className="flex flex-col gap-[0.6rem] flex-1 min-h-0 overflow-y-auto">
                {/* Squad invites */}
                {hasSquadInvites && squadInvites.map((inv) => (
                  <SquadInviteCard
                    key={`squad-${inv.fromUserId}`}
                    name={inv.fromName}
                    onAccept={() => handleAcceptSquadInvite(inv.fromUserId)}
                    onDecline={() => handleDeclineSquadInvite(inv.fromUserId)}
                  />
                ))}

                {/* Pending friend requests */}
                {hasIncoming && pendingRequests.incoming.map((req) => (
                  <FriendRequestCard
                    key={`req-${req.userId}`}
                    name={req.name}
                    onAccept={() => handleAcceptRequest(req.userId)}
                    onDecline={() => handleDeclineRequest(req.userId)}
                  />
                ))}

                {/* Separator between requests and friends */}
                {(hasIncoming || hasSquadInvites) && hasFriends && (
                  <div className="h-px w-full bg-[rgba(248,239,255,0.08)] shrink-0 my-[0.2rem]" />
                )}

                {/* Friend list */}
                {hasFriends && sortedFriends.map((f) => (
                  <FriendCard
                    key={f.id}
                    friend={f}
                    onInvite={() => handleInviteToSquad(f.id)}
                    onRemove={() => handleRemoveFriend(f.id)}
                  />
                ))}

                {/* Empty state */}
                {!hasContent && (
                  <div className="flex flex-col gap-[1.2rem] flex-1 min-h-0 items-center justify-center opacity-55 overflow-hidden">
                    <NoFriendsIcon width={46} height={45} className="text-[#f8efff] shrink-0" />
                    <div className="flex flex-col gap-[0.4rem] items-center shrink-0">
                      <span className="text-[1.2rem] text-[#f8efff] whitespace-nowrap">
                        VOCÊ NÃO POSSUI AMIGOS
                      </span>
                      <span className="text-[1.2rem] text-[#f8efff] whitespace-nowrap">
                        ADICIONE AMIGOS E OS VERÁ POR AQUI.
                      </span>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>

          <DividerIcon width="100%" className="shrink-0 text-[#C8FE4E]" />
        </div>

        <div className="flex flex-col gap-[1.6rem]">
          <div className="flex flex-col border-2 border-[rgba(248,239,255,0.25)] border-solid">
            <div className="bg-[rgba(29,28,38,0.85)] flex items-center justify-between px-[1.8rem] py-[0.8rem]">
              <span className="text-[1.2rem] text-[#f8efff] whitespace-nowrap">MODO DE JOGO</span>
              <SlashesIcon width={30} height={12} className="text-[#f8efff]" />
            </div>
            <SwitchMode className="w-full" onClick={() => navigate('/switch-mode')} />
          </div>

          <div className="bg-[rgba(29,28,38,0.85)] flex flex-col gap-[1rem] items-center p-[1.8rem]">
            <Preencher className="w-full" onChange={setFillSlot} />
            <ButtonHero className="w-full" onClick={handleJoinQueue} disabled={!isLeader} />
            {isInSquad && (
              <button
                className="flex items-center justify-center w-full h-[3.6rem] bg-[rgba(248,239,255,0.06)] border border-solid border-[rgba(248,239,255,0.15)] cursor-pointer transition-opacity hover:opacity-80"
                onClick={handleLeaveSquad}
              >
                <span className="font-['Termina',sans-serif] text-[1.2rem] font-semibold text-[rgba(248,239,255,0.6)] whitespace-nowrap">
                  SAIR DO SQUAD
                </span>
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

function FriendRequestCard({
  name,
  onAccept,
  onDecline,
}: {
  name: string
  onAccept: () => void
  onDecline: () => void
}) {
  return (
    <div className="flex items-center gap-[1.2rem] px-[1.4rem] py-[0.8rem] bg-[rgba(200,254,78,0.04)] border-l-4 border-solid border-[#c8fe4e] animate-[slideIn_0.3s_ease-out]">
      <div className="size-[4rem] rounded-full bg-[rgba(200,254,78,0.12)] flex items-center justify-center shrink-0">
        <UserPlus size={18} className="text-[#c8fe4e]" />
      </div>

      <div className="flex flex-col gap-[0.2rem] flex-1 min-w-0">
        <span className="text-[1.2rem] font-semibold text-[#f8efff] truncate">{name}</span>
        <span className="text-[1rem] text-[rgba(248,239,255,0.45)]">PEDIDO DE AMIZADE</span>
      </div>

      <div className="flex items-center gap-[0.4rem] shrink-0">
        <button
          className="size-[3.2rem] flex items-center justify-center bg-[#c8fe4e] cursor-pointer transition-opacity hover:opacity-80"
          onClick={onAccept}
        >
          <Check size={16} className="text-[#1d1c26]" strokeWidth={3} />
        </button>
        <button
          className="size-[3.2rem] flex items-center justify-center bg-[rgba(248,239,255,0.08)] border border-solid border-[rgba(248,239,255,0.15)] cursor-pointer transition-opacity hover:opacity-80"
          onClick={onDecline}
        >
          <X size={16} className="text-[rgba(248,239,255,0.6)]" strokeWidth={3} />
        </button>
      </div>
    </div>
  )
}

function SquadInviteCard({
  name,
  onAccept,
  onDecline,
}: {
  name: string
  onAccept: () => void
  onDecline: () => void
}) {
  return (
    <div className="flex items-center gap-[1.2rem] px-[1.4rem] py-[0.8rem] bg-[rgba(157,13,233,0.06)] border-l-4 border-solid border-[#9d0de9] animate-[slideIn_0.3s_ease-out]">
      <div className="size-[4rem] rounded-full bg-[rgba(157,13,233,0.15)] flex items-center justify-center shrink-0">
        <Swords size={18} className="text-[#e9beff]" />
      </div>

      <div className="flex flex-col gap-[0.2rem] flex-1 min-w-0">
        <span className="text-[1.2rem] font-semibold text-[#f8efff] truncate">{name}</span>
        <span className="text-[1rem] text-[rgba(248,239,255,0.45)]">CONVITE PARA SQUAD</span>
      </div>

      <div className="flex items-center gap-[0.4rem] shrink-0">
        <button
          className="size-[3.2rem] flex items-center justify-center bg-[#9d0de9] cursor-pointer transition-opacity hover:opacity-80"
          onClick={onAccept}
        >
          <Check size={16} className="text-[#f8efff]" strokeWidth={3} />
        </button>
        <button
          className="size-[3.2rem] flex items-center justify-center bg-[rgba(248,239,255,0.08)] border border-solid border-[rgba(248,239,255,0.15)] cursor-pointer transition-opacity hover:opacity-80"
          onClick={onDecline}
        >
          <X size={16} className="text-[rgba(248,239,255,0.6)]" strokeWidth={3} />
        </button>
      </div>
    </div>
  )
}

function FriendCard({
  friend,
  onInvite,
  onRemove,
}: {
  friend: { id: string; name: string; team: string; avatar: string; banner: string; online: boolean }
  onInvite: () => void
  onRemove: () => void
}) {
  const [hovered, setHovered] = useState(false)

  return (
    <div
      className="relative"
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
    >
      <div className="absolute top-[0.8rem] left-[0.8rem] z-10 flex items-center gap-[0.4rem]">
        <div className={`size-[0.8rem] rounded-full ${friend.online ? 'bg-[#c8fe4e] shadow-[0_0_0.6rem_rgba(200,254,78,0.5)]' : 'bg-[rgba(248,239,255,0.2)]'}`} />
      </div>
      <PerfilView
        username={friend.name}
        team={friend.team}
        avatarSrc={friend.avatar}
        backgroundSrc={friend.banner}
        variant="default"
        className={!friend.online ? 'opacity-40' : undefined}
      />
      {hovered && (
        <div className="absolute right-[6.5rem] top-1/2 -translate-y-1/2 flex items-center gap-[0.4rem] z-10">
          {friend.online && (
            <button
              className="flex items-center gap-[0.4rem] h-[3rem] px-[1rem] bg-[#c8fe4e] cursor-pointer transition-opacity hover:opacity-80"
              onClick={(e) => { e.stopPropagation(); onInvite() }}
            >
              <Swords size={13} className="text-[#1d1c26]" />
              <span className="font-['Termina',sans-serif] text-[1rem] font-semibold text-[#1d1c26] whitespace-nowrap">
                CONVIDAR
              </span>
            </button>
          )}
          <button
            className="flex items-center justify-center size-[3rem] bg-[rgba(255,78,78,0.15)] border border-solid border-[rgba(255,78,78,0.3)] cursor-pointer transition-opacity hover:opacity-80"
            onClick={(e) => { e.stopPropagation(); onRemove() }}
          >
            <UserMinus size={14} className="text-[#ff6b6b]" />
          </button>
        </div>
      )}
    </div>
  )
}
