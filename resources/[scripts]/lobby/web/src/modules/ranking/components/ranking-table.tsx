import { cn } from '@/lib/utils'
import { RankParachuteIcon } from '../icons'
import type { RankRow } from '../data'

type Medal = 'gold' | 'silver' | 'bronze'

const MEDAL: Record<Medal, { edge: string; accent: string; rowBg: string }> = {
  gold: {
    edge: 'rgba(254,198,78,0.9)',
    accent: '#fec64e',
    rowBg:
      'linear-gradient(90deg, rgba(254,198,78,0.2) 0%, rgba(254,198,78,0) 50%, rgba(254,198,78,0.2) 100%), linear-gradient(rgba(29,28,38,0.05), rgba(29,28,38,0.05))',
  },
  silver: {
    edge: 'rgba(228,228,228,0.9)',
    accent: '#e4e4e4',
    rowBg:
      'linear-gradient(90deg, rgba(228,228,228,0.2) 0%, rgba(228,228,228,0) 50%, rgba(228,228,228,0.2) 100%), linear-gradient(rgba(248,239,255,0.05), rgba(248,239,255,0.05))',
  },
  bronze: {
    edge: 'rgba(218,137,87,0.9)',
    accent: '#da8957',
    rowBg:
      'linear-gradient(90deg, rgba(218,137,87,0.2) 0%, rgba(218,137,87,0) 50%, rgba(218,137,87,0.2) 100%), linear-gradient(rgba(29,28,38,0.05), rgba(29,28,38,0.05))',
  },
}

type RankingTableProps = {
  nameLabel: string
  valueColumns: string[]
  rows: RankRow[]
  /** Ranking de clã: mostra o ícone dourado e número dourado em todas as linhas. */
  showRankIcon?: boolean
  /** Ranking de jogador: destaca top 3 com ouro/prata/bronze. */
  useMedals?: boolean
}

export function RankingTable({
  nameLabel,
  valueColumns,
  rows,
  showRankIcon = false,
  useMedals = false,
}: RankingTableProps) {
  return (
    <div className="flex flex-col flex-1 min-h-0 w-full border-2 border-[#4d4c55] border-solid">
      {/* Cabeçalho */}
      <div className="flex items-center justify-center h-[5.2rem] p-[1rem] bg-[rgba(29,28,38,0.55)] border-b border-solid border-[rgba(248,239,255,0.12)] shrink-0 w-full">
        <HeaderCell className="w-[15.9rem] shrink-0">#</HeaderCell>
        <HeaderCell className="flex-1 min-w-0">{nameLabel}</HeaderCell>
        {valueColumns.map((c) => (
          <HeaderCell key={c} className="flex-1 min-w-0">
            {c}
          </HeaderCell>
        ))}
      </div>

      {/* Linhas */}
      <div className="flex flex-col flex-1 min-h-0 overflow-y-auto w-full">
        {rows.map((row, i) => {
          const medal: Medal | undefined =
            useMedals && row.rank <= 3
              ? row.rank === 1
                ? 'gold'
                : row.rank === 2
                  ? 'silver'
                  : 'bronze'
              : undefined
          const medalCfg = medal ? MEDAL[medal] : null
          const altBg = i % 2 === 0 ? 'bg-[rgba(29,28,38,0.05)]' : 'bg-[rgba(248,239,255,0.05)]'

          return (
            <div
              key={row.rank}
              className={cn(
                'relative flex items-center justify-center h-[4.2rem] p-[1rem] border-b border-solid border-[rgba(248,239,255,0.12)] shrink-0 w-full',
                !medalCfg && altBg,
              )}
              style={medalCfg ? { backgroundImage: medalCfg.rowBg } : undefined}
            >
              {/* Acentos coloridos nas bordas (top 3) */}
              {medalCfg && (
                <>
                  <span
                    className="absolute left-0 top-0 bottom-0 w-[1.4rem]"
                    style={{
                      background: medalCfg.edge,
                      clipPath: 'polygon(0 0, 100% 50%, 0 100%)',
                    }}
                  />
                  <span
                    className="absolute right-0 top-0 bottom-0 w-[1.4rem]"
                    style={{
                      background: medalCfg.edge,
                      clipPath: 'polygon(100% 0, 0 50%, 100% 100%)',
                    }}
                  />
                </>
              )}

              {/* Coluna de posição */}
              <div className="flex items-center justify-center gap-[0.6rem] w-[15.9rem] shrink-0">
                {showRankIcon && <RankParachuteIcon className="size-[2.4rem] text-[#fedb4e] shrink-0" />}
                <span
                  className={cn('text-[1.2rem] font-semibold whitespace-nowrap')}
                  style={{
                    color: showRankIcon ? '#fedb4e' : medalCfg?.accent ?? '#f8efff',
                    opacity: !showRankIcon && !medalCfg ? 0.55 : 1,
                  }}
                >
                  {row.rank}
                </span>
              </div>

              {/* Nome */}
              <div className="flex flex-1 min-w-0 items-center justify-center">
                <span
                  className="text-[1.2rem] font-medium text-center whitespace-nowrap overflow-hidden text-ellipsis"
                  style={{ color: medalCfg?.accent ?? (showRankIcon ? '#ffffff' : '#f8efff') }}
                >
                  {row.name}
                </span>
              </div>

              {/* Valores */}
              {row.values.map((v, vi) => (
                <div key={vi} className="flex flex-1 min-w-0 items-center justify-center">
                  <span className="text-[1.2rem] font-medium text-[#f8efff] text-center whitespace-nowrap">
                    {v}
                  </span>
                </div>
              ))}
            </div>
          )
        })}
      </div>
    </div>
  )
}

function HeaderCell({ children, className }: { children: React.ReactNode; className?: string }) {
  return (
    <div className={cn('flex items-center justify-center', className)}>
      <span className="text-[1.4rem] font-semibold text-white text-center whitespace-nowrap">
        {children}
      </span>
    </div>
  )
}
