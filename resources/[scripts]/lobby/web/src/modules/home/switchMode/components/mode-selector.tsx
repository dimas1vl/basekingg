import {
  ArrowSwitchmodeIcon,
  CasualIcon,
  CompetitiveFemaleIcon,
  CompetitiveIcon,
  EventIcon,
} from '@/components/icons'
import { ModeSelect } from '@/components/ui'
import type { GameModesPayload } from '@/types/nui'
import { normalizeModeId } from './modes-data'

const SUBMODE_ICONS: Record<string, React.ElementType> = {
  casual: CasualIcon,
  competitivo: CompetitiveIcon,
  'competitivo-feminino': CompetitiveFemaleIcon,
  evento: EventIcon,
}

type ModeSelectorProps = {
  selectedId: string
  selectedSubmode: string
  gamemodes: GameModesPayload
  onSubmodeChange: (submode: string) => void
}

export function ModeSelector({
  selectedId,
  selectedSubmode,
  gamemodes,
  onSubmodeChange,
}: ModeSelectorProps) {
  const modeName = Object.keys(gamemodes).find((n) => normalizeModeId(n) === selectedId)
  const subTypes = modeName ? (gamemodes[modeName].sub_types ?? {}) : {}

  const submodes = Object.entries(subTypes).map(([name, config]) => ({
    id: normalizeModeId(name),
    label: name.toUpperCase(),
    premium: config.premium ?? false,
    inactive: config.inactive ?? false,
  }))

  return (
    <div className="flex relative flex-col shrink-0 border-[0.6rem] border-[#4d4c55] border-solid">
      <div className="relative px-[3.2rem] py-[2rem] flex flex-col gap-[1rem]">
        <span className="text-[2rem] font-bold text-[#c8fe4e] whitespace-nowrap">
          {modeName?.toUpperCase() ?? selectedId.toUpperCase()}
        </span>

        <div className="flex items-center gap-[1rem]">
          {submodes.map((sub) => {
            const Icon = SUBMODE_ICONS[sub.id]
            return (
              <ModeSelect
                key={sub.id}
                label={sub.label}
                icon={
                  Icon ? (
                    <Icon width={67} height={56} className="text-[rgba(248,239,255,0.2)]" />
                  ) : undefined
                }
                state={
                  sub.inactive ? 'inactive' : selectedSubmode === sub.id ? 'active' : 'default'
                }
                premium={sub.premium}
                className="flex-1 w-auto"
                onClick={sub.inactive ? undefined : () => onSubmodeChange(sub.id)}
              />
            )
          })}
        </div>
      </div>

      <ArrowSwitchmodeIcon
        className="absolute left-[27.2rem] top-[-2rem] pointer-events-none"
        width={303}
        height={56}
      />
    </div>
  )
}
