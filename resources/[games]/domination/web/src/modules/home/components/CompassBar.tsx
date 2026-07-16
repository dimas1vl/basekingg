import { imgEllipse4, imgFrame198, imgVector10 } from '../assets'

const PX_PER_DEG = 2.4
const FULL_W     = Math.round(360 * PX_PER_DEG)
const COPIES     = 3

type Mark = {
  deg: number
  x:   number
  kind: 'cardinal' | 'inter' | 'ten' | 'five'
  label?: string
}

const CARD: Record<number, string> = {
  0: 'N', 45: 'NE', 90: 'L', 135: 'SE', 180: 'S', 225: 'SO', 270: 'O', 315: 'NO',
}

const BASE_MARKS: Mark[] = []
for (let d = 0; d < 360; d += 5) {
  const x = d * PX_PER_DEG
  const label = CARD[d]
  const kind = label
    ? d % 90 === 0 ? 'cardinal' : 'inter'
    : d % 10 === 0 ? 'ten' : 'five'
  BASE_MARKS.push({ deg: d, x, kind, label })
}

interface CompassBarProps {
  heading: number // 0–359
}

export default function CompassBar({ heading }: CompassBarProps) {
  const raw = ((heading * PX_PER_DEG) % FULL_W + FULL_W) % FULL_W
  const translateX = -(FULL_W + raw - 220)

  return (
    <>
      <div className="absolute h-[26px] left-[calc(37.5%+20px)] top-[14px] w-[440px]">

        <div className="-translate-x-1/2 -translate-y-1/2 absolute h-[40px] left-[calc(50%+0.5px)] top-[calc(50%-42px)] w-[695px]">
          <div className="absolute inset-[-190%_-10.94%]">
            <img alt="" className="block max-w-none size-full" src={imgEllipse4} />
          </div>
        </div>

        <div
          className="absolute inset-0 overflow-hidden"
          style={{
            maskImage:
              'linear-gradient(to right, transparent 0%, white 12%, white 88%, transparent 100%)',
            maskRepeat: 'no-repeat',
          }}
        >
          <svg
            height="26"
            style={{
              width: FULL_W * COPIES,
              transform: `translateX(${translateX}px)`,
              transition: 'transform 0.1s linear',
              display: 'block',
              overflow: 'visible',
            }}
            viewBox={`0 0 ${FULL_W * COPIES} 26`}
            fill="none"
          >
            {Array.from({ length: COPIES }, (_, copy) =>
              BASE_MARKS.map(({ deg, x: bx, kind, label }) => {
                const x = copy * FULL_W + bx

                if (kind === 'cardinal') return (
                  <g key={`${copy}-${deg}`}>
                    <line x1={x} y1={10} x2={x} y2={26} stroke="#f8efff" strokeWidth="1.2" opacity="0.95" />
                    <text x={x} y={8} fontSize="8" fontFamily="Rajdhani,sans-serif" fontWeight="700"
                      textAnchor="middle" fill="#c8fe4e" opacity="1">{label}</text>
                  </g>
                )

                if (kind === 'inter') return (
                  <g key={`${copy}-${deg}`}>
                    <line x1={x} y1={14} x2={x} y2={26} stroke="#f8efff" strokeWidth="1" opacity="0.75" />
                    <text x={x} y={10} fontSize="6.5" fontFamily="Rajdhani,sans-serif" fontWeight="600"
                      textAnchor="middle" fill="#f8efff" opacity="0.75">{label}</text>
                  </g>
                )

                if (kind === 'ten') return (
                  <line key={`${copy}-${deg}`}
                    x1={x} y1={18} x2={x} y2={26} stroke="#f8efff" strokeWidth="0.8" opacity="0.5" />
                )

                return (
                  <line key={`${copy}-${deg}`}
                    x1={x} y1={21} x2={x} y2={26} stroke="#f8efff" strokeWidth="0.6" opacity="0.3" />
                )
              })
            )}
          </svg>
        </div>

        <div className="absolute left-1/2 -translate-x-1/2 top-0" style={{ pointerEvents: 'none' }}>
          <svg width="8" height="7" viewBox="0 0 8 7">
            <polygon points="4,7 0,0 8,0" fill="#c8fe4e" opacity="0.95" />
          </svg>
        </div>

        <div className="-translate-x-1/2 absolute bg-[rgba(29,28,38,0.85)] content-stretch flex flex-col gap-[10px] h-[20px] items-center justify-center left-1/2 pb-px pt-[2px] px-[4px] top-[29px] w-[40px]">
          <div className="[word-break:break-word] flex flex-col font-['Termina:Medium',sans-serif] justify-center leading-[0] min-w-full not-italic relative shrink-0 text-[12px] text-[color:var(--color-light,#f8efff)] text-center w-[min-content]">
            <p className="leading-[normal]">{Math.round(heading)}</p>
          </div>
          <div className="-translate-x-1/2 absolute h-[9px] left-[calc(50%-0.5px)] top-[-5px] w-[12px]">
            <div className="absolute inset-[0_-0.42%_0_-0.17%]">
              <img alt="" className="block max-w-none size-full" src={imgFrame198} />
            </div>
          </div>
        </div>
      </div>

      <div className="-translate-x-1/2 absolute h-[11.19px] left-[calc(50%+0.43px)] top-[77px] w-[212.857px]">
        <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgVector10} />
      </div>
    </>
  )
}
