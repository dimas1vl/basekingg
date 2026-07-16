import { fmtInt } from '@/utils/fmt'

interface LevelBarProps {
  level: number
  xpInto: number
  xpPer: number
}

// Barra de nível/XP logo abaixo do hotbar (Figma Frame 287).
export default function LevelBar({ level, xpInto, xpPer }: LevelBarProps) {
  const pct = xpPer > 0 ? Math.max(0, Math.min(100, (xpInto / xpPer) * 100)) : 0

  return (
    <div className="absolute content-stretch flex items-center justify-between left-[calc(37.5%+70px)] top-[1051px] w-[340px]">
      <div className="bg-[rgba(29,28,38,0.55)] content-stretch flex items-center justify-center p-[4px] relative shrink-0">
        <div className="flex flex-col font-['Termina:Demi',sans-serif] justify-center leading-[0] not-italic text-[10px] text-[color:var(--color-primary,#c8fe4e)] text-center whitespace-nowrap">
          <p className="leading-[normal]">NIVEL {level}</p>
        </div>
      </div>

      <div className="h-[8px] overflow-hidden relative shrink-0 w-[91px]" style={{ background: 'rgba(248,239,255,0.15)' }}>
        <div
          className="absolute left-0 top-0 h-full bg-[var(--color-primary,#c8fe4e)] transition-[width] duration-300"
          style={{ width: `${pct}%` }}
        />
      </div>

      <div className="bg-[rgba(29,28,38,0.55)] content-stretch flex items-center justify-center p-[4px] relative shrink-0">
        <div className="flex flex-col font-['Termina:Demi',sans-serif] justify-center leading-[0] not-italic text-[10px] text-[rgba(248,239,255,0.75)] text-right whitespace-nowrap">
          <p className="leading-[normal]">XP - {fmtInt(xpInto)} / {fmtInt(xpPer)}</p>
        </div>
      </div>
    </div>
  )
}
