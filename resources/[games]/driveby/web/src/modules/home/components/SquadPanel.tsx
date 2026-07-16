import type { SquadMember } from '@/types/hud'
import {
  imgSquad,
  imgSquad1,
  imgVector1,
  imgVector2,
  imgSubtract,
  imgSpeakerHigh,
  imgSpeakerHigh1,
  imgUnion1,
} from '../assets'

interface SquadPanelProps {
  squad: SquadMember[]
}

function squadBorderColor(m: SquadMember) {
  return !m.alive ? 'rgba(29,28,38,0.85)' : m.health < 25 ? '#ff5858' : 'rgba(248,239,255,0.55)'
}

export default function SquadPanel({ squad }: SquadPanelProps) {
  return (
    <div className="absolute bottom-[35px] content-stretch flex flex-col gap-[8px] items-start left-[40px] w-[225px]">
      {squad.map((member) => {
        const borderColor = squadBorderColor(member)
        const isLowHealth = member.health < 30
        const healthColor = isLowHealth ? '#ff5b5b' : '#f8efff'
        const healthBorder = isLowHealth ? '#ff9696' : '#f8efff'
        return (
          <div
            key={member.slot}
            className="content-stretch flex gap-[4px] items-start relative shrink-0 w-full"
          >
            <div
              className="border-2 border-solid relative shrink-0 size-[36px] overflow-clip"
              style={{ borderColor }}
            >
              {member.alive ? (
                <div className="absolute inset-0 overflow-hidden pointer-events-none">
                  <img
                    alt=""
                    className="absolute h-[203.17%] left-[-7.14%] max-w-none top-[-2.47%] w-[114.29%]"
                    src={imgSquad}
                  />
                </div>
              ) : (
                <>
                  <img
                    alt=""
                    className="absolute inset-0 max-w-none object-bottom pointer-events-none size-full"
                    src={imgSquad1}
                  />
                  <div className="-translate-x-1/2 -translate-y-1/2 absolute h-[22px] left-1/2 top-1/2 w-[18px]">
                    <img
                      alt=""
                      className="absolute block inset-0 max-w-none size-full"
                      src={imgVector2}
                    />
                  </div>
                </>
              )}
            </div>

            <div
              className={`content-stretch flex flex-[1_0_0] flex-col items-start min-w-px relative ${!member.alive ? 'opacity-55' : ''}`}
            >
              <div className="content-stretch flex h-[18px] items-center relative shrink-0 w-full">
                <div
                  className="content-stretch flex flex-col items-center justify-center overflow-clip px-[9px] py-[5px] relative shrink-0 size-[18px]"
                  style={{ backgroundColor: member.badgeColor }}
                >
                  <div className="[word-break:break-word] flex flex-col font-['Termina:Demi',sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[10px] text-[color:var(--color-light,#f8efff)] text-center w-full">
                    <p className="leading-[normal]">{member.slot}</p>
                  </div>
                </div>
                <div className="content-stretch flex h-full items-center justify-between px-[4px] relative shrink-0 w-[167px]">
                  <div className="-translate-x-1/2 absolute h-[18px] left-1/2 top-0 w-[167px]">
                    <img
                      alt=""
                      className="absolute block inset-0 max-w-none size-full"
                      src={imgSubtract}
                    />
                  </div>
                  <div className="content-stretch flex gap-[4px] items-center relative shrink-0">
                    <div
                      className="[word-break:break-word] flex flex-col font-['Termina:Medium',sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[10px] text-center whitespace-nowrap"
                      style={{ color: isLowHealth && member.alive ? '#ff5858' : '#f8efff' }}
                    >
                      <p className="leading-[normal]">{member.name}</p>
                    </div>
                    {member.speaking && (
                      <div className="h-[16px] relative shrink-0 w-[20px]">
                        <img
                          alt=""
                          className="absolute block inset-0 max-w-none size-full"
                          src={imgSpeakerHigh1}
                        />
                      </div>
                    )}
                  </div>
                  <div className="relative shrink-0 size-[16px]">
                    <img
                      alt=""
                      className="absolute block inset-0 max-w-none size-full"
                      src={imgSpeakerHigh}
                    />
                  </div>
                  <div className="absolute h-[6px] left-[126px] top-[-3px] w-[15px]">
                    <div className="absolute inset-[-16.67%_-6.67%]">
                      <img alt="" className="block max-w-none size-full" src={imgUnion1} />
                    </div>
                  </div>
                </div>
              </div>

              <div className="content-stretch flex flex-col gap-[2px] items-start relative shrink-0 w-full">
                <div className="bg-[rgba(29,28,38,0.85)] h-[4px] opacity-45 overflow-clip relative shrink-0 w-full">
                  <div
                    className="absolute bg-[var(--color-light,#f8efff)] h-[6px] left-0 top-0 transition-all duration-300"
                    style={{ width: `${member.armor}%` }}
                  />
                </div>
                <div
                  className="border-l-[3px] border-r-[3px] border-solid h-[12px] overflow-clip relative shrink-0 w-full"
                  style={{ backgroundColor: 'rgba(29,28,38,0.45)', borderColor: healthBorder }}
                >
                  <div
                    className="absolute h-[18px] left-0 top-0 transition-all duration-300"
                    style={{ width: `${member.health}%`, backgroundColor: healthColor }}
                  />
                  <div className="absolute flex h-[776px] items-center justify-center left-[-68px] top-[-151px] w-[577px]">
                    <div className="-scale-y-100 flex-none rotate-180">
                      <div className="h-[776px] relative w-[577px]">
                        <div className="absolute inset-[-1.8%_-2.43%]">
                          <img alt="" className="block max-w-none size-full" src={imgVector1} />
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )
      })}
    </div>
  )
}
