import { cn } from '@/lib/utils'
import cardBg from '@/assets/airdrop/card-bg.svg'
import cardBgHover from '@/assets/airdrop/card-bg-hover.svg'
import type { Ability } from '../types'

interface AbilityCardProps {
  ability: Ability
  selected: boolean
  disabled?: boolean
  onSelect: (ability: Ability) => void
}

export function AbilityCard({ ability, selected, disabled, onSelect }: AbilityCardProps) {
  const active = selected

  return (
    <button
      type="button"
      disabled={disabled}
      onClick={() => onSelect(ability)}
      className={cn(
        'group relative h-[16.4rem] w-[12.9rem] shrink-0 outline-none',
        'transition-transform duration-150 ease-out active:scale-[0.98]',
        disabled && 'pointer-events-none opacity-40',
      )}
    >
      <img
        src={cardBg}
        alt=""
        className={cn(
          'absolute inset-0 h-full w-full transition-opacity duration-200',
          'group-hover:opacity-0',
          active && 'opacity-0',
        )}
      />

      <img
        src={cardBgHover}
        alt=""
        className={cn(
          'absolute inset-0 h-full w-full opacity-0 transition-opacity duration-200 drop-shadow-accent',
          'group-hover:opacity-100',
          active && 'opacity-100',
        )}
      />

      <div className="absolute inset-x-0 top-0 flex h-[11rem] items-center justify-center">
        <img
          src={ability.icon}
          alt=""
          style={{ width: ability.iconWidth, height: ability.iconHeight }}
          className={cn(
            'object-contain transition-transform duration-200 ease-out',
            'group-hover:scale-[1.16]',
            active && 'scale-[1.16]',
          )}
        />
      </div>

      <div className="absolute bottom-[1.9rem] left-1/2 flex w-[10.5rem] -translate-x-1/2 flex-col items-center gap-[0.6rem] text-center">
        <span className="font-termina text-[1.4rem] font-bold leading-none tracking-wide text-primary">
          {ability.title}
        </span>
        <span className="whitespace-pre-line font-termina text-[1rem] font-medium leading-[1.25] tracking-wide text-light/55">
          {ability.description}
        </span>
      </div>
    </button>
  )
}
