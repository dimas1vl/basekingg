import { useEffect, useState } from 'react'
import { useListener } from '@/hooks/listener'
import { nuiPost } from '@/utils/nui'
import { fmtInt } from '@/utils/fmt'
import type { ShopState } from '@/types/domination'
import { imgHubLogo } from './assets'
import TeamPanel from './components/TeamPanel'

const TABS: Array<{ key: string; label: string }> = [
  { key: 'inicio', label: 'INÍCIO' },
  { key: 'armario', label: 'ARMÁRIO' },
  { key: 'time', label: 'MEU TIME' },
  { key: 'caixas', label: 'CAIXAS / INVENTÁRIO' },
  { key: 'config', label: 'CONFIGURAÇÕES' },
]

export default function HubOverlay() {
  const [open, setOpen] = useState(false)
  const [tab, setTab] = useState('inicio')
  const [level, setLevel] = useState(1)
  const [money, setMoney] = useState(0)

  useListener<{ value: boolean }>('hub:visible', ({ value }) => setOpen(!!value))

  // o nível/dinheiro da navbar vêm do mesmo estado da loja (Dom.state)
  useListener<{ data: ShopState }>('shop', ({ data }) => {
    if (!data) return
    setLevel(data.level || 1)
    setMoney(data.gems || 0)
  })

  function closeHub() {
    setOpen(false)
    nuiPost('hub:close')
  }

  useEffect(() => {
    if (!open) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') closeHub()
    }
    document.addEventListener('keydown', onKey)
    return () => document.removeEventListener('keydown', onKey)
  }, [open])

  return (
    <div id="dom-hub-overlay" className={open ? 'shown' : ''}>
      <div id="dom-hub-navbar">
        <div className="hub-brand">
          <img src={imgHubLogo} alt="" />
        </div>

        <nav>
          {TABS.map((t) => (
            <button
              key={t.key}
              className={`hub-tab${tab === t.key ? ' active' : ''}`}
              onClick={() => setTab(t.key)}
            >
              {t.label}
            </button>
          ))}
        </nav>

        <div className="hub-right">
          <div className="hub-lv">
            <span>LV {level}</span>
          </div>
          <div className="hub-gems">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
              <path d="M11.8 10.9c-2.27-.59-3-1.2-3-2.15 0-1.09 1.01-1.85 2.7-1.85 1.78 0 2.44.85 2.5 2.1h2.21c-.07-1.72-1.12-3.3-3.21-3.81V3h-3v2.16c-1.94.42-3.5 1.68-3.5 3.61 0 2.31 1.91 3.46 4.7 4.13 2.5.6 3 1.48 3 2.41 0 .69-.49 1.79-2.7 1.79-2.06 0-2.87-.92-2.98-2.1h-2.2c.12 2.19 1.76 3.42 3.68 3.83V21h3v-2.15c1.95-.37 3.5-1.5 3.5-3.55 0-2.84-2.43-3.81-4.7-4.4z" />
            </svg>
            <span className="hub-gem-count">{fmtInt(money)} Dinheiro</span>
          </div>
          <button className="hub-gems-add" type="button">
            +
          </button>
        </div>
      </div>

      <div id="dom-hub-divider" />

      <div id="dom-hub-content">
        <TeamPanel shown={open && tab === 'time'} />
      </div>

      <div id="dom-hub-footer">
        <div className="hub-hint">
          <span className="hub-key">F1</span>
          <span>FECHAR HUB</span>
        </div>
        <button id="dom-hub-exit" type="button" onClick={() => { closeHub(); nuiPost('hub:exit') }}>
          SAIR DA DOMINAÇÃO
        </button>
      </div>
    </div>
  )
}
