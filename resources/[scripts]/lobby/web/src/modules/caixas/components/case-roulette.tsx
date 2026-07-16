import { useLayoutEffect, useRef, useState } from 'react'
import { DividerIcon } from '@/components/icons'
import { buildReel, RARITY_COLOR, ROULETTE_POOL, type RouletteItem } from '../data'

const CARD_W = 27.27 // rem
const GAP = 1.2 // rem
const PITCH = CARD_W + GAP
const REEL_LEN = 50
const WINNER_INDEX = 42
const START_INDEX = 5

type Phase = 'idle' | 'spinning' | 'result'

type CaseRouletteProps = {
  onWin?: (item: RouletteItem) => void
}

export function CaseRoulette({ onWin }: CaseRouletteProps) {
  const viewportRef = useRef<HTMLDivElement>(null)
  const stripRef = useRef<HTMLDivElement>(null)

  const [reel, setReel] = useState<RouletteItem[]>(() =>
    buildReel(ROULETTE_POOL, ROULETTE_POOL[0], REEL_LEN, WINNER_INDEX),
  )
  const [offset, setOffset] = useState(0)
  const [transition, setTransition] = useState('none')
  const [phase, setPhase] = useState<Phase>('idle')
  const [won, setWon] = useState<RouletteItem | null>(null)

  const remPx = () =>
    typeof window === 'undefined'
      ? 10
      : parseFloat(getComputedStyle(document.documentElement).fontSize) || 10

  const centerOffset = (index: number, jitterRem = 0) => {
    const vp = viewportRef.current
    if (!vp) return 0
    const rem = remPx()
    const cardW = CARD_W * rem
    const pitch = PITCH * rem
    return vp.clientWidth / 2 - (index * pitch + cardW / 2) + jitterRem * rem
  }

  // Posição inicial: reel populado e centrado num card qualquer.
  useLayoutEffect(() => {
    setTransition('none')
    setOffset(centerOffset(START_INDEX))
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const spin = () => {
    if (phase === 'spinning') return

    // Sorteia o vencedor e remonta a fita.
    const winner = ROULETTE_POOL[Math.floor(pseudoRandom() * ROULETTE_POOL.length)]
    const nextReel = buildReel(ROULETTE_POOL, winner, REEL_LEN, WINNER_INDEX)
    setReel(nextReel)
    setWon(null)
    setPhase('spinning')

    // Reset instantâneo para o início, depois anima até o vencedor.
    setTransition('none')
    setOffset(centerOffset(START_INDEX))

    requestAnimationFrame(() => {
      // força reflow para o reset valer antes da transição
      void stripRef.current?.offsetWidth
      const jitter = (pseudoRandom() - 0.5) * CARD_W * 0.55
      requestAnimationFrame(() => {
        setTransition('transform 5.6s cubic-bezier(0.12, 0.62, 0.1, 1)')
        setOffset(centerOffset(WINNER_INDEX, jitter))
      })
    })
  }

  const handleTransitionEnd = () => {
    if (phase !== 'spinning') return
    const winner = reel[WINNER_INDEX]
    setWon(winner)
    setPhase('result')
    onWin?.(winner)
  }

  return (
    <div className="flex flex-col items-center w-full gap-[2.4rem]">
      {/* Roleta */}
      <div ref={viewportRef} className="relative w-full h-[28.9rem] overflow-hidden">
        {/* Marcador central */}
        <div className="absolute left-1/2 -translate-x-1/2 top-0 bottom-0 w-[0.3rem] bg-[#c8fe4e] z-20 shadow-[0_0_1.2rem_rgba(200,254,78,0.8)] pointer-events-none" />
        <div className="absolute left-1/2 -translate-x-1/2 top-0 z-20 pointer-events-none">
          <div className="w-0 h-0 border-l-[0.9rem] border-r-[0.9rem] border-t-[1.1rem] border-l-transparent border-r-transparent border-t-[#c8fe4e]" />
        </div>
        {/* Máscara lateral (fade) */}
        <div className="absolute inset-0 z-10 pointer-events-none bg-gradient-to-r from-[#101012] via-transparent to-[#101012] opacity-70" />

        <div
          ref={stripRef}
          className="absolute top-0 left-0 flex items-center gap-[1.2rem] h-full will-change-transform"
          style={{ transform: `translateX(${offset}px)`, transition }}
          onTransitionEnd={handleTransitionEnd}
        >
          {reel.map((item) => (
            <ReelCard key={item.id} item={item} />
          ))}
        </div>
      </div>

      {/* Ações / resultado */}
      <div className="flex flex-col items-center gap-[1.2rem]">
        {phase === 'result' && won && (
          <div className="flex items-center gap-[1rem]">
            <span className="text-[1.6rem] font-medium text-[#f8efff] opacity-75">VOCÊ GANHOU</span>
            <span
              className="text-[1.6rem] font-bold"
              style={{ color: RARITY_COLOR[won.rarity] }}
            >
              {won.name}
            </span>
          </div>
        )}
        <button
          onClick={spin}
          disabled={phase === 'spinning'}
          className="flex items-center justify-center h-[5.2rem] px-[3.6rem] bg-[rgba(200,254,78,0.12)] border-2 border-[#c8fe4e] border-solid cursor-pointer transition-colors hover:bg-[rgba(200,254,78,0.22)] disabled:opacity-40 disabled:cursor-default"
        >
          <span className="text-[1.8rem] font-bold text-[#c8fe4e] whitespace-nowrap">
            {phase === 'spinning' ? 'ABRINDO...' : phase === 'result' ? 'ABRIR NOVAMENTE' : 'ABRIR CAIXA'}
          </span>
        </button>
      </div>
    </div>
  )
}

function ReelCard({ item }: { item: RouletteItem }) {
  return (
    <div className="flex flex-col items-center justify-center h-full w-[27.27rem] shrink-0">
      <div className="flex flex-col flex-1 min-h-0 gap-[0.6rem] pt-[0.4rem] px-[0.4rem] pb-[0.6rem] bg-[#312f37] w-full">
        <div className="relative flex-1 min-h-0 w-full border-2 border-[rgba(248,239,255,0.15)] border-solid overflow-hidden bg-gradient-to-b from-[#1e1f26] to-[#2b2b2b]">
          <img
            alt={item.name}
            src={item.image}
            className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 h-[70%] max-w-none object-contain pointer-events-none"
          />
          <div className="absolute left-0 right-0 bottom-0 flex items-center justify-center h-[3.1rem] px-[1rem] bg-[rgba(0,0,0,0.35)]">
            <span className="text-[1.2rem] font-medium text-[#f8efff] text-center whitespace-nowrap overflow-hidden text-ellipsis">
              {item.name}
            </span>
          </div>
        </div>
        <div className="flex items-center justify-center">
          <span className="text-[1.4rem] font-medium text-[#f8efff] whitespace-nowrap">ADQUIRIDO</span>
        </div>
      </div>
      {/* Divisor colorido pela raridade */}
      <div className="h-[1.2rem] w-full overflow-hidden">
        <DividerIcon width="100%" style={{ color: RARITY_COLOR[item.rarity] }} />
      </div>
    </div>
  )
}

/** Pequeno PRNG por chamada (evita Math.random no SSR/build determinístico). */
let seed = 0
function pseudoRandom() {
  // usa performance.now como fonte de variação em runtime
  seed = (seed + (typeof performance !== 'undefined' ? performance.now() : 1) * 9301 + 49297) % 233280
  return seed / 233280
}
