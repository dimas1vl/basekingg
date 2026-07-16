import imgIconClosePanel from '@/assets/minigames/icon-close-panel.svg'
import imgRoomPreview from '@/assets/minigames/room-preview.png'
import imgDividerH from '@/assets/minigames/divider-h.png'
import { Room } from '../types'

type Props = {
  room: Room
  onClose: () => void
  onEnter: () => void
}

export default function RoomDetailsPanel({ room, onClose, onEnter }: Props) {
  return (
    <div className="flex flex-col items-start w-[340px] h-[483px]">
      <div className="bg-[rgba(29,28,38,0.95)] flex flex-col items-start px-[18px] py-[12px] shrink-0 w-full">
        <div className="border-mg-light border-l-4 flex h-[24px] items-center justify-between pl-[16px] pr-[12px] w-full">
          <span className="font-termina font-medium text-[12px] text-mg-light text-center whitespace-nowrap">
            SALA DE {room.owner.toUpperCase()}
          </span>
          <button onClick={onClose} className="h-[12px] w-[30px] relative cursor-pointer">
            <img alt="" className="absolute inset-[-8.33%_-3.33%] block w-full h-full" src={imgIconClosePanel} />
          </button>
        </div>
      </div>

      <div className="bg-[#1d1c26] flex flex-col items-center justify-center p-[8px] shrink-0 w-full">
        <div className="h-[127px] w-full overflow-hidden">
          <img alt="" className="w-full h-full object-cover" src={imgRoomPreview} />
        </div>
      </div>

      <div className="bg-[rgba(29,28,38,0.9)] flex flex-1 flex-col items-center justify-between min-h-0 p-[18px] w-full">
        <div className="flex flex-col gap-[12px] items-start w-full">
          <div className="bg-[rgba(248,239,255,0.05)] border-2 border-[rgba(248,239,255,0.05)] flex h-[42px] items-center overflow-hidden px-[18px] w-full">
            <div className="flex flex-1 h-[22px] items-center justify-between">
              <span className="font-termina font-medium text-[12px] text-mg-light whitespace-nowrap">MAPA</span>
              <span className="font-termina font-medium text-[12px] text-mg-light whitespace-nowrap">{room.map}</span>
            </div>
          </div>
          <div className="bg-[rgba(248,239,255,0.05)] border-2 border-[rgba(248,239,255,0.05)] flex h-[42px] items-center overflow-hidden px-[18px] w-full">
            <div className="flex flex-1 h-[22px] items-center justify-between">
              <span className="font-termina font-medium text-[12px] text-mg-light whitespace-nowrap">STATUS</span>
              <span className="font-termina font-medium text-[12px] whitespace-nowrap" style={{ color: '#e8ffb5' }}>
                {room.isPrivate ? 'PRIVADA' : 'PÚBLICA'}
              </span>
            </div>
          </div>
          <div className="bg-[rgba(248,239,255,0.05)] border-2 border-[rgba(248,239,255,0.05)] flex h-[42px] items-center overflow-hidden px-[18px] w-full">
            <div className="flex flex-1 h-[22px] items-center justify-between">
              <span className="font-termina font-medium text-[12px] text-mg-light whitespace-nowrap">JOGADORES</span>
              <span className="font-termina font-medium text-[12px] text-mg-light whitespace-nowrap">
                {room.players}/{room.maxPlayers}
              </span>
            </div>
          </div>
        </div>

        <button
          onClick={onEnter}
          className="bg-mg-light flex h-[41px] items-center justify-center px-[12px] py-[4px] w-full cursor-pointer hover:brightness-95 transition-all shrink-0"
        >
          <span className="font-termina font-semibold text-[14px] text-mg-bg text-center whitespace-nowrap">ENTRAR</span>
        </button>
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
  )
}
