import { useState, useEffect, useRef } from 'react'
import imgIconClosePanel from '@/assets/minigames/icon-close-panel.svg'

type Props = {
  roomOwner: string
  onConfirm: (password: string) => void
  onClose: () => void
}

export default function PasswordModal({ roomOwner, onConfirm, onClose }: Props) {
  const [password, setPassword] = useState('')
  const inputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    inputRef.current?.focus()
  }, [])

  const handleConfirm = () => {
    if (password.trim()) onConfirm(password)
  }

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') handleConfirm()
    if (e.key === 'Escape') onClose()
  }

  return (
    <div
      className="fixed inset-0 flex items-center justify-center z-50"
      style={{ background: 'rgba(10,9,16,0.75)' }}
      onClick={(e) => { if (e.target === e.currentTarget) onClose() }}
    >
      <div className="flex flex-col items-start w-[380px]">
        <div className="bg-[rgba(29,28,38,0.98)] flex flex-col items-start px-[18px] py-[12px] w-full">
          <div className="border-mg-primary border-l-4 flex h-[24px] items-center justify-between pl-[16px] pr-[12px] w-full">
            <span className="font-termina font-medium text-[12px] text-mg-primary whitespace-nowrap">
              SALA PRIVADA
            </span>
            <button onClick={onClose} className="h-[12px] w-[30px] relative cursor-pointer">
              <img alt="" className="absolute inset-[-8.33%_-3.33%] block w-full h-full" src={imgIconClosePanel} />
            </button>
          </div>
        </div>

        <div className="bg-[rgba(29,28,38,0.98)] flex flex-col gap-[16px] items-start p-[18px] w-full border-t border-[rgba(248,239,255,0.06)]">
          <p className="font-termina font-medium text-[11px] text-[rgba(248,239,255,0.55)] whitespace-nowrap">
            SALA DE {roomOwner.toUpperCase()} REQUER SENHA
          </p>

          <div className="border border-[rgba(248,239,255,0.25)] flex h-[42px] items-center gap-[10px] overflow-hidden px-[12px] w-full">
            <input
              ref={inputRef}
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder="SENHA DA SALA"
              className="flex-1 bg-transparent font-termina font-medium text-[12px] text-mg-light placeholder:text-[rgba(248,239,255,0.3)] outline-none border-none"
            />
          </div>

          <div className="flex gap-[8px] w-full">
            <button
              onClick={onClose}
              className="bg-[rgba(248,239,255,0.05)] border border-[rgba(248,239,255,0.25)] flex flex-1 h-[41px] items-center justify-center cursor-pointer hover:bg-[rgba(248,239,255,0.1)] transition-colors"
            >
              <span className="font-termina font-semibold text-[12px] text-mg-light whitespace-nowrap">
                CANCELAR
              </span>
            </button>
            <button
              onClick={handleConfirm}
              disabled={!password.trim()}
              className="bg-mg-primary flex flex-1 h-[41px] items-center justify-center cursor-pointer hover:brightness-110 disabled:opacity-40 disabled:cursor-not-allowed transition-all"
            >
              <span className="font-termina font-semibold text-[12px] text-mg-bg whitespace-nowrap">
                CONFIRMAR
              </span>
            </button>
          </div>
        </div>

        <div className="h-[3px] w-full bg-mg-primary" />
      </div>
    </div>
  )
}
