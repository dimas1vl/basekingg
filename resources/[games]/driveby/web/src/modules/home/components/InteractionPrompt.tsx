import type { InteractionData } from '@/types/hud'
import { imgUnion6 } from '../assets'

interface InteractionPromptProps {
  interaction: InteractionData
}

export default function InteractionPrompt({ interaction }: InteractionPromptProps) {
  if (!interaction.visible) return null

  return (
    <div className="-translate-x-1/2 absolute content-stretch flex flex-col items-end justify-center left-[calc(56.25%-26px)] top-[503px] w-[186px]">
      <div className="content-stretch flex h-[20px] items-start justify-end opacity-85 relative shrink-0">
        <div className="bg-[var(--color-primary,#c8fe4e)] content-stretch flex flex-col items-center justify-center overflow-clip px-[4px] py-[3px] relative shrink-0 w-[20px]">
          <div className="[word-break:break-word] flex flex-col font-['Termina:Medium',sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[12px] text-[color:var(--color-background,#1d1c26)] text-center whitespace-nowrap">
            <p className="leading-[normal]">{interaction.key}</p>
          </div>
        </div>
        <div className="bg-[var(--color-background,#1d1c26)] content-stretch flex h-full items-center overflow-clip px-[10px] py-[5px] relative shrink-0 w-[166px]">
          <div className="[word-break:break-word] flex flex-col font-['Termina:Medium',sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[10px] text-[color:var(--color-light,#f8efff)] text-center whitespace-nowrap">
            <p className="leading-[normal]">{interaction.action}</p>
          </div>
        </div>
      </div>
      <div className="content-stretch flex flex-col items-start pl-[20px] relative shrink-0 w-full">
        <div className="bg-[rgba(29,28,38,0.65)] content-stretch flex h-[20px] items-center justify-between px-[10px] py-[5px] relative shrink-0 w-full">
          <div className="[word-break:break-word] flex flex-col font-['Termina:Medium',sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[10px] text-[rgba(248,239,255,0.55)] text-center whitespace-nowrap">
            <p className="leading-[normal]">{interaction.detail}</p>
          </div>
          <div className="[word-break:break-word] flex flex-col font-['Termina:Medium',sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[10px] text-[rgba(248,239,255,0.55)] text-center whitespace-nowrap">
            <p className="leading-[normal]">{interaction.detailValue}</p>
          </div>
          <div className="-translate-y-1/2 absolute flex h-[7px] items-center justify-center left-[110px] top-[calc(50%+10.5px)] w-[19px]">
            <div className="flex-none rotate-180">
              <div className="h-[7px] relative w-[19px]">
                <div className="absolute inset-[-14.29%_-5.26%]">
                  <img alt="" className="block max-w-none size-full" src={imgUnion6} />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
