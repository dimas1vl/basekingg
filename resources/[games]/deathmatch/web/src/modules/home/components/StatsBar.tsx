import {
  imgVector12,
  imgUnion3,
  imgSubtract1,
  imgUnion4,
  imgVector6,
  imgVector8,
  imgAssistsIcon,
  imgStatArrowAssists,
} from '../assets'

interface StatsBarProps {
  kills: number
  killStreak: number
  players: number
}

function StatItem({ icon, iconSize, value, arrow = imgUnion4 }: { icon: string; iconSize: { w: string; h: string }; value: number; arrow?: string }) {
  return (
    <div className="content-stretch flex flex-[1_0_0] flex-col h-[29px] items-start min-w-px relative">
      <div className="bg-[rgba(29,28,38,0.85)] content-stretch flex flex-[1_0_0] items-center justify-center min-h-px pt-[4px] px-[12px] relative w-full">
        <div className="content-stretch flex gap-[6px] items-center relative shrink-0">
          <div className={`${iconSize.h} relative shrink-0 ${iconSize.w}`}>
            <img alt="" className="absolute block inset-0 max-w-none size-full" src={icon} />
          </div>
          <div className="[word-break:break-word] flex flex-col font-['Termina:Demi',sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[12px] text-[color:var(--color-light,#f8efff)] text-center whitespace-nowrap">
            <p className="leading-[normal]">{value}</p>
          </div>
        </div>
      </div>
      <div className="h-[7px] overflow-clip relative shrink-0 w-full">
        <div className="-translate-x-1/2 absolute h-[9px] left-[calc(50%+207.5px)] top-0 w-[1021px]">
          <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgSubtract1} />
        </div>
      </div>
      <div className="-translate-y-1/2 absolute flex h-[14.952px] items-center justify-center left-[-4px] top-[calc(50%-0.02px)] w-[8.25px]">
        <div className="-rotate-90 -scale-y-100 flex-none">
          <div className="h-[8.25px] relative w-[14.952px]">
            <div className="absolute inset-[-12.12%_-6.69%]">
              <img alt="" className="block max-w-none size-full" src={arrow} />
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

export default function StatsBar({ kills, killStreak, players }: StatsBarProps) {
  return (
    <>
      <div className="absolute content-stretch flex gap-[12px] items-center justify-center right-[calc(75%+164px)] top-[40px] w-[207px]">
        <StatItem icon={imgVector8} iconSize={{ w: 'w-[11px]', h: 'h-[13px]' }} value={kills} />
        <StatItem icon={imgAssistsIcon} iconSize={{ w: 'w-[9px]', h: 'h-[14px]' }} value={killStreak} arrow={imgStatArrowAssists} />
        <StatItem icon={imgVector6} iconSize={{ w: 'w-[6px]', h: 'h-[12px]' }} value={players} />
      </div>
    </>
  )
}
