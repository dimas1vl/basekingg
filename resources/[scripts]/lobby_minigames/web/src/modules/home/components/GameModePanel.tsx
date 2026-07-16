import imgIconClose from '@/assets/minigames/icon-close.svg'
import imgIconBalaclava from '@/assets/minigames/icon-balaclava.svg'
import imgIconBuilding from '@/assets/minigames/icon-building.svg'
import imgIconCaretRight from '@/assets/minigames/icon-caret-right.svg'
import imgDividerH from '@/assets/minigames/divider-h.png'
import { GameMode } from '../types'

type Props = {
  modes: GameMode[]
  onSelectMode: (mode: GameMode) => void
}

export default function GameModePanel({ modes, onSelectMode }: Props) {
  return (
    <div className="absolute left-1/2 -translate-x-1/2 -translate-y-1/2 top-[calc(50%+0.5px)]">
      <div className="flex flex-col items-start w-[434px]">
        <div className="flex flex-col items-start w-full shrink-0">
          <div className="bg-[rgba(29,28,38,0.95)] flex flex-col items-start pb-[12px] pt-[18px] px-[18px] w-full">
            <div className="border-mg-primary border-b-2 border-l-8 border-r-2 border-t-2 flex h-[42px] items-center justify-between pl-[16px] pr-[12px] w-full">
              <span className="font-termina font-medium text-[14px] text-mg-primary text-center whitespace-nowrap">
                MINI-GAMES
              </span>
              <div className="h-[12px] w-[30px] relative">
                <img alt="" className="absolute inset-[-8.33%_-3.33%] block w-full h-full" src={imgIconClose} />
              </div>
            </div>
          </div>
        </div>

        <div className="w-full shrink-0">
          <div className="bg-[rgba(29,28,38,0.9)] flex flex-col gap-[8px] items-start justify-center p-[18px] w-full">
            {modes.map((mode) => (
              <button
                key={mode.id}
                onClick={() => onSelectMode(mode)}
                className="bg-[rgba(248,239,255,0.05)] border-2 border-[rgba(248,239,255,0.35)] flex h-[56px] items-center justify-center px-[18px] py-[12px] w-full cursor-pointer hover:bg-[rgba(248,239,255,0.1)] transition-colors"
              >
                <div className="flex flex-1 h-full items-center justify-between">
                  <div className="flex gap-[4px] h-full items-center py-1">
                    <div className="overflow-hidden relative shrink-0 w-[24px] h-[24px]">
                      {mode.icon === 'balaclava' ? (
                        <div
                          className="absolute"
                          style={{ top: '50%', left: '5px', right: '5px', transform: 'translateY(-50%)', aspectRatio: '14/18' }}
                        >
                          <img alt="" className="absolute inset-0 w-full h-full" src={imgIconBalaclava} />
                        </div>
                      ) : (
                        <div
                          className="absolute"
                          style={{ top: '50%', left: '6px', right: '6px', transform: 'translateY(-50%)', aspectRatio: '12/18' }}
                        >
                          <img alt="" className="absolute inset-0 w-full h-full" src={imgIconBuilding} />
                        </div>
                      )}
                    </div>
                    <span className="font-termina font-semibold text-[12px] text-mg-light text-center whitespace-nowrap">
                      {mode.name}
                    </span>
                  </div>
                  <div className="flex items-center justify-end">
                    <div className="flex items-center px-[8px] py-[4px]">
                      <span className="font-termina font-medium text-[10px] text-[rgba(248,239,255,0.75)] text-center whitespace-nowrap">
                        {mode.openRooms === null ? 'CRIE UMA SALA' : 'SALAS ABERTAS'}
                      </span>
                    </div>
                    <div className="bg-mg-primary flex gap-[10px] items-center px-[8px] py-[4px]">
                      {mode.openRooms === null ? (
                        <div className="relative w-[12px] h-[12px]">
                          <img alt="" className="absolute inset-0 w-full h-full" src={imgIconCaretRight} />
                        </div>
                      ) : (
                        <span className="font-termina font-semibold text-[10px] text-mg-bg text-center whitespace-nowrap">
                          {mode.openRooms}
                        </span>
                      )}
                    </div>
                  </div>
                </div>
              </button>
            ))}
          </div>
        </div>

        <div className="bg-[rgba(29,28,38,0.95)] flex flex-col items-center justify-center px-[18px] py-[12px] shrink-0 w-full">
          <span className="font-termina font-medium text-[10px] text-[rgba(248,239,255,0.35)] text-center whitespace-nowrap">
            APROVEITE NOSSOS MINI-GAMES
          </span>
        </div>

        <div className="h-[17px] overflow-hidden relative shrink-0 w-full">
          <div
            className="absolute flex h-[17px] items-center justify-center top-0"
            style={{ left: 'calc(50% + 204.75px)', transform: 'translateX(-50%)', width: '1929.5px' }}
          >
            <div style={{ transform: 'scaleY(-1) rotate(180deg)' }}>
              <img alt="" src={imgDividerH} style={{ width: '1929.5px', height: '17px', display: 'block' }} />
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
