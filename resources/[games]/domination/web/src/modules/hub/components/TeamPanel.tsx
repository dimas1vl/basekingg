import { useEffect, useRef, useState } from 'react'
import { useListener } from '@/hooks/listener'
import { nuiPost } from '@/utils/nui'
import type { TeamMember, TeamRole, TeamState } from '@/types/domination'

const ROLE_COLORS: Record<string, string> = {
  lider: '#fedb4e',
  gerente: '#c08bff',
  sublider: '#6ce8ff',
  recrutador: '#c8fe4e',
  membro: 'rgba(248,239,255,0.55)',
}

const ROLE_ORDER: TeamRole[] = ['gerente', 'sublider', 'recrutador', 'membro']

function roleLabel(d: TeamState, r: string): string {
  return (d.roleLabels && d.roleLabels[r as TeamRole]) || r
}

function copyText(t: string) {
  try {
    if (navigator.clipboard) {
      navigator.clipboard.writeText(t)
      return
    }
  } catch {
    /* noop */
  }
  try {
    const i = document.createElement('textarea')
    i.value = t
    document.body.appendChild(i)
    i.select()
    document.execCommand('copy')
    document.body.removeChild(i)
  } catch {
    /* noop */
  }
}

/* ===================== Modal próprio ===================== */
interface ModalInput {
  placeholder?: string
  value?: string
  maxlength?: number
  readonly?: boolean
}

interface ModalOpts {
  title: string
  message?: string
  input?: ModalInput
  confirmText?: string
  cancelText?: string | null
  danger?: boolean
  onConfirm?: (value: string) => void
}

function TeamModal({ opts, onClose }: { opts: ModalOpts; onClose: () => void }) {
  const inputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    if (inputRef.current && opts.input && !opts.input.readonly) {
      try {
        inputRef.current.focus()
      } catch {
        /* noop */
      }
    }
  }, [opts])

  function done(ok: boolean) {
    const val = inputRef.current ? inputRef.current.value : ''
    onClose()
    if (ok && typeof opts.onConfirm === 'function') opts.onConfirm(val)
  }

  return (
    <div id="dom-team-modal" onMouseDown={(e) => { if (e.target === e.currentTarget) done(false) }}>
      <div className="tm-box">
        <div className="tm-head">{opts.title || ''}</div>
        <div className="tm-body">
          {opts.message && <div>{opts.message}</div>}
          {opts.input && (
            <input
              ref={inputRef}
              className="tm-input"
              placeholder={opts.input.placeholder || ''}
              maxLength={opts.input.maxlength || 255}
              readOnly={opts.input.readonly}
              defaultValue={opts.input.value ?? ''}
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  e.preventDefault()
                  done(true)
                }
              }}
            />
          )}
        </div>
        <div className="tm-foot">
          {opts.cancelText !== null && (
            <button className="tm-btn cancel" onClick={() => done(false)}>
              {opts.cancelText || 'Cancelar'}
            </button>
          )}
          <button className={`tm-btn ${opts.danger ? 'danger' : 'ok'}`} onClick={() => done(true)}>
            {opts.confirmText || 'OK'}
          </button>
        </div>
      </div>
    </div>
  )
}

/* ===================== Last login ===================== */
function LastLogin({ m }: { m: TeamMember }) {
  if (m.online) {
    return (
      <span className="last">
        <span className="dot" />
        Online
      </span>
    )
  }
  if (!m.lastLogin) return <span className="last">—</span>
  const s = String(m.lastLogin).replace('T', ' ').slice(0, 16)
  return <span className="last">{s}</span>
}

/* ===================== Painel de time ===================== */
export default function TeamPanel({ shown }: { shown: boolean }) {
  const [data, setData] = useState<TeamState | null>(null)
  const [filter, setFilter] = useState('')
  const [modal, setModal] = useState<ModalOpts | null>(null)
  const nameRef = useRef<HTMLInputElement>(null)

  useListener<{ data: TeamState }>('team', ({ data: d }) => setData(d ?? null))

  // ao abrir a aba TIME, pede o estado atualizado
  useEffect(() => {
    if (shown) nuiPost('team:request')
  }, [shown])

  // fecha modal quando a aba/hub fecha
  useEffect(() => {
    if (!shown) setModal(null)
  }, [shown])

  function renderEmpty(d: TeamState | null) {
    const inv = d?.invite
    return (
      <>
        {inv && (
          <div className="team-invite">
            <div className="ti-title">CONVITE DE TIME</div>
            <div className="ti-sub">
              <b>{inv.from}</b> te convidou para o time <b>{inv.team}</b>
            </div>
            <div className="ti-actions">
              <button className="ti-accept" onClick={() => nuiPost('team:accept')}>
                ACEITAR
              </button>
              <button className="ti-decline" onClick={() => nuiPost('team:decline')}>
                RECUSAR
              </button>
            </div>
          </div>
        )}
        <div className="team-empty">
          <div className="team-empty-title">VOCÊ NÃO ESTÁ EM UM TIME</div>
          <div className="team-empty-sub">Crie seu time e monte sua equipe.</div>
          <input ref={nameRef} className="team-name-input" maxLength={24} placeholder="NOME DO TIME" />
          <button
            className="team-create-btn"
            onClick={() => {
              const v = (nameRef.current?.value || '').trim()
              if (v.length < 3) return
              nuiPost('team:create', { name: v })
            }}
          >
            CRIAR TIME
          </button>
        </div>
      </>
    )
  }

  function renderPanel(d: TeamState) {
    const caps = d.caps || {}
    const c = d.counts || {}
    const f = filter.toLowerCase()
    const members = (d.members || []).filter(
      (m) => !f || String(m.id).includes(f) || (m.name || '').toLowerCase().includes(f),
    )

    return (
      <div className="team-panel">
        <div className="team-head">
          <div className="team-head-left">
            <div className="team-logo">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor">
                <circle cx="12" cy="8" r="4" />
                <path d="M4 20c0-4 4-6 8-6s8 2 8 6z" />
              </svg>
            </div>
            <div className="team-name">
              {d.name}
              {d.premium ? (
                <span className="team-premium">PREMIUM</span>
              ) : (
                <span className="team-free">NÃO PREMIUM</span>
              )}
            </div>
          </div>
          <div className="team-head-right">
            <button className="team-btn discord" onClick={() => onDiscord(d)}>
              DISCORD
            </button>
            <button className="team-btn leave" onClick={() => onLeave(d)}>
              SAIR DO TIME
            </button>
          </div>
        </div>

        <div className="team-stats">
          <div className="team-stat">
            <span className="lbl">Membros</span>
            <span className="val">
              {d.memberCount} / {d.maxMembers}
            </span>
          </div>
          <div className="team-stat">
            <span className="lbl">Membros em atividade</span>
            <span className="val">{d.onlineCount}</span>
          </div>
          <div className="team-stat">
            <span className="lbl">Cargos</span>
            <span className="roles-line">
              <span>GERENTES {c.gerente || 0}/{caps.gerente || 0}</span>
              <span>SUB LÍDERES {c.sublider || 0}/{caps.sublider || 0}</span>
              <span>RECRUTADORES {c.recrutador || 0}/{caps.recrutador || 0}</span>
            </span>
          </div>
        </div>

        <div className="team-toolbar">
          <input
            className="team-search"
            placeholder="Pesquisar"
            value={filter}
            onChange={(e) => setFilter(e.target.value)}
          />
          {d.perms?.invite && (
            <button className="team-add" onClick={() => onAdd()}>
              ADICIONAR
            </button>
          )}
        </div>

        <div className="team-list">
          <div className="team-row head">
            <span>ID</span>
            <span>JOGADOR</span>
            <span>ÚLTIMO LOGIN</span>
            <span />
          </div>
          {members.map((m) => {
            const color = ROLE_COLORS[m.role] || '#aaa'
            return (
              <div className="team-row" key={m.id}>
                <span>{m.id}</span>
                <span className="pname">
                  {m.role === 'lider' && (
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="#fedb4e">
                      <path d="M3 7l4 3 5-5 5 5 4-3v10H3z" />
                    </svg>
                  )}
                  {m.name}
                  <span
                    className="role-badge"
                    style={{ background: `${color}22`, color, border: `1px solid ${color}66` }}
                  >
                    {roleLabel(d, m.role)}
                  </span>
                </span>
                <LastLogin m={m} />
                <span className="actions">
                  {d.perms?.promote && m.role !== 'lider' && (
                    <select
                      value={m.role}
                      onChange={(e) => nuiPost('team:setrole', { id: m.id, role: e.target.value })}
                    >
                      {ROLE_ORDER.map((r) => (
                        <option key={r} value={r}>
                          {roleLabel(d, r)}
                        </option>
                      ))}
                    </select>
                  )}
                  {d.perms?.kick && m.role !== 'lider' && (
                    <button className="kick" title="Expulsar" onClick={() => onKick(m.id)}>
                      ✕
                    </button>
                  )}
                </span>
              </div>
            )
          })}
        </div>
      </div>
    )
  }

  /* ---- handlers de modal ---- */
  function onKick(id: number) {
    setModal({
      title: 'Expulsar Membro',
      message: 'Tem certeza que deseja expulsar esse membro do time?',
      confirmText: 'Expulsar',
      danger: true,
      onConfirm: () => nuiPost('team:kick', { id }),
    })
  }

  function onDiscord(d: TeamState) {
    if (d.perms?.setDiscord) {
      setModal({
        title: 'Discord do Time',
        input: { placeholder: 'https://discord.gg/...', value: d.discord || '', maxlength: 255 },
        confirmText: 'Salvar',
        onConfirm: (v) => nuiPost('team:setdiscord', { url: (v || '').trim() }),
      })
    } else if (d.discord) {
      setModal({
        title: 'Discord do Time',
        input: { value: d.discord, readonly: true },
        confirmText: 'Copiar',
        cancelText: 'Fechar',
        onConfirm: (v) => copyText(v),
      })
    } else {
      setModal({ title: 'Discord do Time', message: 'Nenhum link de Discord definido.', confirmText: 'OK', cancelText: null })
    }
  }

  function onLeave(d: TeamState) {
    const msg =
      d.myRole === 'lider'
        ? 'Você é o líder — sair vai DESFAZER o time. Confirmar?'
        : 'Tem certeza que deseja sair do time?'
    setModal({ title: 'Sair do Time', message: msg, confirmText: 'Sair', danger: true, onConfirm: () => nuiPost('team:leave') })
  }

  function onAdd() {
    setModal({
      title: 'Adicionar Jogador',
      input: { placeholder: 'ID ou nome do jogador' },
      confirmText: 'Adicionar',
      onConfirm: (v) => {
        const t = (v || '').trim()
        if (t) nuiPost('team:invite', { target: t })
      },
    })
  }

  return (
    <div id="dom-team-root" className={shown ? 'shown' : ''}>
      {data?.hasTeam ? renderPanel(data) : renderEmpty(data)}
      {modal && <TeamModal opts={modal} onClose={() => setModal(null)} />}
    </div>
  )
}
