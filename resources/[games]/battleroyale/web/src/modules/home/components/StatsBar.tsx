import type { PhaseData } from '@/types/hud'
import {
  imgVector6,
  imgSubtract1,
  imgUnion4,
  imgVector7,
  imgVector8,
  imgFrame206,
  imgVector9,
  imgSubtract2,
} from '../assets'

const FALLBACK = {
  stats: { left: 40, top: 40, width: 276 },
  phase: { left: 40, top: 262, width: 279 },
}

interface MinimapFrame {
  x: number
  y: number
  w: number
  h: number
}

interface StatsBarProps {
  alivePlayers: number
  aliveSquads: number
  kills: number
  phase: PhaseData
  minimapFrame?: MinimapFrame | null
}

function computeLayout(frame: MinimapFrame | null | undefined) {
  if (!frame) return FALLBACK

  return {
    stats: { left: frame.x, top: frame.y, width: frame.w },
    phase: { left: frame.x, top: frame.y + frame.h + 4, width: frame.w },
  }
}

export default function StatsBar({ alivePlayers, aliveSquads, kills, phase, minimapFrame }: StatsBarProps) {
  const layout = computeLayout(minimapFrame)

  return (
    <>
      <div
        className="absolute content-stretch flex gap-[12px] items-center justify-center"
        style={{
          left: `${layout.stats.left}px`,
          top: `${layout.stats.top}px`,
          width: `${layout.stats.width}px`,
        }}
      >
        <div className="content-stretch flex flex-[1_0_0] flex-col h-[29px] items-start min-w-px relative">
          <div className="bg-[rgba(29,28,38,0.85)] content-stretch flex flex-[1_0_0] items-center justify-center min-h-px pt-[4px] px-[12px] relative w-full">
            <div className="content-stretch flex gap-[6px] items-start justify-end relative shrink-0">
              <div className="h-[12px] relative shrink-0 w-[6px]">
                <img
                  alt=""
                  className="absolute block inset-0 max-w-none size-full"
                  src={imgVector6}
                />
              </div>
              <div className="[word-break:break-word] flex flex-col font-['Termina:Demi',sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[12px] text-[color:var(--color-light,#f8efff)] text-center whitespace-nowrap">
                <p className="leading-[normal]">{alivePlayers}</p>
              </div>
            </div>
          </div>
          <div className="h-[7px] overflow-clip relative shrink-0 w-full">
            <div className="-translate-x-1/2 absolute h-[9px] left-[calc(50%+209.5px)] top-0 w-[1021px]">
              <img
                alt=""
                className="absolute block inset-0 max-w-none size-full"
                src={imgSubtract1}
              />
            </div>
          </div>
          <div className="-translate-y-1/2 absolute flex h-[14.952px] items-center justify-center left-[-4px] top-[calc(50%-0.02px)] w-[8.25px]">
            <div className="-rotate-90 -scale-y-100 flex-none">
              <div className="h-[8.25px] relative w-[14.952px]">
                <div className="absolute inset-[-12.12%_-6.69%]">
                  <img alt="" className="block max-w-none size-full" src={imgUnion4} />
                </div>
              </div>
            </div>
          </div>
        </div>
        <div className="content-stretch flex flex-[1_0_0] flex-col h-[29px] items-start min-w-px relative">
          <div className="bg-[rgba(29,28,38,0.85)] content-stretch flex flex-[1_0_0] items-center justify-center min-h-px pt-[4px] px-[12px] relative w-full">
            <div className="content-stretch flex gap-[6px] items-start justify-end relative shrink-0">
              <div className="h-[14px] relative shrink-0 w-[20px]">
                <img
                  alt=""
                  className="absolute block inset-0 max-w-none size-full"
                  src={imgVector7}
                />
              </div>
              <div className="[word-break:break-word] flex flex-col font-['Termina:Demi',sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[12px] text-[color:var(--color-light,#f8efff)] text-center whitespace-nowrap">
                <p className="leading-[normal]">{aliveSquads}</p>
              </div>
            </div>
          </div>
          <div className="h-[7px] overflow-clip relative shrink-0 w-full">
            <div className="-translate-x-1/2 absolute h-[9px] left-[calc(50%+207.5px)] top-0 w-[1021px]">
              <img
                alt=""
                className="absolute block inset-0 max-w-none size-full"
                src={imgSubtract1}
              />
            </div>
          </div>
          <div className="-translate-y-1/2 absolute flex h-[14.952px] items-center justify-center left-[-4px] top-[calc(50%-0.02px)] w-[8.25px]">
            <div className="-rotate-90 -scale-y-100 flex-none">
              <div className="h-[8.25px] relative w-[14.952px]">
                <div className="absolute inset-[-12.12%_-6.69%]">
                  <img alt="" className="block max-w-none size-full" src={imgUnion4} />
                </div>
              </div>
            </div>
          </div>
        </div>
        <div className="content-stretch flex flex-[1_0_0] flex-col h-[29px] items-start min-w-px relative">
          <div className="bg-[rgba(29,28,38,0.85)] content-stretch flex flex-[1_0_0] items-center justify-center min-h-px pt-[4px] px-[12px] relative w-full">
            <div className="content-stretch flex gap-[6px] items-start justify-end relative shrink-0">
              <div className="h-[13px] relative shrink-0 w-[11px]">
                <img
                  alt=""
                  className="absolute block inset-0 max-w-none size-full"
                  src={imgVector8}
                />
              </div>
              <div className="[word-break:break-word] flex flex-col font-['Termina:Demi',sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[12px] text-[color:var(--color-light,#f8efff)] text-center whitespace-nowrap">
                <p className="leading-[normal]">{kills}</p>
              </div>
            </div>
          </div>
          <div className="h-[7px] overflow-clip relative shrink-0 w-full">
            <div className="-translate-x-1/2 absolute h-[9px] left-[calc(50%+207.5px)] top-0 w-[1021px]">
              <img
                alt=""
                className="absolute block inset-0 max-w-none size-full"
                src={imgSubtract1}
              />
            </div>
          </div>
          <div className="-translate-y-1/2 absolute flex h-[14.952px] items-center justify-center left-[-4px] top-[calc(50%-0.02px)] w-[8.25px]">
            <div className="-rotate-90 -scale-y-100 flex-none">
              <div className="h-[8.25px] relative w-[14.952px]">
                <div className="absolute inset-[-12.12%_-6.69%]">
                  <img alt="" className="block max-w-none size-full" src={imgUnion4} />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div
        className="absolute content-stretch flex flex-col h-[33px] items-start"
        style={{
          left: `${layout.phase.left}px`,
          top: `${layout.phase.top}px`,
          width: `${layout.phase.width}px`,
        }}
      >
        <div className="bg-[rgba(29,28,38,0.86)] flex-[1_0_0] min-h-px relative w-full">
          <div className="absolute content-stretch flex flex-col h-[22px] items-start justify-between left-[8px] top-[2px]" style={{ width: `calc(100% - 16px)` }}>
            <div className="[word-break:break-word] content-stretch flex font-['Termina:Medium',sans-serif] items-center justify-between leading-[0] not-italic relative shrink-0 text-[10px] text-[color:var(--color-light,#f8efff)] w-full whitespace-nowrap">
              <div className="flex flex-col justify-center relative shrink-0">
                <p className="leading-[normal]">{phase.timer}</p>
              </div>
              <div className="flex flex-col justify-center relative shrink-0">
                <p>
                  <span className="leading-[normal]">{`FASE ${phase.phase} `}</span>
                  {/* <span className="leading-[normal] text-[rgba(248,239,255,0.55)]">{`/ `}</span> */}
                  {/* <span className="leading-[normal]">{phase.totalPhases}</span> */}
                </p>
              </div>
            </div>
            <div className="bg-[rgba(248,239,255,0.15)] h-[7px] relative shrink-0 w-full">
              <div
                className="absolute h-[7px] left-0 top-0 transition-all duration-500"
                style={{ width: `${phase.progress * 100}%` }}
              >
                <img
                  alt=""
                  className="absolute block inset-0 max-w-none size-full"
                  src={imgFrame206}
                />
              </div>
              <div className="-translate-y-1/2 absolute bg-[var(--color-light,#f8efff)] h-[7px] right-0 top-1/2 w-[5px]" />
              <div className="absolute h-[12px] right-[8px] top-[-3px] w-[6px]">
                <div className="absolute inset-[-33.33%_-66.67%]">
                  <img alt="" className="block max-w-none size-full" src={imgVector9} />
                </div>
              </div>
            </div>
          </div>
        </div>
        <div className="h-[7px] overflow-clip relative shrink-0 w-full">
          <div className="-translate-x-1/2 absolute h-[9px] left-[calc(50%-44px)] top-0 w-[1021px]">
            <img
              alt=""
              className="absolute block inset-0 max-w-none size-full"
              src={imgSubtract2}
            />
          </div>
        </div>
      </div>
    </>
  )
}
