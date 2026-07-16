import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { cn } from '@/lib/utils'
import { SwitchHeader } from '@/modules/home/switchMode/components/switch-header'
import {
  CLAN_COLUMNS,
  MOCK_CLAN_RANKING,
  MOCK_PLAYER_RANKING,
  PLAYER_COLUMNS,
  RANKING_TABS,
  type RankingTab,
} from './data'
import { RankingTable } from './components/ranking-table'

export default function RankingPage() {
  const navigate = useNavigate()
  const [tab, setTab] = useState<RankingTab>('player')

  const isClan = tab === 'clan'

  return (
    <div className="relative flex flex-col w-full h-full overflow-hidden">
      {/* Fundo escuro com brilho radial */}
      <div className="absolute inset-0 -z-10 bg-[#101012]" />
      <div
        className="absolute inset-0 -z-10"
        style={{
          background:
            'radial-gradient(115rem 65rem at 50% 40%, rgba(29,28,34,0.9) 0%, rgba(29,28,34,0) 70%)',
        }}
      />

      <div className="flex flex-col gap-[2.4rem] w-full h-full p-[5rem] min-h-0">
        {/* Cabeçalho */}
        <div className="flex flex-col shrink-0">
          <SwitchHeader title="RANKING" subtitle="" onBack={() => navigate('/')} />

          {/* Abas */}
          <div className="flex items-center gap-[0.6rem] h-[3rem] px-[3.6rem] bg-gradient-to-r from-[rgba(0,0,0,0.25)] to-[rgba(0,0,0,0)]">
            {RANKING_TABS.map((t) => {
              const active = t.id === tab
              return (
                <button
                  key={t.id}
                  onClick={() => t.enabled && setTab(t.id)}
                  className={cn(
                    'flex h-[3rem] items-center justify-center px-[1.2rem] transition-colors',
                    active
                      ? 'bg-[#9d0de9] cursor-pointer'
                      : t.enabled
                        ? 'cursor-pointer hover:bg-[rgba(157,13,233,0.25)]'
                        : 'cursor-default opacity-45',
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

        {/* Tabela */}
        {isClan ? (
          <RankingTable
            nameLabel="CLAN"
            valueColumns={CLAN_COLUMNS.slice(1)}
            rows={MOCK_CLAN_RANKING}
            showRankIcon
          />
        ) : (
          <RankingTable
            nameLabel="NOME"
            valueColumns={PLAYER_COLUMNS.slice(1)}
            rows={MOCK_PLAYER_RANKING}
            useMedals
          />
        )}
      </div>
    </div>
  )
}
