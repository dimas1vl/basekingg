import { ArrowStylizedLeftIcon, SlashesIcon } from '@/components/icons'

type SwitchHeaderProps = {
  onBack: () => void
  title?: string
  subtitle?: string
}

export function SwitchHeader({
  onBack,
  title = 'MODOS DE JOGO',
  subtitle = 'SELECIONE UMA CATEGORIA PARA VER OS MODOS RELACIONADOS',
}: SwitchHeaderProps) {
  return (
    <div className="flex flex-col shrink-0">
      <div className="relative flex items-center gap-[3.2rem] bg-[rgba(248,239,255,0.05)] border-l-8 border-solid border-[#f8efff] pl-[3.6rem] pr-[3.2rem] py-[1.2rem]">
        <button
          onClick={onBack}
          onMouseEnter={(e) => {
            const el = e.currentTarget
            el.style.backgroundColor = '#c8fe4e'
            el.style.width = '5rem'
            el.style.border = '2px solid rgba(248,239,255,0.55)'
          }}
          onMouseLeave={(e) => {
            const el = e.currentTarget
            el.style.backgroundColor = '#f8efff'
            el.style.width = '4.4rem'
            el.style.border = 'none'
          }}
          className="absolute left-[-5.8rem] top-0 h-full flex items-center justify-center cursor-pointer overflow-hidden transition-[width,background-color] duration-200"
          style={{ width: '4.4rem', backgroundColor: '#f8efff' }}
        >
          <ArrowStylizedLeftIcon width={24} height={27} className="text-[#1d1c26]" />
        </button>
        <div className="absolute left-[-4.8rem] top-[-2.1rem] opacity-35">
          <span className="text-[1rem] font-semibold text-[#f8efff]">VOLTAR</span>
        </div>
        <span className="text-[2.4rem] font-bold text-[#f8efff] whitespace-nowrap">{title}</span>
        <SlashesIcon width={50} height={20} className="text-[#f8efff] shrink-0" />
      </div>
      {subtitle.length > 0 && (
        <>
          <div className="bg-black/25 px-[3.6rem] py-[0.8rem]">
            <span className="text-[1.2rem] font-medium text-[#f8efff] opacity-75 whitespace-nowrap">
              {subtitle}
            </span>
          </div>
        </>
      )}
    </div>
  )
}
