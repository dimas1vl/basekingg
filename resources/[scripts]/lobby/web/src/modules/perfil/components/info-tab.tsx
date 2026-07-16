import { useState } from 'react'
import { cn } from '@/lib/utils'
import { CaretIcon, CrosshairSimpleIcon } from '@/components/icons'
import type { PlayerData } from '@/types/nui'
import { fetchData } from '@/utils/fetchData'
import {
  ACHIEVEMENT_SLOTS,
  COMMENTS_PER_PAGE,
  MOCK_CLAN,
  MOCK_COMMENTS,
  TOTAL_ACHIEVEMENTS,
  type ClanInfo,
  type ProfileComment,
} from '../data'
import { CountTag, Panel, SectionHeader } from './section'

type InfoTabProps = {
  player: PlayerData | null
  clan?: ClanInfo
  comments?: ProfileComment[]
  unlockedAchievements?: number
}

export function InfoTab({
  player,
  clan = MOCK_CLAN,
  comments = MOCK_COMMENTS,
  unlockedAchievements = 2,
}: InfoTabProps) {
  const kills = player?.kills ?? 0
  const deaths = player?.deaths ?? 0
  const wins = player?.wins ?? 0
  const kd = (kills / Math.max(deaths, 1)).toFixed(2)

  return (
    <div className="flex gap-[1.2rem] h-full w-full px-[5rem] pb-[5rem] pt-[1.2rem] min-h-0">
      {/* Coluna esquerda */}
      <div className="flex flex-col gap-[1.2rem] flex-1 min-w-0">
        {/* Conquistas */}
        <Panel>
          <SectionHeader
            title="CONQUISTAS"
            subtitle="CONQUISTAS DESBLOQUEADAS"
            tag={<CountTag>{unlockedAchievements}/{TOTAL_ACHIEVEMENTS}</CountTag>}
          />
          <div className="flex items-center justify-between p-[1.4rem] bg-[rgba(29,28,38,0.55)] overflow-hidden">
            {Array.from({ length: ACHIEVEMENT_SLOTS }).map((_, i) => (
              <div
                key={i}
                className={cn(
                  'shrink-0 size-[6.4rem] border border-solid',
                  i < unlockedAchievements
                    ? 'bg-[rgba(200,254,78,0.12)] border-[#c8fe4e]'
                    : 'bg-[rgba(248,239,255,0.05)] border-[#4d4c55]',
                )}
              />
            ))}
          </div>
        </Panel>

        {/* Clan */}
        <Panel>
          <SectionHeader title="CLAN" subtitle="INFORMAÇÕES DO CLAN" />
          <div className="flex items-center gap-[4.8rem] p-[1.4rem] bg-[rgba(29,28,38,0.55)] overflow-hidden">
            <div className="flex items-center gap-[1.6rem] shrink-0">
              <div className="relative shrink-0 size-[7.2rem] border-2 border-[#f8efff] border-solid overflow-hidden bg-[rgba(248,239,255,0.06)]">
                <img
                  alt={clan.name}
                  src={player?.avatar ?? new URL('/avatar.png', import.meta.url).href}
                  className="absolute inset-0 size-full object-cover"
                />
              </div>
              <div className="flex flex-col gap-[1rem] items-start justify-center">
                <div className="flex items-center justify-center px-[0.4rem] bg-[#c8fe4e]">
                  <span className="text-[1.6rem] font-bold text-[#1d1c26] whitespace-nowrap">
                    {clan.tag}
                  </span>
                </div>
                <span className="text-[1.4rem] font-medium text-[#f8efff] whitespace-nowrap">
                  {clan.name}
                </span>
              </div>
            </div>

            <div className="flex items-center gap-[1.2rem] h-full">
              <ClanStat label="MEMBROS">
                <span className="text-[1.2rem] font-medium text-[#f8efff]">{clan.members}</span>
              </ClanStat>
              <ClanStat label="TROFEUS" className="w-[16.4rem]">
                <div className="flex items-center gap-[1.2rem] flex-1">
                  {clan.trophies.map((t, i) => (
                    <div key={i} className="flex items-center gap-[0.4rem] shrink-0">
                      <div className="flex items-center justify-center shrink-0 size-[2rem]">
                        <div className="rotate-45 size-[1.4rem] bg-[#636363] border-2 border-[rgba(255,255,255,0.37)] border-solid" />
                      </div>
                      <span className="text-[1.2rem] font-medium text-[#f8efff]">{t}</span>
                    </div>
                  ))}
                </div>
              </ClanStat>
              <ClanStat label="LIDER">
                <span className="text-[1.2rem] font-medium text-[#f8efff]">{clan.leader}</span>
              </ClanStat>
            </div>
          </div>
        </Panel>

        {/* Estatísticas */}
        <div className="flex gap-[1rem]">
          <StatCard title="PROPORÇÃO K/D" value={kd} />
          <StatCard title="ELIMINAÇÕES" value={kills.toLocaleString('pt-BR')} />
          <StatCard title="VITÓRIAS" value={wins.toLocaleString('pt-BR')} />
        </div>
      </div>

      {/* Coluna direita: comentários */}
      <CommentsPanel comments={comments} avatar={player?.avatar} />
    </div>
  )
}

function ClanStat({
  label,
  children,
  className,
}: {
  label: string
  children: React.ReactNode
  className?: string
}) {
  return (
    <div className={cn('flex flex-col h-full items-start justify-center', className)}>
      <div className="flex flex-col items-start justify-center w-full h-[2.5rem] px-[1.2rem] py-[0.8rem] bg-[rgba(248,239,255,0.12)] overflow-hidden">
        <span className="text-[1.2rem] font-bold text-[rgba(248,239,255,0.55)] whitespace-nowrap">
          {label}
        </span>
      </div>
      <div className="flex items-center w-full h-[3.4rem] px-[1.2rem] py-[0.8rem] bg-[rgba(248,239,255,0.05)] overflow-hidden">
        {children}
      </div>
    </div>
  )
}

function StatCard({ title, value }: { title: string; value: string }) {
  return (
    <Panel className="flex-1 min-w-0">
      <SectionHeader title={title} />
      <div className="flex items-center justify-between px-[1.4rem] py-[0.8rem] bg-[rgba(29,28,38,0.55)] overflow-hidden">
        <span className="text-[3.2rem] font-bold text-white whitespace-nowrap">{value}</span>
        <CrosshairSimpleIcon className="size-[6.4rem] text-[#f8efff] shrink-0" />
      </div>
    </Panel>
  )
}

function CommentsPanel({ comments, avatar }: { comments: ProfileComment[]; avatar?: string }) {
  const [page, setPage] = useState(1)
  const [draft, setDraft] = useState('')
  const totalPages = Math.max(1, Math.ceil(comments.length / COMMENTS_PER_PAGE))
  const start = (page - 1) * COMMENTS_PER_PAGE
  const pageComments = comments.slice(start, start + COMMENTS_PER_PAGE)
  const defaultAvatar = avatar ?? new URL('/avatar.png', import.meta.url).href

  const changePage = (dir: number) => setPage((p) => Math.min(totalPages, Math.max(1, p + dir)))

  const submit = () => {
    const text = draft.trim()
    if (!text) return
    fetchData('sendProfileComment', { text })
    setDraft('')
  }

  return (
    <Panel className="w-[64.5rem] shrink-0 h-full">
      <SectionHeader
        title="COMENTÁRIOS"
        subtitle="Pagina de comentários"
        right={
          <div className="flex items-center gap-[0.4rem] shrink-0">
            <button
              onClick={() => changePage(-1)}
              className="flex items-center justify-center size-[3.2rem] bg-[rgba(248,239,255,0.1)] cursor-pointer transition-colors hover:bg-[rgba(248,239,255,0.2)]"
            >
              <CaretIcon className="size-[2.4rem] text-[#f8efff] -scale-x-100" />
            </button>
            <CountTag>
              {page}/{totalPages}
            </CountTag>
            <button
              onClick={() => changePage(1)}
              className="flex items-center justify-center size-[3.2rem] bg-[rgba(248,239,255,0.1)] cursor-pointer transition-colors hover:bg-[rgba(248,239,255,0.2)]"
            >
              <CaretIcon className="size-[2.4rem] text-[#f8efff]" />
            </button>
          </div>
        }
      />
      <div className="flex flex-col flex-1 min-h-0 pb-[1.4rem] bg-[rgba(29,28,38,0.55)] overflow-hidden">
        {/* Campo de comentar */}
        <div className="flex items-center gap-[1.2rem] p-[1.4rem] bg-[#141419] shrink-0">
          <CommentAvatar src={defaultAvatar} />
          <input
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && submit()}
            placeholder="COMENTAR"
            className="flex-1 min-w-0 h-[4.8rem] px-[1.2rem] bg-transparent border border-solid border-[rgba(248,239,255,0.25)] text-[1.2rem] font-medium text-[#f8efff] placeholder:text-[rgba(248,239,255,0.55)] outline-none"
          />
        </div>

        {/* Lista */}
        <div className="flex flex-col flex-1 min-h-0 overflow-y-auto">
          {pageComments.map((c) => (
            <div key={c.id} className="flex items-start gap-[1.2rem] p-[1.4rem] shrink-0">
              <CommentAvatar src={c.avatar ?? defaultAvatar} />
              <div className="flex flex-col gap-[1.2rem] flex-1 min-w-0">
                <div className="flex flex-col gap-[0.6rem] items-start px-[0.4rem] bg-[rgba(248,239,255,0.03)]">
                  <span className="text-[1.4rem] font-bold text-[#f8efff]">{c.name}</span>
                  <span className="text-[1.2rem] font-medium text-[rgba(248,239,255,0.55)]">{c.date}</span>
                </div>
                <span className="text-[1.2rem] font-medium text-[#f8efff] break-words">{c.text}</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </Panel>
  )
}

function CommentAvatar({ src }: { src: string }) {
  return (
    <div className="relative shrink-0 size-[4.8rem] border-2 border-[#f8efff] border-solid overflow-hidden">
      <img alt="" src={src} className="absolute inset-0 size-full object-cover" />
    </div>
  )
}
