import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useLobby } from '@/providers/LobbyProvider'
import { fetchData } from '@/utils/fetchData'
import type { GameVariant } from '@/types/nui'
import { GameModeCard } from './components/game-mode-card'
import { MODES, buildModeData, normalizeModeId } from './components/modes-data'
import { ModeSelector } from './components/mode-selector'
import { SwitchHeader } from './components/switch-header'

type PickerState = {
  category: string
  submode: string
  submodeName: string
  variants: GameVariant[]
}

export default function SwitchModePage() {
  const navigate = useNavigate()
  const { selectedMode, gamemodes, setSelectedMode } = useLobby()
  const [selected, setSelected] = useState(selectedMode.category)
  const [selectedSubmode, setSelectedSubmode] = useState(selectedMode.submode)
  const [picker, setPicker] = useState<PickerState | null>(null)

  const modes = Object.keys(gamemodes).length > 0
    ? Object.entries(gamemodes).map(([name, data]) => buildModeData(name, data.new))
    : MODES

  const handleCategoryChange = (category: string) => {
    if (category === 'mini-games') {
      fetchData('lobby_minigames:enter', {})
      return
    }
    setSelected(category)
    setSelectedMode({ category, submode: selectedSubmode })
    fetchData('selectMode', { category, submode: selectedSubmode })
  }

  const resolveSubmodeConfig = (categoryId: string, submodeId: string) => {
    const modeName = Object.keys(gamemodes).find((n) => normalizeModeId(n) === categoryId)
    const subTypes = modeName ? (gamemodes[modeName].sub_types ?? {}) : {}
    const subTypeName = Object.keys(subTypes).find((n) => normalizeModeId(n) === submodeId)
    return subTypeName ? subTypes[subTypeName] : null
  }

  const joinQueue = (category: string, submode: string) => {
    setSelectedSubmode(submode)
    setSelectedMode({ category, submode })
    fetchData('selectMode', { category, submode })
    fetchData('joinQueue', { category, submode, fillSlot: false })
    navigate('/')
  }

  const handleSubmodeChange = (submode: string) => {
    const config = resolveSubmodeConfig(selected, submode)
    if (config?.variants && config.variants.length > 0) {
      const categoryName = Object.keys(gamemodes).find((n) => normalizeModeId(n) === selected)
      const subTypes     = categoryName ? (gamemodes[categoryName].sub_types ?? {}) : {}
      const submodeName  = Object.keys(subTypes).find((n) => normalizeModeId(n) === submode) ?? submode
      setPicker({ category: selected, submode, submodeName, variants: config.variants })
      return
    }
    joinQueue(selected, submode)
  }

  const handleVariantPick = (variant: GameVariant) => {
    if (!picker) return
    const { category } = picker
    setPicker(null)
    joinQueue(category, variant.target)
  }

  return (
    <div className="flex flex-col w-full h-full px-[5rem] py-[3.2rem] gap-[3.2rem] overflow-hidden">
      <SwitchHeader onBack={() => navigate('/')} />

      <div className="flex items-center justify-between flex-1 min-h-0 px-[1.2rem] gap-[0.8rem]">
        {modes.map((mode, i) => (
          <>
            <div key={mode.id} className="relative h-full flex-1 min-w-0">
              <GameModeCard
                label={mode.label}
                video={mode.video}
                color={mode.color}
                hoverColor={mode.hoverColor}
                overlayOpacity={mode.overlayOpacity}
                circuit={mode.circuit}
                hoverCircuit={mode.hoverCircuit}
                hoverCircuitWhite={mode.hoverCircuitWhite}
                rotation={mode.rotation}
                selectedBorder={mode.selectedBorder}
                badge={mode.badge}
                selected={selected === mode.id}
                onClick={() => handleCategoryChange(mode.id)}
              />
            </div>
            {i < modes.length - 1 && (
              <div key={`sep-${i}`} className="shrink-0">
                <img src={new URL('/xis.png', import.meta.url).href} alt="" className="w-[8.4rem] pointer-events-none" />
              </div>
            )}
          </>
        ))}
      </div>

      {selected !== 'mini-games' && (
        <ModeSelector
          selectedId={selected}
          selectedSubmode={selectedSubmode}
          gamemodes={gamemodes}
          onSubmodeChange={handleSubmodeChange}
        />
      )}

      {picker && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center"
          onClick={() => setPicker(null)}
          style={{ background: 'rgba(8,6,14,0.78)', backdropFilter: 'blur(3px)' }}
        >
          <div
            className="relative flex flex-col gap-[2rem]"
            style={{
              width: 'min(56rem, 92vw)',
              background: '#1d1c26',
              borderLeft: '8px solid #c8fe4e',
              padding: '2.8rem 3.2rem',
              boxShadow: '0 18px 60px rgba(0,0,0,0.6)',
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between">
              <span
                className="font-['Termina',sans-serif] text-[1.1rem] tracking-[0.3rem]"
                style={{ color: 'rgba(248,239,255,0.5)' }}
              >
                {picker.submodeName.toUpperCase()}
              </span>
              <button
                type="button"
                onClick={() => setPicker(null)}
                className="cursor-pointer"
                style={{
                  width: '2.8rem',
                  height: '2.8rem',
                  background: 'transparent',
                  border: '1px solid rgba(248,239,255,0.25)',
                  color: '#f8efff',
                  fontSize: '1.2rem',
                }}
              >
                X
              </button>
            </div>

            <h2
              className="font-['Termina',sans-serif] text-[1.8rem] tracking-[0.4rem]"
              style={{ color: '#f8efff' }}
            >
              ESCOLHA O ESTILO
            </h2>

            <div className="flex gap-[1.2rem]">
              {picker.variants.map((v) => (
                <button
                  key={v.id}
                  type="button"
                  onClick={() => handleVariantPick(v)}
                  className="flex-1 cursor-pointer transition-[background-color,border-color] duration-150"
                  style={{
                    height: '5.6rem',
                    background: 'rgba(248,239,255,0.08)',
                    border: '2px solid rgba(248,239,255,0.2)',
                    color: '#f8efff',
                    fontFamily: 'Termina, sans-serif',
                    fontSize: '1.6rem',
                    fontWeight: 700,
                    letterSpacing: '0.4rem',
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.background = '#c8fe4e'
                    e.currentTarget.style.borderColor = '#c8fe4e'
                    e.currentTarget.style.color = '#1d1c26'
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.background = 'rgba(248,239,255,0.08)'
                    e.currentTarget.style.borderColor = 'rgba(248,239,255,0.2)'
                    e.currentTarget.style.color = '#f8efff'
                  }}
                >
                  {v.label}
                </button>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
