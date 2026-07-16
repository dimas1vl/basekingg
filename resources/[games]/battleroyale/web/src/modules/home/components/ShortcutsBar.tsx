import type { PregameShortcuts } from '@/types/hud'

interface ShortcutsBarProps extends PregameShortcuts {
  leaveVisible: boolean
  leavePct: number
}

export default function ShortcutsBar({ visible, passive, current, max, leaveVisible, leavePct }: ShortcutsBarProps) {
  if (!visible) return null

  const hasWaiting = typeof current === 'number' && typeof max === 'number'

  return (
    <div
      className="pointer-events-none absolute left-1/2 flex flex-col items-center gap-[6px]"
      style={{
        bottom: 35,
        transform: 'translateX(-50%)',
        fontFamily: 'Termina, Rajdhani, Inter, system-ui, sans-serif',
        color: '#f8efff',
      }}
    >
      {hasWaiting && (
        <div
          className="flex items-center justify-between"
          style={{
            width: 380,
            height: 34,
            background: 'rgba(20,19,28,0.88)',
            borderRadius: 4,
            padding: '0 14px',
            boxSizing: 'border-box',
          }}
        >
          <div className="flex items-center gap-[10px]">
            <span
              className="inline-flex items-center justify-center"
              style={{
                height: 18,
                padding: '0 8px',
                background: '#c8fe4e',
                color: '#14130e',
                fontWeight: 700,
                fontSize: 9,
                letterSpacing: '0.08em',
                lineHeight: 1,
                borderRadius: 2,
              }}
            >
              BATTLE ROYALE
            </span>
            <span
              style={{
                fontWeight: 500,
                fontSize: 10,
                letterSpacing: '0.06em',
                opacity: 0.7,
                lineHeight: 1,
              }}
            >
              AGUARDANDO JOGADORES
            </span>
          </div>
          <span
            style={{
              fontWeight: 700,
              fontSize: 14,
              color: '#c8fe4e',
              fontVariantNumeric: 'tabular-nums',
              letterSpacing: '0.04em',
              lineHeight: 1,
            }}
          >
            {current}/{max}
          </span>
        </div>
      )}

      <div
        className="flex items-center"
        style={{
          gap: 8,
          width: 380,
        }}
      >
        <div
          className="flex flex-1 items-center justify-center gap-[8px]"
          style={{
            height: 30,
            background: passive ? 'rgba(20,19,28,0.88)' : 'rgba(255,107,107,0.15)',
            borderRadius: 4,
            padding: '0 14px',
            transition: 'background 0.2s ease',
          }}
        >
          <span
            className="inline-flex items-center justify-center"
            style={{
              height: 18,
              minWidth: 22,
              padding: '0 6px',
              background: passive ? '#c8fe4e' : '#ff6b6b',
              color: '#14130e',
              fontWeight: 700,
              fontSize: 10,
              letterSpacing: '0.05em',
              lineHeight: 1,
              borderRadius: 2,
              transition: 'background 0.2s ease',
            }}
          >
            G
          </span>
          <span
            style={{
              fontWeight: 500,
              fontSize: 10,
              letterSpacing: '0.05em',
              whiteSpace: 'nowrap',
              lineHeight: 1,
              opacity: 0.9,
            }}
          >
            {passive ? 'ENTRAR PVP' : 'SAIR PVP'}
          </span>
        </div>

        <div
          className="flex flex-1 items-center justify-center gap-[8px]"
          style={{
            height: 30,
            background: 'rgba(20,19,28,0.88)',
            borderRadius: 4,
            padding: '0 14px',
          }}
        >
          <span
            className="inline-flex items-center justify-center"
            style={{
              height: 18,
              minWidth: 22,
              padding: '0 6px',
              background: '#ff6b6b',
              color: '#14130e',
              fontWeight: 700,
              fontSize: 10,
              letterSpacing: '0.05em',
              lineHeight: 1,
              borderRadius: 2,
            }}
          >
            F
          </span>
          <span
            style={{
              fontWeight: 500,
              fontSize: 10,
              letterSpacing: '0.05em',
              whiteSpace: 'nowrap',
              lineHeight: 1,
              opacity: 0.9,
            }}
          >
            VOLTAR AO LOBBY
          </span>
        </div>
      </div>

      {leaveVisible && (
        <div
          className="relative w-full overflow-hidden"
          style={{
            width: 380,
            height: 3,
            background: 'rgba(20,19,28,0.6)',
            borderRadius: 2,
          }}
        >
          <div
            className="absolute left-0 top-0 h-full"
            style={{
              background: '#c8fe4e',
              width: `${leavePct}%`,
              transition: 'width 0.05s linear',
              borderRadius: 2,
            }}
          />
        </div>
      )}
    </div>
  )
}
