import { useState } from 'react'
import { cn } from '@/lib/utils'
import { NovatIcon } from '@/components/icons'

type PerfilViewProps = {
  username: string
  team: string
  avatarSrc?: string
  backgroundSrc?: string
  variant?: 'default' | 'selected'
  onClick?: () => void
  className?: string
}

export function PerfilView({
  username,
  team,
  avatarSrc,
  backgroundSrc,
  variant = 'default',
  onClick,
  className,
}: PerfilViewProps) {
  const [hovered, setHovered] = useState(false)
  const isSelected = variant === 'selected'
  const showHover = hovered && !isSelected

  return (
    <div
      className={cn(
        'relative flex items-center justify-between px-[1.8rem] py-[0.8rem] w-full cursor-pointer',
        isSelected
          ? 'bg-gradient-to-r from-[#f8efff] to-[#424050] border-2 border-[rgba(248,239,255,0.25)] border-solid'
          : showHover
            ? 'bg-gradient-to-r from-[#f8efff] to-[#424050] border-[.1rem] border-[rgba(248,239,255,0.5)] border-solid'
            : '',
        className,
      )}
      onClick={onClick}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
    >
      {/* Background com imagem — só no estado normal */}
      {!isSelected && !showHover && backgroundSrc && (
        <>
          <img
            alt=""
            className="absolute inset-0 size-full max-w-none object-cover opacity-85 pointer-events-none"
            src={backgroundSrc}
          />
          <div className="absolute inset-0 bg-gradient-to-r from-[rgba(29,28,38,0.85)] to-[rgba(29,28,38,0)] pointer-events-none" />
        </>
      )}

      {/* Esquerda: avatar + info */}
      <div className="relative flex items-center gap-[1.2rem] shrink-0">
        <div
          className={cn(
            'relative shrink-0 size-[4.8rem] border-2 border-solid overflow-hidden',
            isSelected || showHover ? 'border-[#c8fe4e]' : 'border-[#f8efff]',
          )}
        >
          {avatarSrc && (
            <img
              alt={username}
              className="absolute inset-0 size-full object-cover"
              src={avatarSrc}
            />
          )}
        </div>
        <div className="flex flex-col gap-[0.4rem] items-start">
          <span
            className={cn(
              'text-[1.4rem] font-semibold whitespace-nowrap',
              isSelected || showHover ? 'text-[#1d1c26]' : 'text-white',
            )}
          >
            {username}
          </span>
          <span
            className={cn(
              'text-[1.4rem] font-medium whitespace-nowrap',
              isSelected || showHover ? 'text-[#1d1c26]' : 'text-[#c8fe4e]',
            )}
          >
            {team}
          </span>
        </div>
      </div>

      {/* Direita: ícone novat */}
      <div
        className={cn(
          'relative shrink-0 size-[4.8rem] rounded-full flex items-center justify-center overflow-hidden',
          isSelected || showHover ? 'bg-[rgba(29,28,38,0.35)]' : 'bg-[rgba(248,239,255,0.1)]',
        )}
      >
        <NovatIcon width={36} height={36} style={{ color: '#88cff5' }} />
      </div>

      {/* Badge VISUALIZAR — aparece no hover ou selected */}
      {(isSelected || showHover) && (
        <div
          className="absolute bg-[#1d1c26] flex items-center justify-center px-[0.8rem] py-[0.4rem] -translate-x-1/2"
          style={{ left: 'calc(50% + 3.7rem)', top: '50%', transform: 'translate(-50%, -50%)' }}
        >
          <span className="text-[1.4rem] font-medium text-[#c8fe4e] whitespace-nowrap">
            VISUALIZAR
          </span>
        </div>
      )}
    </div>
  )
}
