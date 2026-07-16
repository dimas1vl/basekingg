import { imgFrame215, imgVector } from '../assets'

interface ReloadIndicatorProps {
  visible: boolean
}

// Indicador "REECARREGANDO" centralizado acima do hotbar (Figma 289:6564).
export default function ReloadIndicator({ visible }: ReloadIndicatorProps) {
  if (!visible) return null
  return (
    <div className="-translate-x-1/2 absolute bg-[rgba(29,28,38,0.85)] border-[#fedb4e] border-l-2 border-r-2 border-solid h-[24px] left-1/2 overflow-clip top-[917px] w-[42px]">
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
