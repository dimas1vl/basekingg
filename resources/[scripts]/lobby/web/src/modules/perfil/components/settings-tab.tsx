import { cn } from '@/lib/utils'
import { CaretIcon } from '@/components/icons'
import type { ProfileSetting, ProfileSettingKey } from '../data'
import { Panel, SectionHeader } from './section'

type SettingsTabProps = {
  settings: ProfileSetting[]
  onChange: (key: ProfileSettingKey, value: boolean) => void
}

export function SettingsTab({ settings, onChange }: SettingsTabProps) {
  // Agrupa em linhas de 2 colunas (esquerda / direita), como no design.
  const rows: ProfileSetting[][] = []
  for (let i = 0; i < settings.length; i += 2) rows.push(settings.slice(i, i + 2))

  return (
    <div className="flex flex-col gap-[1.2rem] w-full px-[5rem] pb-[5rem] pt-[1.2rem] overflow-y-auto min-h-0">
      {rows.map((row, i) => (
        <div key={i} className="flex gap-[1.2rem] w-full shrink-0">
          {row.map((s) => (
            <Panel key={s.key} className="flex-1 min-w-0">
              <SectionHeader
                title={s.label}
                titleSize="1.4rem"
                right={
                  <Toggle
                    value={s.value}
                    onChange={(v) => onChange(s.key, v)}
                  />
                }
              />
            </Panel>
          ))}
          {row.length === 1 && <div className="flex-1" />}
        </div>
      ))}
    </div>
  )
}

function Toggle({ value, onChange }: { value: boolean; onChange: (v: boolean) => void }) {
  return (
    <div className="flex items-center gap-[0.5rem] h-[4.2rem] w-[49.5rem] shrink-0">
      <button
        onClick={() => onChange(!value)}
        className="flex items-center justify-center h-full px-[1.2rem] bg-[rgba(248,239,255,0.1)] cursor-pointer transition-colors hover:bg-[rgba(248,239,255,0.2)]"
      >
        <CaretIcon className="size-[2.4rem] text-[#f8efff] -scale-x-100" />
      </button>

      <div className="flex flex-1 min-w-0 h-full items-center border-2 border-[rgba(248,239,255,0.1)] border-solid bg-[rgba(248,239,255,0.05)] overflow-hidden">
        <button
          onClick={() => onChange(false)}
          className={cn(
            'flex flex-1 min-w-0 h-full items-center justify-center px-[1.2rem] transition-colors cursor-pointer',
            !value ? 'bg-[#f8efff]' : 'hover:bg-[rgba(248,239,255,0.08)]',
          )}
        >
          <span
            className={cn(
              'text-[1.2rem] font-semibold whitespace-nowrap',
              !value ? 'text-[#1d1c26]' : 'text-[#f8efff]',
            )}
          >
            DESLIGADO
          </span>
        </button>
        <button
          onClick={() => onChange(true)}
          className={cn(
            'flex flex-1 min-w-0 h-full items-center justify-center px-[1.2rem] transition-colors cursor-pointer',
            value ? 'bg-[#c8fe4e]' : 'hover:bg-[rgba(200,254,78,0.12)]',
          )}
        >
          <span
            className={cn(
              'text-[1.2rem] font-semibold whitespace-nowrap',
              value ? 'text-[#1d1c26]' : 'text-[#f8efff]',
            )}
          >
            LIGADO
          </span>
        </button>
      </div>

      <button
        onClick={() => onChange(!value)}
        className="flex items-center justify-center h-full w-[4.8rem] bg-[rgba(248,239,255,0.1)] cursor-pointer transition-colors hover:bg-[rgba(248,239,255,0.2)]"
      >
        <CaretIcon className="size-[2.4rem] text-[#f8efff]" />
      </button>
    </div>
  )
}
