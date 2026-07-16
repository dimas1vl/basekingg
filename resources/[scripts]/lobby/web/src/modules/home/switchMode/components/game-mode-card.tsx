import { useRef, useState } from 'react'
import { CIRCUIT_A, TEXTURE } from './modes-data'

export type GameModeCardProps = {
  label: string
  video?: string
  color?: string
  hoverColor?: string
  overlayOpacity?: number
  circuit?: string
  hoverCircuit?: string
  hoverCircuitWhite?: boolean
  rotation?: number
  selectedBorder?: string
  badge?: string
  selected?: boolean
  onClick?: () => void
}

const DEFAULT_IMG = new URL('/defaultMode.png', import.meta.url).href
const BG_NEWS = new URL('/bg-news.svg', import.meta.url).href

export function GameModeCard({
  label,
  video,
  color = '#c0c0c0',
  overlayOpacity = 0.35,
  circuit = CIRCUIT_A,
  hoverCircuit,
  hoverCircuitWhite = false,
  rotation = 0.61,
  selectedBorder = '#9d0de9',
  badge,
  selected = false,
  onClick,
}: GameModeCardProps) {
  const videoRef = useRef<HTMLVideoElement>(null)
  const [hovered, setHovered] = useState(false)

  const isActive = hovered || selected
  const activeCircuit = isActive && hoverCircuit ? hoverCircuit : circuit
  const circuitStyle = isActive && hoverCircuitWhite
    ? { filter: 'brightness(0) invert(1)' }
    : undefined

  const handleMouseEnter = () => {
    setHovered(true)
    videoRef.current?.play()
  }
  const handleMouseLeave = () => {
    setHovered(false)
    const v = videoRef.current
    if (!v) return
    v.pause()
    v.currentTime = 0
  }

  return (
    <div
      className="relative h-full w-full cursor-pointer"
      onClick={onClick}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
    >
      {/* Back card */}
      <div
        className="absolute overflow-hidden pointer-events-none"
        style={{ inset: '-0.784rem 1.205rem -0.479rem -0.696rem', transform: 'rotate(-0.66deg) skewX(-0.01deg)' }}
      >
        <div className="absolute inset-0" style={{ backgroundColor: color }} />
        <img src={TEXTURE} alt="" className="absolute inset-0 size-full object-cover opacity-50 pointer-events-none" />
        <div className="absolute inset-0" style={{ backgroundColor: `rgba(0,0,0,${overlayOpacity})` }} />
      </div>

      {/* Main card */}
      <div
        className="absolute flex flex-col overflow-hidden"
        style={{
          inset: '0 0.022rem -0.037rem -0.644rem',
          transform: `rotate(${rotation}deg)`,
          border: isActive ? `0.6rem solid ${selectedBorder}` : 'none',
        }}
      >
        {/* Fundo */}
        <div className="absolute inset-0 pointer-events-none">
          <div className="absolute inset-0" style={{ backgroundColor: color }} />
          <div className="absolute inset-0" style={{ backgroundImage: 'linear-gradient(260deg, rgba(0,0,0,0) 9%, rgba(0,0,0,0.2) 50%, rgba(0,0,0,0) 91%)' }} />
        </div>

        {/* Circuito */}
        <div className="absolute pointer-events-none -scale-x-100" style={{ inset: '-9.4rem -8.359rem -9.452rem -8.277rem' }}>
          <img src={activeCircuit} alt="" className="absolute inset-0 size-full block max-w-none" style={circuitStyle} />
        </div>

        {/* Mídia */}
        <div className="relative flex-1 min-h-0 w-full">
          <div className="absolute inset-x-[1rem] top-[1rem] bottom-0">
            {video ? (
              <video
                ref={videoRef}
                src={video}
                className="absolute inset-0 size-full object-cover pointer-events-none"
                muted loop playsInline preload="auto"
              />
            ) : (
              <img src={DEFAULT_IMG} alt="" className="absolute inset-0 size-full object-cover pointer-events-none" />
            )}
          </div>
        </div>

        {/* Rodapé */}
        <div className="relative flex items-center justify-center py-[2rem] shrink-0 w-full">
          <span className="text-[1.6rem] font-bold text-[#1d1c26] text-center whitespace-nowrap">{label}</span>
          <div className="absolute bottom-[0.6rem] right-0 flex items-center gap-px opacity-55">
            <div className="bg-[#1d1c26] px-[0.2rem] flex items-center">
              <span className="text-[1rem] font-medium text-[#f8efff]">KINGG</span>
            </div>
            <div className="bg-[#1d1c26] self-stretch w-[0.6rem]" />
            <div className="bg-[#1d1c26] self-stretch w-[0.4rem]" />
            <div className="bg-[#1d1c26] self-stretch w-[0.3rem]" />
            <div className="bg-[#1d1c26] self-stretch w-[0.1rem]" />
          </div>
        </div>

        {/* Badge */}
        {badge && (
          <div className="absolute left-1/2 -translate-x-1/2 top-[1rem] flex flex-col items-center z-10">
            <div
              className="relative flex items-center justify-center pt-[0.6rem] px-[0.6rem] overflow-hidden"
              style={{ backgroundImage: `url(${BG_NEWS})`, backgroundSize: 'cover', backgroundPosition: 'center' }}
            >
              <span className="relative text-[1.6rem] font-bold text-[#1d1c26]">{badge}</span>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
