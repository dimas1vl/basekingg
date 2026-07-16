import imgFooterDecor from '@/assets/minigames/footer-decor.svg'
import { useHudScale } from '@/hooks/useHudScale'

export default function HHintHud() {
  const { scale, offsetX, offsetY } = useHudScale()

  return (
    <div
      className="absolute top-0 left-0 pointer-events-none"
      style={{
        width: '1920px',
        height: '1080px',
        fontSize: '16px',
        transformOrigin: 'top left',
        transform: `translate(${offsetX}px, ${offsetY}px) scale(${scale})`,
      }}
    >
      <div className="absolute left-1/2 -translate-x-1/2" style={{ top: '1016px', width: '278px' }}>
        <div className="bg-[rgba(29,28,38,0.85)] flex items-center justify-center h-[22px] px-3 pt-1">
          <p className="font-termina font-semibold text-[12px] text-[#f8efff] text-center whitespace-nowrap">
            H{' '}
            <span className="font-medium text-[rgba(248,239,255,0.65)]">- VOLTAR AO MENU PRINCIPAL</span>
          </p>
        </div>
        <div className="h-[7px] overflow-hidden relative w-full">
          <div
            className="absolute top-0"
            style={{ left: 'calc(50% + 207.5px)', transform: 'translateX(-50%)', width: '1021px', height: '9px' }}
          >
            <img alt="" className="w-full h-full" src={imgFooterDecor} />
          </div>
        </div>
      </div>
    </div>
  )
}
