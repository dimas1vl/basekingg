interface BottomBarProps {
  progress: number // 0-1
}

// Barra fina full-width no rodapé da tela (Figma Frame 162).
export default function BottomBar({ progress }: BottomBarProps) {
  const pct = Math.max(0, Math.min(100, progress * 100))
  return (
    <div className="-translate-x-1/2 absolute bg-[rgba(29,28,38,0.85)] bottom-0 h-[3px] left-1/2 overflow-clip w-[1920px]">
      <div
        className="-translate-y-1/2 absolute bg-[var(--color-light,#f8efff)] h-[6px] left-0 top-[calc(50%+0.5px)] transition-[width] duration-500"
        style={{ width: `${pct}%` }}
      />
    </div>
  )
}
