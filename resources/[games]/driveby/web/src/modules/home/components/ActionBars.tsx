import type { ActionData } from '@/types/hud'
import { imgFrame215, imgVector, imgFrame215Medkit } from '../assets'

interface ActionBarsProps {
  action: ActionData
}

function ReloadIndicator() {
  return (
    <div className="bg-[rgba(29,28,38,0.85)] border-[#fedb4e] border-l-2 border-r-2 border-solid h-[24px] overflow-clip relative w-[42px]">
      <div className="-translate-x-1/2 -translate-y-1/2 absolute bg-[var(--color-light,#f8efff)] h-[24px] left-1/2 top-1/2 w-px" />
      <div className="-translate-x-1/2 -translate-y-1/2 absolute h-[24px] left-1/2 top-1/2 w-[38px]">
        <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgFrame215} />
      </div>
      <div className="-translate-x-1/2 -translate-y-1/2 absolute h-[14px] left-1/2 mix-blend-difference top-1/2 w-[16px]">
        <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgVector} />
      </div>
    </div>
  )
}

function MedicalKitBar({
  className,
  text,
  cancelKey,
  progress,
}: {
  className?: string
  text: string
  cancelKey: string
  progress: number
}) {
  const fillWidth = Math.round(2 + Math.min(1, Math.max(0, progress)) * 196)

  return (
    <div
      className={
        className ??
        'bg-[rgba(29,28,38,0.85)] border-[var(--color-primary,#c8fe4e)] border-l-2 border-r-2 border-solid h-[24px] relative w-[202px]'
      }
    >
      <div className="absolute h-[24px] left-0 top-0 w-[198px]">
        <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgFrame215Medkit} />
      </div>
      <div
        className="-translate-x-1/2 -translate-y-1/2 absolute bg-[var(--color-light,#f8efff)] h-[24px] left-1/2 top-1/2"
        style={{ width: fillWidth, transition: 'width 0.15s linear' }}
      />
      <div className="-translate-x-1/2 -translate-y-1/2 [word-break:break-word] absolute flex flex-col font-['Termina:Medium',sans-serif] justify-center leading-[0] left-1/2 mix-blend-difference not-italic text-[12px] text-[color:var(--color-light,#f8efff)] text-center top-1/2 whitespace-nowrap">
        <p className="leading-[normal]">{text}</p>
      </div>
      <div className="-translate-x-1/2 -translate-y-1/2 [word-break:break-word] absolute flex flex-col font-['Termina:Medium',sans-serif] justify-center leading-[0] left-[calc(50%+0.5px)] not-italic text-[10px] text-[color:var(--color-light,#f8efff)] text-center top-[31px] whitespace-nowrap">
        <p>
          <span className="[word-break:break-word] font-['Termina:Heavy',sans-serif] leading-[normal] not-italic">
            {cancelKey}
          </span>
          <span className="leading-[normal]">{` PARA CANCELAR`}</span>
        </p>
      </div>
    </div>
  )
}

export default function ActionBars({ action }: ActionBarsProps) {
  if (!action.visible) return null

  return (
    <>
      {action.type === 'medkit' && (
        <MedicalKitBar
          text={action.text}
          cancelKey={action.cancelKey}
          progress={action.progress}
          className="absolute bg-[rgba(29,28,38,0.85)] border-[var(--color-primary,#c8fe4e)] border-l-2 border-r-2 border-solid h-[24px] left-[calc(37.5%+139px)] top-[720px] w-[202px]"
        />
      )}
      {action.type === 'reload' && (
        <div className="-translate-x-1/2 absolute left-1/2 top-[913px]">
          <ReloadIndicator />
        </div>
      )}
    </>
  )
}
