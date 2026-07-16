import { cn } from '@/lib/utils'
import { NovatIcon, RankDiamondIcon, SlashesIcon } from '@/components/icons'
import type { PlayerData } from '@/types/nui'
import type { ProfileTab } from '../data'

const TABS: { id: ProfileTab; label: string }[] = [
  { id: 'info', label: 'INFORMAÇÕES' },
  { id: 'inventory', label: 'INVENTÁRIO' },
  { id: 'settings', label: 'CONFIGURAÇÕES' },
]

type ProfileHeaderProps = {
  player: PlayerData | null
  rank?: string
  tab: ProfileTab
  onTab: (tab: ProfileTab) => void
}

export function ProfileHeader({ player, rank = 'OURO', tab, onTab }: ProfileHeaderProps) {
  const avatar = player?.avatar ?? new URL('/avatar.png', import.meta.url).href
  const banner = player?.banner ?? new URL('/banner-perfil.png', import.meta.url).href

  return (
    <div className="relative flex flex-col shrink-0 w-full isolate">
      {/* decoração /// à esquerda das abas */}
      <SlashesIcon
        width={30}
        height={12}
        className="absolute left-[0.9rem] bottom-[0.9rem] text-[#c8fe4e] z-10"
      />

      {/* Banner + identidade */}
      <div className="relative z-[2] flex h-[12.4rem] items-end px-[5rem] py-[1rem] w-full">
        {/* fundo do banner recortado ao próprio banner */}
        <div className="absolute inset-0 overflow-hidden">
          <div className="absolute inset-0 bg-[#131217]" />
          <img
            alt=""
            src={banner}
            className="absolute inset-0 size-full max-w-none object-cover opacity-85 pointer-events-none"
          />
          <div className="absolute inset-0 bg-gradient-to-r from-[#1d1c26] to-[rgba(29,28,38,0)] pointer-events-none" />
        </div>

        {/* pointer-events-none: o avatar transborda por cima da barra de abas
            (efeito do design), mas não pode capturar os cliques das abas */}
        <div className="relative flex flex-col items-start pt-[4rem] self-stretch pointer-events-none">
          <div className="flex items-start gap-[1.2rem]">
            {/* Avatar grande */}
            <div className="relative shrink-0 size-[12.8rem] border-2 border-[#f8efff] border-solid overflow-hidden">
              <img alt={player?.name} src={avatar} className="absolute inset-0 size-full object-cover" />
            </div>

            <div className="flex items-center gap-[1.2rem]">
              {/* Nome + rank */}
              <div className="flex flex-col gap-[0.4rem] items-start justify-center">
                <div className="flex items-center">
                  {player?.team && (
                    <div className="flex items-center justify-center p-[0.6rem] bg-[#c8fe4e]">
                      <span className="text-[1.6rem] font-bold text-[#1d1c26] whitespace-nowrap">
                        {player.team}
                      </span>
                    </div>
                  )}
                  <div className="flex items-center justify-center h-full px-[0.6rem] bg-[rgba(248,239,255,0.1)]">
                    <span className="text-[2.4rem] font-semibold text-white whitespace-nowrap">
                      {player?.name ?? ''}
                    </span>
                  </div>
                </div>
                <span className="text-[2rem] font-medium text-[#fedb4e] whitespace-nowrap">{rank}</span>
              </div>

              {/* Losango dourado do rank */}
              <RankDiamondIcon className="shrink-0 size-[5.6rem]" />

              {/* Separador */}
              <svg
                width="8"
                height="43"
                viewBox="0 0 8 43"
                fill="none"
                className="shrink-0 opacity-40"
              >
                <path d="M6 2L2 41" stroke="#f8efff" strokeWidth="2" strokeLinecap="round" />
              </svg>

              {/* Ícone de patente */}
              <div className="relative shrink-0 size-[4.8rem] rounded-full flex items-center justify-center bg-[rgba(248,239,255,0.1)] overflow-hidden">
                <NovatIcon width={36} height={36} style={{ color: '#88cff5' }} />
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Abas */}
      <div className="relative z-[1] flex items-center gap-[0.6rem] h-[3rem] pl-[19.1rem] pr-[5rem] bg-gradient-to-r from-[rgba(0,0,0,0.25)] to-[rgba(0,0,0,0)] w-full">
        {TABS.map((t) => {
          const active = t.id === tab
          return (
            <button
              key={t.id}
              onClick={() => onTab(t.id)}
              className={cn(
                'flex h-[3rem] items-center justify-center px-[1.2rem] cursor-pointer transition-colors',
                active ? 'bg-[#9d0de9]' : 'hover:bg-[rgba(157,13,233,0.25)]',
              )}
            >
              <span className="text-[1.2rem] font-medium text-[#f8efff] whitespace-nowrap">
                {t.label}
              </span>
            </button>
          )
        })}
      </div>
    </div>
  )
}
