import { useState } from 'react'
import imgIconClose from '@/assets/minigames/icon-close.svg'
import imgIconCaretRight from '@/assets/minigames/icon-caret-right.svg'
import imgIconSearch from '@/assets/minigames/icon-search.svg'
import imgIconRefresh from '@/assets/minigames/icon-refresh.svg'
import imgIconRefreshDark from '@/assets/minigames/icon-refresh-dark.svg'
import imgIconGlobe from '@/assets/minigames/icon-globe.svg'
import imgIconGlobeDark from '@/assets/minigames/icon-globe-dark.svg'
import imgIconLock from '@/assets/minigames/icon-lock.svg'
import imgDividerV from '@/assets/minigames/divider-v.svg'
import imgDividerH from '@/assets/minigames/divider-h.png'
import { Room } from '../types'

const PAGE_SIZE = 6

type Props = {
  rooms: Room[]
  totalPlayers: number
  activeRooms: number
  selectedRoomId?: string
  modeName?: string
  onSelectRoom: (room: Room) => void
  onCreateRoom: () => void
  onRefresh: () => void
}

export default function RoomListPanel({
  rooms,
  totalPlayers,
  activeRooms,
  selectedRoomId,
  modeName,
  onSelectRoom,
  onCreateRoom,
  onRefresh,
}: Props) {
  const [page, setPage] = useState(0)
  const [search, setSearch] = useState('')

  const filtered = rooms.filter((r) => r.owner.toLowerCase().includes(search.toLowerCase()))
  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE))
  const safePage = Math.min(page, totalPages - 1)
  const pageRooms = filtered.slice(safePage * PAGE_SIZE, safePage * PAGE_SIZE + PAGE_SIZE)

  return (
    <div className="flex flex-col items-start w-[736px] h-[595px]">
      <div className="flex flex-col items-start w-full shrink-0">
        <div className="bg-[rgba(29,28,38,0.95)] flex flex-col items-start pb-[12px] pt-[18px] px-[18px] w-full">
          <div className="border-mg-primary border-b-2 border-l-8 border-r-2 border-t-2 flex h-[42px] items-center justify-between pl-[16px] pr-[12px] w-full">
            <div className="flex items-center py-1">
              <span className="font-termina font-medium text-[14px] text-mg-primary text-center whitespace-nowrap">
                {modeName ? `MINI-GAMES · ${modeName}` : 'MINI-GAMES'}
              </span>
            </div>
            <div className="flex items-center gap-[8px]">
              <div className="h-[12px] w-[30px] relative">
                <img alt="" className="absolute inset-[-8.33%_-3.33%] block w-full h-full" src={imgIconClose} />
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="bg-[rgba(29,28,38,0.9)] flex flex-1 flex-col gap-[12px] items-center min-h-0 p-[18px] w-full">
        <div className="flex gap-[12px] items-start justify-center w-full shrink-0">
          <div className="border border-[rgba(248,239,255,0.25)] flex flex-1 gap-[10px] h-[42px] items-center min-w-0 overflow-hidden p-[12px]">
            <input
              type="text"
              value={search}
              onChange={(e) => { setSearch(e.target.value); setPage(0) }}
              placeholder="PROCURE UMA SALA PELO NOME DO DONO"
              className="flex-1 bg-transparent font-termina font-medium text-[12px] text-mg-light placeholder:text-[rgba(248,239,255,0.55)] text-center whitespace-nowrap outline-none border-none min-w-0"
            />
            <img alt="" className="shrink-0 w-[18px] h-[18px]" src={imgIconSearch} />
          </div>
          <button
            onClick={() => { onRefresh(); setPage(0) }}
            className="group bg-[rgba(248,239,255,0.05)] border border-[rgba(248,239,255,0.25)] flex gap-[12px] h-[42px] items-center px-[17px] py-px shrink-0 cursor-pointer hover:bg-mg-light transition-colors"
          >
            <img alt="" className="shrink-0 w-[18px] h-[18px] group-hover:hidden" src={imgIconRefresh} />
            <img alt="" className="shrink-0 w-[18px] h-[18px] hidden group-hover:block" src={imgIconRefreshDark} />
            <span className="font-termina font-semibold text-[12px] text-mg-light group-hover:text-mg-bg text-center whitespace-nowrap">
              ATUALIZAR
            </span>
          </button>
        </div>

        <div className="flex flex-1 flex-col gap-[8px] items-start min-h-0 w-full">
          <div className="bg-[rgba(29,28,38,0.55)] flex h-[25px] items-center overflow-hidden pl-[18px] pr-[12px] shrink-0 w-full">
            <div className="flex flex-1 gap-[10px] items-center">
              <div className="w-[145px] shrink-0">
                <span className="font-termina font-medium text-[12px] text-[rgba(248,239,255,0.55)] whitespace-nowrap">DONO</span>
              </div>
              <div className="flex-1 text-center">
                <span className="font-termina font-medium text-[12px] text-[rgba(248,239,255,0.55)] whitespace-nowrap">MAPA</span>
              </div>
              <div className="flex-1 text-center">
                <span className="font-termina font-medium text-[12px] text-[rgba(248,239,255,0.55)] whitespace-nowrap">JOGADORES</span>
              </div>
              <div className="w-[101px] shrink-0 text-right">
                <span className="font-termina font-medium text-[12px] text-[rgba(248,239,255,0.55)] whitespace-nowrap">STATUS</span>
              </div>
            </div>
          </div>

          <div className="flex flex-1 flex-col gap-[4px] min-h-0 w-full">
            {pageRooms.length === 0 ? (
              <div className="flex flex-1 items-center justify-center">
                <span className="font-termina font-medium text-[11px] text-[rgba(248,239,255,0.3)]">
                  NENHUMA SALA ENCONTRADA
                </span>
              </div>
            ) : (
              pageRooms.map((room) => (
                <button
                  key={room.id}
                  onClick={() => onSelectRoom(room)}
                  className={`group flex h-[42px] items-center overflow-hidden px-[18px] shrink-0 w-full cursor-pointer transition-colors border-2 ${
                    selectedRoomId === room.id
                      ? 'bg-mg-primary border-mg-primary'
                      : 'bg-[rgba(248,239,255,0.1)] border-[rgba(248,239,255,0.1)] hover:bg-mg-primary hover:border-mg-primary'
                  }`}
                >
                  <div className="flex flex-1 gap-[10px] h-[22px] items-center">
                    <div className="w-[145px] shrink-0">
                      <span className={`font-termina font-medium text-[12px] whitespace-nowrap ${selectedRoomId === room.id ? 'text-mg-bg' : 'text-mg-light group-hover:text-mg-bg'}`}>
                        {room.owner}
                      </span>
                    </div>
                    <div className="flex-1 text-center">
                      <span className={`font-termina font-medium text-[12px] whitespace-nowrap ${selectedRoomId === room.id ? 'text-mg-bg' : 'text-mg-light group-hover:text-mg-bg'}`}>
                        {room.map}
                      </span>
                    </div>
                    <div className="flex-1 text-center">
                      <span className={`font-termina font-medium text-[12px] whitespace-nowrap ${selectedRoomId === room.id ? 'text-mg-bg' : 'text-mg-light group-hover:text-mg-bg'}`}>
                        {room.players}/{room.maxPlayers}
                      </span>
                    </div>
                    <div className="w-[101px] shrink-0 flex justify-end">
                      {room.isPrivate ? (
                        <img
                          alt=""
                          className={`w-[18px] h-[18px] transition-filter ${
                            selectedRoomId === room.id ? 'brightness-0' : 'group-hover:brightness-0'
                          }`}
                          src={imgIconLock}
                        />
                      ) : (
                        <>
                          <img alt="" className={`w-[18px] h-[18px] ${selectedRoomId === room.id ? 'hidden' : 'block group-hover:hidden'}`} src={imgIconGlobe} />
                          <img alt="" className={`w-[18px] h-[18px] ${selectedRoomId === room.id ? 'block' : 'hidden group-hover:block'}`} src={imgIconGlobeDark} />
                        </>
                      )}
                    </div>
                  </div>
                </button>
              ))
            )}
          </div>

          <div className="flex items-center justify-between shrink-0 w-full h-[28px]">
            <button
              onClick={() => setPage((p) => Math.max(0, p - 1))}
              disabled={safePage === 0}
              className="bg-[rgba(248,239,255,0.05)] border border-[rgba(248,239,255,0.15)] flex items-center px-[12px] h-full cursor-pointer disabled:opacity-25 hover:enabled:bg-[rgba(248,239,255,0.1)] transition-colors"
            >
              <span className="font-termina font-medium text-[11px] text-mg-light whitespace-nowrap">← ANTERIOR</span>
            </button>
            <span className="font-termina font-medium text-[11px] text-[rgba(248,239,255,0.45)] whitespace-nowrap">
              {safePage + 1} / {totalPages} &nbsp;·&nbsp; {filtered.length} SALAS
            </span>
            <button
              onClick={() => setPage((p) => Math.min(totalPages - 1, p + 1))}
              disabled={safePage >= totalPages - 1}
              className="bg-[rgba(248,239,255,0.05)] border border-[rgba(248,239,255,0.15)] flex items-center px-[12px] h-full cursor-pointer disabled:opacity-25 hover:enabled:bg-[rgba(248,239,255,0.1)] transition-colors"
            >
              <span className="font-termina font-medium text-[11px] text-mg-light whitespace-nowrap">PRÓXIMA →</span>
            </button>
          </div>
        </div>
      </div>

      <div className="bg-[rgba(29,28,38,0.95)] flex items-center justify-between px-[18px] py-[12px] shrink-0 w-full">
        <div className="flex gap-[16px] items-center">
          <div className="flex flex-col items-start">
            <span className="font-termina font-semibold text-[10px] text-[rgba(248,239,255,0.55)] whitespace-nowrap leading-[15px]">
              TOTAL DE JOGADORES
            </span>
            <span className="font-termina font-semibold text-[13px] text-mg-primary tracking-[1px] whitespace-nowrap leading-6">
              {totalPlayers.toLocaleString('pt-BR')} ONLINE
            </span>
          </div>
          <div className="h-[24px] w-[8px] relative shrink-0">
            <img alt="" className="absolute inset-0 w-full h-full" src={imgDividerV} />
          </div>
          <div className="flex flex-col items-start">
            <span className="font-termina font-semibold text-[10px] text-[rgba(248,239,255,0.55)] whitespace-nowrap leading-[15px]">
              SALAS ATIVAS
            </span>
            <span className="font-termina font-semibold text-[13px] text-mg-primary tracking-[1px] whitespace-nowrap leading-6">
              {activeRooms}
            </span>
          </div>
        </div>
        <button
          onClick={onCreateRoom}
          className="bg-mg-primary border-2 border-[rgba(248,239,255,0.55)] flex items-center justify-center px-[16px] py-[12px] cursor-pointer hover:brightness-110 transition-all"
        >
          <span className="font-termina font-semibold text-[14px] text-mg-bg text-center whitespace-nowrap">CRIAR SALA</span>
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
