import type { KillEntry } from '@/types/hud'
import {
  imgWeaponCarbinerifleMk23,
  imgUnion7,
  imgFrame220,
  imgFrame221,
  imgFrame222,
} from '../assets'

interface KillFeedProps {
  entries: KillEntry[]
}

function killFeedFrame(e: KillEntry) {
  return e.killerIsTeam ? imgFrame220 : e.victimIsTeam ? imgFrame222 : imgFrame221
}

export default function KillFeed({ entries }: KillFeedProps) {
  return (
    <div className="absolute content-stretch flex flex-col gap-[6px] items-start right-[33px] top-[56px] w-[359px]">
      {entries.map((entry) => {
        const isGreen = entry.killerIsTeam && !entry.victimIsTeam
        const isRed = entry.victimIsTeam && !entry.killerIsTeam
        const frame = killFeedFrame(entry)
        return (
          <div
            key={entry.id}
            className="content-stretch flex h-[22px] items-center justify-end relative shrink-0 w-full"
          >
            <div
              className={`bg-[rgba(29,28,38,0.7)] content-stretch flex h-full items-center justify-end px-[16px] relative shrink-0 ${isGreen ? 'border border-[var(--color-primary,#c8fe4e)] border-solid' : isRed ? 'border border-[#ff5858] border-solid' : ''}`}
            >
              <div className="content-stretch flex gap-[12px] items-center justify-end relative shrink-0">
                <div
                  className="[word-break:break-word] flex flex-col font-['Termina:Demi',sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[10px] text-center whitespace-nowrap"
                  style={{ color: isGreen ? 'var(--color-primary,#c8fe4e)' : '#f8efff' }}
                >
                  <p className="leading-[normal]">{entry.killer}</p>
                </div>
                <div className="h-[10.794px] relative shrink-0 w-[31.934px]">
                  <img
                    alt=""
                    className="absolute inset-0 max-w-none object-bottom pointer-events-none size-full"
                    src={imgWeaponCarbinerifleMk23}
                  />
                </div>
                <div className="h-[10px] relative shrink-0 w-[17.839px]">
                  <img
                    alt=""
                    className="absolute block inset-0 max-w-none size-full"
                    src={imgUnion7}
                  />
                </div>
                <div
                  className="[word-break:break-word] flex flex-col font-['Termina:Demi',sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[10px] text-center whitespace-nowrap"
                  style={{
                    color: isRed
                      ? '#ff5858'
                      : isGreen && entry.victimIsTeam
                        ? 'var(--color-primary,#c8fe4e)'
                        : '#f8efff',
                  }}
                >
                  <p className="leading-[normal]">{entry.victim}</p>
                </div>
              </div>
            </div>
            <div className="h-full relative shrink-0 w-[13px]">
              <div className="absolute inset-[0_-1.75%_0_-29.02%]">
                <img alt="" className="block max-w-none size-full" src={frame} />
              </div>
            </div>
          </div>
        )
      })}
    </div>
  )
}
