import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { SwitchHeader } from '@/modules/home/switchMode/components/switch-header'
import { ArrowStylizedLeftIcon, SlashesIcon } from '@/components/icons'
import { fetchData } from '@/utils/fetchData'
import { CAIXAS_BG, MOCK_BOXES, type Box } from './data'
import { BoxCard } from './components/box-card'
import { CaseRoulette } from './components/case-roulette'

export default function CaixasPage() {
  const navigate = useNavigate()
  const [opening, setOpening] = useState<Box | null>(null)

  const openBox = (box: Box) => {
    setOpening(box)
    fetchData('openBox', { boxId: box.id })
  }

  if (opening) {
    return <RouletteView box={opening} onBack={() => setOpening(null)} />
  }

  return (
    <div className="relative flex flex-col w-full h-full overflow-hidden">
      <div className="absolute inset-0 -z-10 bg-[#101012]" />
      <div
        className="absolute inset-0 -z-10"
        style={{
          background:
            'radial-gradient(115rem 65rem at 50% 40%, rgba(29,28,34,0.9) 0%, rgba(29,28,34,0) 70%)',
        }}
      />

      <div className="flex flex-col gap-[2.4rem] w-full h-full p-[5rem] min-h-0">
        <SwitchHeader title="CAIXAS" subtitle="" onBack={() => navigate('/')} />

        {/* Painel */}
        <div className="flex flex-col flex-1 min-h-0 p-[0.2rem] border-2 border-[#4d4c55] border-solid">
          <div className="flex h-[6.9rem] items-center justify-between px-[2.4rem] py-[0.8rem] bg-[rgba(29,28,38,0.85)] overflow-hidden shrink-0">
            <div className="flex items-center gap-[1.2rem]">
              <span className="text-[1.6rem] font-bold text-[#c8fe4e] whitespace-nowrap">SUASC CAIXAS</span>
              <SlashesIcon width={18} height={11} className="text-[#c8fe4e]" />
              <span className="text-[1.2rem] font-medium text-[#f8efff] opacity-75 whitespace-nowrap">
                ABRA E GERENCIE SUAS CAIXAS
              </span>
            </div>
            <SlashesIcon width={30} height={12} className="text-[#f8efff]" />
          </div>

          <div className="flex-1 min-h-0 bg-[rgba(29,28,38,0.55)] overflow-y-auto p-[2.4rem]">
            {MOCK_BOXES.length ? (
              <div className="grid grid-cols-6 gap-x-[2rem] gap-y-[2.4rem]">
                {MOCK_BOXES.map((box) => (
                  <BoxCard key={box.id} box={box} onClick={() => openBox(box)} />
                ))}
              </div>
            ) : (
              <div className="flex items-center justify-center h-full opacity-55">
                <span className="text-[1.2rem] font-medium text-[#f8efff]">VOCÊ NÃO POSSUI CAIXAS</span>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

function RouletteView({ box, onBack }: { box: Box; onBack: () => void }) {
  return (
    <div className="relative w-full h-full overflow-hidden">
      {/* Fundo da cena (baú) */}
      <img alt="" src={CAIXAS_BG} className="absolute inset-0 size-full object-cover pointer-events-none" />
      <div className="absolute inset-0 bg-[rgba(16,16,18,0.35)] pointer-events-none" />

      {/* Voltar */}
      <button
        onClick={onBack}
        onMouseEnter={(e) => {
          const el = e.currentTarget
          el.style.backgroundColor = '#c8fe4e'
          el.style.width = '5rem'
        }}
        onMouseLeave={(e) => {
          const el = e.currentTarget
          el.style.backgroundColor = '#f8efff'
          el.style.width = '4.4rem'
        }}
        className="absolute left-[5rem] top-[3rem] z-30 h-[4.4rem] flex items-center justify-center cursor-pointer overflow-hidden transition-[width,background-color] duration-200"
        style={{ width: '4.4rem', backgroundColor: '#f8efff' }}
      >
        <ArrowStylizedLeftIcon width={24} height={27} className="text-[#1d1c26]" />
      </button>

      {/* Roleta */}
      <div className="absolute left-0 right-0 top-[13rem] px-[2rem] flex flex-col items-center">
        <CaseRoulette />
      </div>

      {/* Nome da caixa */}
      <div className="absolute left-1/2 -translate-x-1/2 bottom-[3rem] z-20">
        <span className="text-[1.4rem] font-medium text-[#f8efff] opacity-75 whitespace-nowrap">
          {box.name}
        </span>
      </div>
    </div>
  )
}
