import { useEffect, useRef, useState } from 'react'
import { FieldCard } from './components/FieldCard'
import { FieldDivider } from './components/FieldDivider'
import { NuiInput } from './components/NuiInput'
import openUrl from '@/utils/openUrl'
import { fetchData } from '@/utils/fetchData'

function useUIScale() {
  const [scale, setScale] = useState(1)
  useEffect(() => {
    const update = () => setScale(Math.min(window.innerWidth / 1920, window.innerHeight / 1080, 1))
    update()
    window.addEventListener('resize', update)
    return () => window.removeEventListener('resize', update)
  }, [])
  return scale
}

export default function Home() {
  const scale = useUIScale()

  const [nickname, setNickname] = useState('')
  const [nicknameError, setNicknameError] = useState(false)
  const [day, setDay] = useState('')
  const [month, setMonth] = useState('')
  const [year, setYear] = useState('')
  const [gender, setGender] = useState<'masculino' | 'feminino'>('masculino')
  const [accepted, setAccepted] = useState(false)
  const [checkHover, setCheckHover] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [formError, setFormError] = useState<string | null>(null)

  const checkTimer = useRef<ReturnType<typeof setTimeout> | null>(null)

  useEffect(() => {
    if (checkTimer.current) clearTimeout(checkTimer.current)
    setNicknameError(false)
    if (nickname.length < 3) return
    checkTimer.current = setTimeout(async () => {
      const res = await fetchData<{ available: boolean }>(
        'checkName',
        { name: nickname },
        { available: true },
      )
      setNicknameError(!res.available)
    }, 500)
    return () => {
      if (checkTimer.current) clearTimeout(checkTimer.current)
    }
  }, [nickname])

  async function handleRegister() {
    if (submitting) return
    setFormError(null)

    if (!nickname || nickname.length < 3 || nickname.length > 20) {
      setFormError('Nickname deve ter entre 3 e 20 caracteres.')
      return
    }
    if (nicknameError) {
      setFormError('Escolha um nickname disponível.')
      return
    }
    if (!day || !month || !year) {
      setFormError('Preencha a data de nascimento completa.')
      return
    }
    if (!accepted) {
      setFormError('Aceite os termos de serviço para continuar.')
      return
    }

    setSubmitting(true)
    const res = await fetchData<{ ok: boolean; error?: string }>(
      'register',
      {
        name: nickname,
        gender: gender === 'masculino' ? 'male' : 'female',
        birthdate: { day: Number(day), month: Number(month), year: Number(year) },
      },
      { ok: true },
    )
    setSubmitting(false)

    if (!res.ok) {
      if (res.error === 'name_taken') {
        setNicknameError(true)
        setFormError('Nickname já está em uso.')
      } else if (res.error === 'birthdate_invalid') {
        setFormError('Data de nascimento inválida.')
      } else {
        setFormError('Ocorreu um erro. Tente novamente.')
      }
    }
  }

  return (
    <div className="w-screen h-screen overflow-hidden relative bg-[#1d1c26]">
      <img
        src={new URL('/background.png', import.meta.url).href}
        alt=""
        className="absolute inset-0 size-full object-cover pointer-events-none"
        draggable={false}
      />

      <div className="absolute inset-0 flex items-center justify-center">
        <div
          className="relative shrink-0 overflow-hidden"
          style={{
            width: 1920,
            height: 1080,
            transform: `scale(${scale})`,
            transformOrigin: 'center',
          }}
        >
          <div
            className="absolute"
            style={{ top: 50, left: '50%', transform: 'translateX(-50%)', width: 148, height: 109 }}
          >
            <img
              src={new URL('/logo.png', import.meta.url).href}
              alt="KINGG"
              className="absolute inset-0 size-full object-contain"
              draggable={false}
            />
          </div>

          <div
            className="absolute flex flex-col"
            style={{ top: 218, left: '50%', transform: 'translateX(-50%)', width: 410, gap: 8 }}
          >
            <div className="flex flex-col items-center w-full" style={{ gap: 6 }}>
              <div
                className="bg-[rgba(248,239,255,0.05)] flex items-center justify-center w-full"
                style={{ paddingLeft: 36, paddingRight: 32, paddingTop: 12, paddingBottom: 12 }}
              >
                <span className="text-[#f8efff] text-[24px] font-bold tracking-widest uppercase">
                  CRIAR CONTA
                </span>
              </div>
              <p
                className="text-[12px] text-[rgba(248,239,255,0.55)] text-center w-full"
                style={{ lineHeight: 1.6 }}
              >
                Chegou o momento de iniciar sua jornada, a busca para se tornar o melhor e mais
                temido se inicia aqui, determine o seu apelido, pelo qual será lembrado!
              </p>
            </div>

            <div
              className="flex items-center justify-center"
              style={{ width: 152, height: 41, marginLeft: 'auto', marginRight: 'auto' }}
            >
              <img
                src={new URL('/arrow.svg', import.meta.url).href}
                alt=""
                style={{ height: 27, objectFit: 'contain', transform: 'rotate(-5.48deg)' }}
              />
            </div>

            <div className="flex flex-col w-full" style={{ gap: 24 }}>
              <div className="flex flex-col">
                <FieldCard label="SEU NICKNAME">
                  <div className="relative flex items-center">
                    <NuiInput
                      placeholder="Ex: rACCOzr"
                      value={nickname}
                      onChange={(e) => setNickname(e.target.value)}
                    />
                    {nicknameError && (
                      <span className="absolute right-[5px] text-[#ff5858] text-[10px] whitespace-nowrap">
                        *NICKNAME JÁ ESTÁ EM USO
                      </span>
                    )}
                  </div>
                </FieldCard>
                <FieldDivider />
              </div>

              <div className="flex flex-col">
                <FieldCard label="DATA DE NASCIMENTO">
                  <div className="flex" style={{ gap: 4 }}>
                    <NuiInput
                      placeholder="DIA"
                      value={day}
                      onChange={(e) => setDay(e.target.value)}
                    />
                    <NuiInput
                      placeholder="MÊS"
                      value={month}
                      onChange={(e) => setMonth(e.target.value)}
                    />
                    <NuiInput
                      placeholder="ANO"
                      value={year}
                      onChange={(e) => setYear(e.target.value)}
                    />
                  </div>
                </FieldCard>
                <FieldDivider />
              </div>

              {/* Gender */}
              <div className="flex flex-col">
                <FieldCard label="GÊNERO">
                  <div className="flex items-center" style={{ height: 42, gap: 5 }}>
                    <button
                      onClick={() =>
                        setGender((g) => (g === 'masculino' ? 'feminino' : 'masculino'))
                      }
                      className="bg-[rgba(248,239,255,0.1)] flex items-center justify-center shrink-0 h-full"
                      style={{ width: 48 }}
                    >
                      <img
                        src={new URL('/CaretRight.png', import.meta.url).href}
                        alt=""
                        className="rotate-180"
                        style={{ width: 24, height: 24 }}
                      />
                    </button>
                    <div className="flex flex-1 h-full border-2 border-[rgba(248,239,255,0.1)] overflow-hidden">
                      <button
                        onClick={() => setGender('masculino')}
                        className={`flex-1 text-[12px] font-bold text-center transition-colors ${
                          gender === 'masculino' ? 'bg-[#f8efff] text-[#1d1c26]' : 'text-[#f8efff]'
                        }`}
                      >
                        MASCULINO
                      </button>
                      <button
                        onClick={() => setGender('feminino')}
                        className={`flex-1 text-[12px] font-bold text-center transition-colors ${
                          gender === 'feminino' ? 'bg-[#f8efff] text-[#1d1c26]' : 'text-[#f8efff]'
                        }`}
                      >
                        FEMININO
                      </button>
                    </div>
                    <button
                      onClick={() =>
                        setGender((g) => (g === 'masculino' ? 'feminino' : 'masculino'))
                      }
                      className="bg-[rgba(248,239,255,0.1)] flex items-center justify-center shrink-0 h-full"
                      style={{ width: 48 }}
                    >
                      <img src={new URL('/CaretRight.png', import.meta.url).href} alt="" style={{ width: 24, height: 24 }} />
                    </button>
                  </div>
                </FieldCard>
                <FieldDivider />
              </div>

              <div className="flex flex-col items-center w-full">
                <button
                  onClick={() => setAccepted((a) => !a)}
                  onMouseEnter={() => setCheckHover(true)}
                  onMouseLeave={() => setCheckHover(false)}
                  className="bg-[rgba(248,239,255,0.05)] w-full flex items-center justify-center"
                  style={{ paddingTop: 8, paddingBottom: 8 }}
                >
                  <div style={{ width: 40, height: 27, position: 'relative' }}>
                    <img
                      src={new URL('/uncheck.png', import.meta.url).href}
                      alt=""
                      style={{
                        position: 'absolute',
                        bottom: 0,
                        width: 40,
                        height: 20,
                        opacity: !accepted && !checkHover ? 1 : 0,
                        transition: 'opacity 0.1s',
                      }}
                    />
                    <img
                      src={new URL('/uncheck-hover.png', import.meta.url).href}
                      alt=""
                      style={{
                        position: 'absolute',
                        bottom: 0,
                        width: 40,
                        height: 20,
                        opacity: !accepted && checkHover ? 1 : 0,
                        transition: 'opacity 0.1s',
                      }}
                    />
                    <img
                      src={new URL('/check.png', import.meta.url).href}
                      alt=""
                      style={{
                        position: 'absolute',
                        bottom: 0,
                        width: 40,
                        height: 27,
                        opacity: accepted ? 1 : 0,
                        transition: 'opacity 0.1s',
                      }}
                    />
                  </div>
                </button>
                <div className="bg-[rgba(29,28,38,0.55)] w-full" style={{ padding: 8 }}>
                  <p className="text-[#f8efff] text-[14px] text-center opacity-55">
                    Sim, li e concordo com os termos de serviço do KINGG, me responsabilizo por
                    todos os atos realizados dentro do servidor.
                  </p>
                </div>
                <div
                  className="bg-[rgba(29,28,38,0.75)] w-full flex items-center justify-center"
                  style={{ padding: 8 }}
                >
                  <button
                    className="text-[#f8efff] text-[14px] underline"
                    onClick={() => openUrl('https://termos.kingg.com')}
                  >
                    LER Termos De Serviço
                  </button>
                </div>
              </div>

              {formError && <p className="text-[#ff5858] text-[11px] text-center">{formError}</p>}

              <button
                onClick={handleRegister}
                disabled={submitting}
                className="w-full bg-[rgba(248,239,255,0.1)] border-2 border-[rgba(248,239,255,0.1)] flex items-center justify-center text-[#f8efff] text-[16px] font-bold tracking-widest uppercase hover:bg-[rgba(248,239,255,0.15)] transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                style={{ height: 56 }}
              >
                {submitting ? 'AGUARDE...' : 'CRIAR'}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
