import { useState, useEffect, useCallback } from 'react'
import { useListener } from '@/hooks/listener'
import { useNuiQuery } from '@/hooks/useNuiQuery'
import { useNuiMutation } from '@/hooks/useNuiMutation'
import { fetchData } from '@/utils/fetchData'
import { isEnvBrowser } from '@/utils/misc'
import iconAirdrop from '@/assets/airdrop/icon-airdrop.svg'
import union from '@/assets/airdrop/union.svg'
import subtract from '@/assets/airdrop/subtract.png'
import { AbilityCard } from './components/AbilityCard'
import { MOCK_ABILITIES, resolveVisual } from './data'
import type { AbilityData } from './types'

export default function Airdrop() {
  const [visible, setVisible] = useState(false)
  const [selectedId, setSelectedId] = useState<string | null>(null)

  const close = useCallback(() => {
    setVisible(false)
    setSelectedId(null)
    fetchData('airdrop:close')
  }, [])

  useListener<boolean>('airdrop:show', () => {
    setSelectedId(null)
    setVisible(true)
  })

  useListener<boolean>('airdrop:close', () => {
    setVisible(false)
    setSelectedId(null)
  })

  useEffect(() => {
    if (!visible) return
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') close()
    }
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [visible, close])

  const { data: abilities = [] } = useNuiQuery<AbilityData[]>({
    event: 'getAbilities',
    mockData: MOCK_ABILITIES,
  })

  const select = useNuiMutation<{ success?: boolean }, { id: string }>({
    event: 'selectAbility',
    onSuccess: () => close(),
    onError: () => setSelectedId(null),
  })

  const handleSelect = (ability: AbilityData) => {
    if (selectedId) return
    setSelectedId(ability.id)
    select.mutate({ id: ability.id })

    if (isEnvBrowser()) setTimeout(close, 450)
  }

  if (!visible) return null

  return (
    <div className="absolute inset-0 z-50 flex items-center justify-center">
      <div className="flex h-[31.1rem] w-[46.3rem] flex-col overflow-hidden font-termina">
        {/* Header */}
        <header className="flex h-[4.3rem] shrink-0 items-center justify-between bg-dark/95 px-[1.8rem]">
          <div className="flex items-center gap-[1rem]">
            <img src={iconAirdrop} alt="" className="h-[2.8rem] w-[2.8rem]" />
            <span className="text-[1.2rem] font-medium tracking-wide text-light">DROP</span>
          </div>
          <img src={union} alt="" className="h-[1.3rem] w-[3.5rem]" />
        </header>

        {/* Subtitle bar */}
        <div
          className="flex h-[3.5rem] shrink-0 items-center px-[1.8rem]"
          style={{
            backgroundImage:
              'linear-gradient(90deg, rgba(255, 255, 255, 0.05) 0%, rgba(255, 255, 255, 0.05) 100%), linear-gradient(90deg, rgba(29, 28, 38, 0.95) 0%, rgba(29, 28, 38, 0.95) 100%)',
          }}
        >
          <span className="text-[1.2rem] font-medium leading-none tracking-wide text-light/55">
            ESCOLHA UMA HABILIDADE.
          </span>
        </div>

        {/* Abilities */}
        <div className="flex flex-1 items-center justify-between bg-dark/90 px-[2.4rem]">
          {abilities.map((ability) => (
            <AbilityCard
              key={ability.id}
              ability={{ ...ability, ...resolveVisual(ability.id) }}
              selected={selectedId === ability.id}
              disabled={!!selectedId && selectedId !== ability.id}
              onSelect={handleSelect}
            />
          ))}
        </div>

        {/* Bottom bar + curved divider */}
        <div className="h-[1.3rem] w-full shrink-0 bg-dark/95" />
        <div className="relative h-[1.7rem] w-full shrink-0 overflow-hidden">
          <div className="absolute left-[calc(50%+20.525rem)] top-0 flex h-[1.7rem] w-[192.95rem] -translate-x-1/2 items-center justify-center">
            <div className="rotate-180 -scale-y-100">
              <img src={subtract} alt="" className="block h-[1.7rem] w-[192.95rem] max-w-none" />
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
