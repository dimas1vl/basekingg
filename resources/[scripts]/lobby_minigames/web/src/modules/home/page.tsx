import { useState, useEffect, useRef } from 'react'
import { createPortal } from 'react-dom'
import { useHudScale } from '@/hooks/useHudScale'
import { useVisibility } from '@/providers/Visibility'
import { useListener } from '@/hooks/listener'
import { fetchData } from '@/utils/fetchData'
import GameModePanel from './components/GameModePanel'
import RoomListPanel from './components/RoomListPanel'
import RoomDetailsPanel from './components/RoomDetailsPanel'
import CreateRoomPanel from './components/CreateRoomPanel'
import PasswordModal from './components/PasswordModal'
import SafeZonePanel from './components/SafeZonePanel'
import { Room, GameMode, GameModeCount, CreateRoomData, PanelMode, Screen } from './types'

const DEFAULT_GAME_MODES: GameMode[] = [
  { id: 'clutch', name: 'CLUTCH', icon: 'balaclava', openRooms: null },
  { id: 'gang', name: 'GANG', icon: 'balaclava', openRooms: 0 },
  { id: 'predios', name: 'PRÉDIOS', icon: 'building', openRooms: 0 },
  { id: 'dominacao', name: 'DOMINAÇÃO', icon: 'balaclava', openRooms: 0 },
]

const MOCK_ROOMS: Room[] = [
  { id: '1', owner: 'RACCO', map: 'MAPA TAL', players: 8, maxPlayers: 12, isPrivate: false },
  { id: '2', owner: 'DIMAS 1VL', map: 'MAPA TAL', players: 8, maxPlayers: 12, isPrivate: true },
  { id: '3', owner: 'LIKIZÃO', map: 'MAPA TAL 3', players: 8, maxPlayers: 12, isPrivate: false },
  { id: '4', owner: 'EDMFILHO', map: 'MAPA TAL 2', players: 8, maxPlayers: 12, isPrivate: false },
  { id: '5', owner: 'BLVREVOLUTION', map: 'MAPA TAL 1', players: 8, maxPlayers: 12, isPrivate: false },
  { id: '6', owner: 'FLAASH', map: 'MAPA TAL 4', players: 8, maxPlayers: 12, isPrivate: true },
  { id: '7', owner: 'MIRTO', map: 'MAPA TAL', players: 8, maxPlayers: 12, isPrivate: false },
  { id: '8', owner: 'RACCO', map: 'PRÉDIOS 2', players: 8, maxPlayers: 12, isPrivate: false },
  { id: '9', owner: 'KINGZIN', map: 'PRÉDIOS 1', players: 4, maxPlayers: 8, isPrivate: false },
  { id: '10', owner: 'LUVZ', map: 'MAPA TAL 5', players: 12, maxPlayers: 12, isPrivate: false },
  { id: '11', owner: 'DRAKEZ', map: 'MAPA TAL 2', players: 3, maxPlayers: 6, isPrivate: true },
  { id: '12', owner: 'PABLITO', map: 'SANDY SHORES', players: 7, maxPlayers: 12, isPrivate: false },
]

export default function Home() {
  const { scale, offsetX, offsetY } = useHudScale()
  const { close, preselectedMode, consumePreselectedMode, safeZones, consumeSafeZones } = useVisibility()

  const [screen, setScreen] = useState<Screen>('gamemode')
  const [gameModes, setGameModes] = useState<GameMode[]>(DEFAULT_GAME_MODES)
  const [selectedMode, setSelectedMode] = useState<GameMode | null>(null)
  const [rooms, setRooms] = useState<Room[]>([])
  const [panelMode, setPanelMode] = useState<PanelMode>(null)
  const [selectedRoom, setSelectedRoom] = useState<Room | null>(null)
  const [showPasswordModal, setShowPasswordModal] = useState(false)
  const [totalPlayers, setTotalPlayers] = useState(0)

  const preselectAppliedRef = useRef(false)

  useListener<GameModeCount[]>('minigames:setGameModes', (counts) => {
    setGameModes((prev) =>
      prev.map((mode) => ({
        ...mode,
        openRooms: counts.find((c) => c.id === mode.id)?.openRooms ?? mode.openRooms,
      }))
    )
  })

  useListener<Room[]>('minigames:setRooms', (data) => {
    setRooms(Array.isArray(data) ? data : [])
  })

  useListener<number>('minigames:setTotalPlayers', (count) => {
    if (typeof count === 'number' && Number.isFinite(count)) setTotalPlayers(count)
  })

  const loadRooms = async (gameModeId: string) => {
    const data = await fetchData<Room[]>('minigames:getRooms', { gameMode: gameModeId }, MOCK_ROOMS)
    setRooms(Array.isArray(data) ? data : [])
  }

  const handleSelectMode = (mode: GameMode) => {
    setSelectedMode(mode)
    setScreen('rooms')
    setPanelMode(null)
    loadRooms(mode.id)
  }

  useEffect(() => {
    if (preselectAppliedRef.current) return
    if (!preselectedMode) return
    const mode = gameModes.find((m) => m.id === preselectedMode)
    if (!mode) return
    preselectAppliedRef.current = true
    consumePreselectedMode()
    handleSelectMode(mode)
  }, [preselectedMode, gameModes, consumePreselectedMode])

  useEffect(() => {
    if (!preselectedMode) preselectAppliedRef.current = false
  }, [preselectedMode])

  const handleSelectRoom = (room: Room) => {
    setSelectedRoom(room)
    setPanelMode('view')
  }

  const handleOpenCreate = () => {
    setSelectedRoom(null)
    setPanelMode('create')
  }

  const handleClosePanel = () => {
    setPanelMode(null)
    setSelectedRoom(null)
  }

  const handleBackToModes = () => {
    setScreen('gamemode')
    setPanelMode(null)
    setSelectedRoom(null)
    setSelectedMode(null)
    setRooms([])
  }

  const handleRefreshRooms = () => {
    if (selectedMode) loadRooms(selectedMode.id)
  }

  const handleEnterRoom = () => {
    if (!selectedRoom) return
    if (selectedRoom.isPrivate) {
      setShowPasswordModal(true)
    } else {
      fetchData('minigames:joinRoom', { roomId: selectedRoom.id })
    }
  }

  const handlePasswordConfirm = (password: string) => {
    if (!selectedRoom) return
    setShowPasswordModal(false)
    fetchData('minigames:joinRoom', { roomId: selectedRoom.id, password })
  }

  const handleCreateRoom = (data: CreateRoomData) => {
    if (!selectedMode) return
    fetchData('minigames:createRoom', { ...data, gameMode: selectedMode.id })
  }

  const handleSelectSafeZone = (zoneId: string) => {
    fetchData('safezone:select', { zoneId })
    consumeSafeZones()
    close()
  }

  const handleCloseSafeZone = () => {
    consumeSafeZones()
    close()
  }

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key !== 'h' && e.key !== 'H') return
      if (showPasswordModal) return
      close()
    }
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [close, showPasswordModal])

  return (
    <div className="relative w-full h-full overflow-hidden">
      <div
        style={{
          position: 'absolute',
          width: '1920px',
          height: '1080px',
          fontSize: '16px',
          transformOrigin: 'top left',
          transform: `translate(${offsetX}px, ${offsetY}px) scale(${scale})`,
        }}
      >
        {safeZones && (
          <div
            className="absolute -translate-x-1/2 -translate-y-1/2"
            style={{ left: '50%', top: '50%' }}
          >
            <SafeZonePanel
              zones={safeZones}
              onSelect={handleSelectSafeZone}
              onClose={handleCloseSafeZone}
            />
          </div>
        )}

        {!safeZones && screen === 'gamemode' && (
          <GameModePanel modes={gameModes} onSelectMode={handleSelectMode} />
        )}

        {!safeZones && screen === 'rooms' && (
          <>
            <div className="absolute left-1/2 -translate-x-1/2 -translate-y-1/2 top-[calc(50%+0.5px)]">
              <RoomListPanel
                rooms={rooms}
                totalPlayers={totalPlayers}
                activeRooms={rooms.length}
                selectedRoomId={selectedRoom?.id}
                modeName={selectedMode?.name}
                onSelectRoom={handleSelectRoom}
                onCreateRoom={handleOpenCreate}
                onRefresh={handleRefreshRooms}
              />
            </div>

            {panelMode === 'view' && selectedRoom && (
              <div
                className="absolute -translate-x-1/2 -translate-y-1/2"
                style={{ left: 'calc(81.25% - 50px)', top: 'calc(50% - 55.5px)' }}
              >
                <RoomDetailsPanel
                  room={selectedRoom}
                  onClose={handleClosePanel}
                  onEnter={handleEnterRoom}
                />
              </div>
            )}

            {panelMode === 'create' && (
              <div
                className="absolute -translate-x-1/2 -translate-y-1/2"
                style={{ left: 'calc(81.25% - 50px)', top: 'calc(50% - 55.5px)' }}
              >
                <CreateRoomPanel
                  gameModeId={selectedMode?.id}
                  onClose={handleClosePanel}
                  onSubmit={handleCreateRoom}
                />
              </div>
            )}
          </>
        )}

        {showPasswordModal && selectedRoom && createPortal(
          <PasswordModal
            roomOwner={selectedRoom.owner}
            onConfirm={handlePasswordConfirm}
            onClose={() => setShowPasswordModal(false)}
          />,
          document.body
        )}
      </div>
    </div>
  )
}
