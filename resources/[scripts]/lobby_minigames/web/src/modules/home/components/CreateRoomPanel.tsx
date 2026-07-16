import { useState, useRef, useEffect } from 'react'
import imgIconClosePanel from '@/assets/minigames/icon-close-panel.svg'
import imgIconDropdown from '@/assets/minigames/icon-dropdown.svg'
import imgFormFieldDecor from '@/assets/minigames/form-field-decor.svg'
import imgCheckOff from '@/assets/minigames/check-off.svg'
import imgCheckOnBg from '@/assets/minigames/check-on-bg.svg'
import imgCheckMark from '@/assets/minigames/check-mark.svg'
import imgDividerH from '@/assets/minigames/divider-h.png'

const MAPS = ['SANDY SHORES', 'CHUMASH', 'VINEWOOD HILLS', 'PALETO BAY', 'MOUNT CHILIAD']
const MAX_PLAYERS_OPTIONS = [2, 4, 6, 8, 10, 12, 16]

const CLUTCH_MAP_RANDOM = 'ALEATÓRIO'
const CLUTCH_VARIANT_LABELS = ['1V1', '1V2', '2V4', '3V5']
const CLUTCH_VARIANT_MAX_PLAYERS: Record<string, number> = {
  '1V1': 2,
  '1V2': 3,
  '2V4': 6,
  '3V5': 8,
}

import { CreateRoomData } from '../types'

type Props = {
  gameModeId?: string
  onClose: () => void
  onSubmit: (data: CreateRoomData) => void
}

export default function CreateRoomPanel({ gameModeId, onClose, onSubmit }: Props) {
  const isClutch = gameModeId === 'clutch'

  const initialVariantLabel = isClutch ? CLUTCH_VARIANT_LABELS[0] : ''
  const [map, setMap] = useState(isClutch ? CLUTCH_MAP_RANDOM : MAPS[0])
  const [maxPlayers, setMaxPlayers] = useState(isClutch ? CLUTCH_VARIANT_MAX_PLAYERS[initialVariantLabel] : 12)
  const [variantLabel, setVariantLabel] = useState<string>(initialVariantLabel)
  const [isPrivate, setIsPrivate] = useState(false)
  const [password, setPassword] = useState('')

  const handleVariantChange = (label: string) => {
    setVariantLabel(label)
    const mp = CLUTCH_VARIANT_MAX_PLAYERS[label]
    if (mp) setMaxPlayers(mp)
  }

  const submit = () => {
    const payload: CreateRoomData = {
      map,
      maxPlayers,
      isPrivate,
      ...(isPrivate && password ? { password } : {}),
      ...(isClutch ? { variant: variantLabel.toLowerCase() } : {}),
      ...(gameModeId ? { gameMode: gameModeId } : {}),
    }
    onSubmit(payload)
  }

  return (
    <div className="flex flex-col items-start w-[340px] h-[483px]">
      <div className="bg-[rgba(29,28,38,0.95)] flex flex-col items-start px-[18px] py-[12px] shrink-0 w-full">
        <div className="border-mg-primary border-l-4 flex h-[24px] items-center justify-between pl-[16px] pr-[12px] w-full">
          <span className="font-termina font-medium text-[12px] text-mg-primary text-center whitespace-nowrap">
            CRIAR SALA
          </span>
          <button onClick={onClose} className="h-[12px] w-[30px] relative cursor-pointer">
            <img alt="" className="absolute inset-[-8.33%_-3.33%] block w-full h-full" src={imgIconClosePanel} />
          </button>
        </div>
      </div>

      <div className="bg-[rgba(29,28,38,0.9)] flex flex-1 flex-col items-center justify-between min-h-0 p-[18px] w-full">
        <div className="flex flex-col gap-[12px] items-start w-full">
          <div className="flex flex-col gap-[4px] items-start w-full">
            <FieldLabel label="MAPA" />
            {isClutch ? (
              <FieldDropdown value={CLUTCH_MAP_RANDOM} options={[CLUTCH_MAP_RANDOM]} onChange={setMap} />
            ) : (
              <FieldDropdown value={map} options={MAPS} onChange={setMap} />
            )}
          </div>

          {isClutch ? (
            <div className="flex flex-col gap-[4px] items-start w-full">
              <FieldLabel label="FORMATO" />
              <FieldDropdown value={variantLabel} options={CLUTCH_VARIANT_LABELS} onChange={handleVariantChange} />
            </div>
          ) : (
            <div className="border-mg-light border-l-4 flex gap-[4px] items-start w-full">
              <div className="bg-[rgba(248,239,255,0.06)] flex flex-1 gap-[10px] items-center overflow-hidden px-[12px] py-[8px] relative self-stretch">
                <span className="font-termina font-medium text-[12px] text-mg-light whitespace-nowrap relative z-10">
                  QTD. DE JOGADORES
                </span>
                <FieldDecorBg />
              </div>
              <NumberDropdown value={maxPlayers} options={MAX_PLAYERS_OPTIONS} onChange={setMaxPlayers} />
            </div>
          )}

          <div className="bg-[rgba(248,239,255,0.06)] flex h-[42px] items-center justify-between overflow-hidden px-[12px] py-[8px] relative w-full">
            <span className="font-termina font-medium text-[12px] text-mg-light whitespace-nowrap relative z-10">
              SALA PRIVADA
            </span>
            <button
              onClick={() => setIsPrivate(!isPrivate)}
              className="group cursor-pointer relative z-10 shrink-0 w-[40px] h-[20px]"
            >
              {isPrivate ? (
                <>
                  <img alt="" className="absolute inset-0 w-full h-full" src={imgCheckOnBg} />
                  <div className="absolute w-[26px] h-[18.5px]" style={{ left: '10px', top: '-5px' }}>
                    <div className="absolute" style={{ inset: '-8.04% -5.15% -7.36% -3.96%' }}>
                      <img alt="" className="block w-full h-full" src={imgCheckMark} />
                    </div>
                  </div>
                </>
              ) : (
                <img
                  alt=""
                  className="absolute inset-0 w-full h-full opacity-35 group-hover:opacity-100 transition-opacity"
                  src={imgCheckOff}
                />
              )}
            </button>
            <FieldDecorBg />
          </div>

          <div className={`flex flex-col gap-[4px] items-start w-full transition-opacity ${isPrivate ? 'opacity-100' : 'opacity-35'}`}>
            <div className="bg-[rgba(248,239,255,0.06)] border-mg-light border-l-4 flex gap-[10px] h-[42px] items-center overflow-hidden px-[12px] py-[8px] relative w-full">
              <span className="font-termina font-medium text-[12px] text-mg-light whitespace-nowrap relative z-10">SENHA</span>
              <span className="font-termina font-medium text-[12px] text-mg-light whitespace-nowrap relative z-10">(SALA PRIVADA)</span>
              <FieldDecorBg />
            </div>
            <div className="border border-[rgba(248,239,255,0.25)] flex gap-[10px] h-[42px] items-center overflow-hidden p-[12px] w-full">
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                disabled={!isPrivate}
                className="flex-1 bg-transparent font-termina font-medium text-[12px] text-[rgba(248,239,255,0.55)] text-center outline-none border-none"
                placeholder="***********"
              />
            </div>
          </div>
        </div>

        <button
          onClick={submit}
          className="bg-mg-light flex h-[41px] items-center justify-center px-[12px] py-[4px] w-full cursor-pointer hover:brightness-95 transition-all shrink-0"
        >
          <span className="font-termina font-semibold text-[14px] text-mg-bg text-center whitespace-nowrap">CRIAR</span>
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

function FieldLabel({ label }: { label: string }) {
  return (
    <div className="bg-[rgba(248,239,255,0.06)] border-mg-light border-l-4 flex gap-[10px] h-[42px] items-center overflow-hidden px-[12px] py-[8px] relative shrink-0 w-full">
      <span className="font-termina font-medium text-[12px] text-mg-light whitespace-nowrap relative z-10">{label}</span>
      <FieldDecorBg />
    </div>
  )
}

function FieldDropdown({ value, options, onChange }: { value: string; options: string[]; onChange: (v: string) => void }) {
  const [open, setOpen] = useState(false)
  const ref = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false)
    }
    document.addEventListener('mousedown', handler)
    return () => document.removeEventListener('mousedown', handler)
  }, [])

  return (
    <div ref={ref} className="relative w-full">
      <button
        onClick={() => setOpen((o) => !o)}
        className="bg-[rgba(248,239,255,0.05)] border border-[rgba(248,239,255,0.25)] flex h-[42px] items-center justify-between px-[17px] py-px w-full cursor-pointer hover:bg-[rgba(248,239,255,0.1)] transition-colors"
      >
        <span className="font-termina font-semibold text-[12px] text-mg-light whitespace-nowrap leading-none">{value}</span>
        <img
          alt=""
          className="w-[9px] h-[16.5px] transition-transform"
          src={imgIconDropdown}
          style={{ transform: open ? 'rotate(-90deg)' : 'rotate(90deg)' }}
        />
      </button>

      {open && (
        <div className="absolute left-0 right-0 top-full z-50 border border-[rgba(248,239,255,0.25)] overflow-hidden" style={{ marginTop: '2px' }}>
          {options.map((opt) => (
            <button
              key={opt}
              onClick={() => { onChange(opt); setOpen(false) }}
              className={`flex h-[38px] items-center w-full px-[17px] cursor-pointer transition-colors font-termina font-medium text-[12px] whitespace-nowrap ${
                opt === value
                  ? 'bg-mg-primary text-mg-bg'
                  : 'bg-[#1d1c26] text-mg-light hover:bg-[#2a2935] hover:text-mg-primary'
              }`}
            >
              {opt}
            </button>
          ))}
        </div>
      )}
    </div>
  )
}

function NumberDropdown({ value, options, onChange }: { value: number; options: number[]; onChange: (v: number) => void }) {
  const [open, setOpen] = useState(false)
  const ref = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false)
    }
    document.addEventListener('mousedown', handler)
    return () => document.removeEventListener('mousedown', handler)
  }, [])

  return (
    <div ref={ref} className="relative shrink-0 w-[84px]">
      <button
        onClick={() => setOpen((o) => !o)}
        className="bg-[rgba(248,239,255,0.05)] border border-[rgba(248,239,255,0.25)] flex h-[42px] items-center justify-between px-[17px] py-px w-full cursor-pointer hover:bg-[rgba(248,239,255,0.1)] transition-colors"
      >
        <span className="font-termina font-semibold text-[12px] text-mg-light leading-none">{value}</span>
        <img
          alt=""
          className="w-[9px] h-[16.5px] transition-transform"
          src={imgIconDropdown}
          style={{ transform: open ? 'rotate(-90deg)' : 'rotate(90deg)' }}
        />
      </button>

      {open && (
        <div className="absolute left-0 right-0 top-full z-50 border border-[rgba(248,239,255,0.25)] overflow-hidden" style={{ marginTop: '2px' }}>
          {options.map((opt) => (
            <button
              key={opt}
              onClick={() => { onChange(opt); setOpen(false) }}
              className={`flex h-[34px] items-center justify-center w-full cursor-pointer transition-colors font-termina font-semibold text-[12px] whitespace-nowrap ${
                opt === value
                  ? 'bg-mg-primary text-mg-bg'
                  : 'bg-[#1d1c26] text-mg-light hover:bg-[#2a2935] hover:text-mg-primary'
              }`}
            >
              {opt}
            </button>
          ))}
        </div>
      )}
    </div>
  )
}

function FieldDecorBg() {
  return (
    <div
      className="absolute pointer-events-none"
      style={{ right: '-261.25px', top: '-224px', width: '427.246px', height: '399.069px' }}
    >
      <div style={{ transform: 'scaleY(-1) rotate(-122.02deg)', width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <img alt="" src={imgFormFieldDecor} style={{ width: '255.468px', height: '344.153px', display: 'block' }} />
      </div>
    </div>
  )
}
