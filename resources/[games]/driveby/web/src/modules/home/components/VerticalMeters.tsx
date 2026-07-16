import { imgGraus, imgFrame210, imgUnion5, imgFrame199, imgGraus1, imgFrame200 } from '../assets'

interface VerticalMetersProps {
  distance: number
  distanceLabel: string
  vehicleSpeed: number
}

function clamp(v: number, min: number, max: number) {
  return Math.max(min, Math.min(max, v))
}

export default function VerticalMeters({
  distance,
  distanceLabel,
  vehicleSpeed,
}: VerticalMetersProps) {
  const leftCalloutTop = Math.round(329 - (clamp(distance, 0, 500) / 500) * 314)
  const rightCalloutTop = Math.round(295 - (clamp(vehicleSpeed, 0, 250) / 250) * 280)

  const leftBarY = clamp(leftCalloutTop, 5, 329)
  const leftBarPath = `M14 ${leftBarY}L7.97949 ${leftBarY + 6}L14 ${leftBarY + 12}V341H0V0H14V${leftBarY}Z`
  const rightBarY = clamp(rightCalloutTop, 5, 325)
  const rightBarPath = `M14 337H0V${rightBarY + 12}L6.0625 ${rightBarY + 6}L0 ${rightBarY}V0H14V337Z`

  return (
    <div className="-translate-x-1/2 -translate-y-1/2 absolute content-stretch flex items-center justify-between left-[calc(50%+0.5px)] top-[calc(50%+0.5px)] w-[827px]">
      <div className="border-[var(--color-primary,#c8fe4e)] border-b-2 border-solid border-t-2 h-[341px] relative shrink-0 w-[14px]">
        <div className="absolute h-[289px] left-0 top-0 w-[14px]">
          <svg
            preserveAspectRatio="none"
            width="100%"
            height="100%"
            overflow="visible"
            style={{ display: 'block' }}
            viewBox="0 0 14 289"
          >
            <path
              d={leftBarPath}
              fill="rgba(29,28,38,0.85)"
              style={{ transition: 'd 0.6s cubic-bezier(0.4,0,0.2,1)' }}
            />
          </svg>
        </div>
        <div className="absolute flex h-[291px] items-center justify-center left-0 top-[-2px] w-[12px]">
          <div className="-rotate-90 flex-none">
            <div className="h-[12px] relative w-[291px]">
              <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgGraus} />
            </div>
          </div>
        </div>
        <div className="absolute bottom-0 h-[48px] left-0 w-[14px]">
          <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgFrame210} />
        </div>
        <div className="-translate-x-1/2 absolute bottom-[46px] h-[4px] left-1/2 w-[24px]">
          <div className="absolute inset-[-10%_-1.67%]">
            <img alt="" className="block max-w-none size-full" src={imgUnion5} />
          </div>
        </div>
        <div
          className="absolute content-stretch flex items-center right-[-80px]"
          style={{ top: leftCalloutTop, transition: 'top 0.6s cubic-bezier(0.4,0,0.2,1)' }}
        >
          <div className="flex h-[8px] items-center justify-center relative shrink-0 w-[7px]">
            <div className="-rotate-90 flex-none">
              <div className="h-[7px] relative w-[8px]">
                <div className="absolute inset-[0_-6.64%_0_-6.27%]">
                  <img alt="" className="block max-w-none size-full" src={imgFrame199} />
                </div>
              </div>
            </div>
          </div>
          <div className="bg-[var(--color-primary,#c8fe4e)] content-stretch flex flex-col items-center justify-center px-[2px] relative shrink-0">
            <div className="[word-break:break-word] flex flex-col font-['Termina:Medium',sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[10px] text-[color:var(--color-background,#1d1c26)] text-center w-full">
              <p className="leading-[normal]">{distance}</p>
            </div>
          </div>
          <div className="bg-[rgba(29,28,38,0.85)] content-stretch flex flex-col h-full items-center justify-center px-[2px] relative shrink-0">
            <div className="[word-break:break-word] flex flex-col font-['Termina:Medium',sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[8px] text-[color:var(--color-light,#f8efff)] text-center w-full">
              <p className="leading-[normal]">METROS</p>
            </div>
          </div>
        </div>
        <div className="-translate-x-1/2 -translate-y-1/2 [word-break:break-word] absolute flex flex-col font-['Termina:Medium',sans-serif] justify-center leading-[0] left-[-27px] not-italic text-[10px] text-[color:var(--color-light,#f8efff)] text-center top-[289px] whitespace-nowrap">
          <p className="leading-[normal]">{distanceLabel}</p>
        </div>
      </div>

      <div className="border-[var(--color-light,#f8efff)] border-b-2 border-solid border-t-2 h-[341px] relative shrink-0 w-[14px]">
        <div className="absolute h-[337px] left-0 top-0 w-[14px]">
          <svg
            preserveAspectRatio="none"
            width="100%"
            height="100%"
            overflow="visible"
            style={{ display: 'block' }}
            viewBox="0 0 14 337"
          >
            <path
              d={rightBarPath}
              fill="rgba(29,28,38,0.85)"
              style={{ transition: 'd 0.4s cubic-bezier(0.4,0,0.2,1)' }}
            />
          </svg>
        </div>
        <div className="absolute flex h-[341px] items-center justify-center right-0 top-[-2px] w-[12px]">
          <div className="-rotate-90 -scale-y-100 flex-none">
            <div className="h-[12px] relative w-[341px]">
              <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgGraus1} />
            </div>
          </div>
        </div>
        <div
          className="absolute content-stretch flex items-center left-[-80px]"
          style={{ top: rightCalloutTop, transition: 'top 0.4s cubic-bezier(0.4,0,0.2,1)' }}
        >
          <div className="bg-[var(--color-primary,#c8fe4e)] content-stretch flex flex-col items-center justify-center px-[2px] relative shrink-0">
            <div className="[word-break:break-word] flex flex-col font-['Termina:Medium',sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[10px] text-[color:var(--color-background,#1d1c26)] text-center w-full">
              <p className="leading-[normal]">{vehicleSpeed}</p>
            </div>
          </div>
          <div className="bg-[rgba(29,28,38,0.85)] content-stretch flex flex-col h-full items-center justify-center px-[2px] relative shrink-0">
            <div className="[word-break:break-word] flex flex-col font-['Termina:Medium',sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[8px] text-[color:var(--color-light,#f8efff)] text-center w-full">
              <p className="leading-[normal]">KMH</p>
            </div>
          </div>
          <div className="h-[8px] relative shrink-0 w-[13px]">
            <div className="-translate-y-1/2 absolute flex h-[8px] items-center justify-center left-0 top-1/2 w-[7px]">
              <div className="-rotate-90 -scale-y-100 flex-none">
                <div className="h-[7px] relative w-[8px]">
                  <div className="absolute inset-[0_-6.64%_0_-6.27%]">
                    <img alt="" className="block max-w-none size-full" src={imgFrame200} />
                  </div>
                </div>
              </div>
            </div>
            <div className="-translate-y-1/2 absolute flex h-[8px] items-center justify-center left-[6px] top-1/2 w-[7px]">
              <div className="-rotate-90 -scale-y-100 flex-none">
                <div className="h-[7px] relative w-[8px]">
                  <div className="absolute inset-[0_-6.64%_0_-6.27%]">
                    <img alt="" className="block max-w-none size-full" src={imgFrame200} />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
