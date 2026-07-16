import { useEffect, useRef, useState } from 'react'
import { useListener } from '@/hooks/listener'
import { nuiPost } from '@/utils/nui'
import {
  useSettings,
  cloneSettings,
  DEFAULT_SETTINGS,
  CATEGORY_LABELS,
  SFX_OPTIONS,
  FOOTSTEP_OPTIONS,
  WEATHER_OPTIONS,
  type DomSettings,
  type Rgb,
  type SfxKey,
} from '@/store/settings'

const SFX_BASE = new URL('sounds/', window.location.href).href

function playSfx(cat: string) {
  const audio = useSettings.getState().settings.audio as unknown as Record<
    string,
    { effect: string; volume: number } | undefined
  >
  const conf = audio?.[cat]
  if (!conf || typeof conf.volume !== 'number') return
  const vol = Math.max(0, Math.min(1, (conf.volume ?? 0) / 100))
  if (vol <= 0) return
  try {
    const a = new Audio(`${SFX_BASE}${cat}/${conf.effect || 'default'}.ogg`)
    a.volume = vol
    void a.play().catch(() => {})
  } catch {
    /* noop */
  }
}

export function AudioManager() {
  useListener<{ cat: string }>('sfx', ({ cat }) => {
    if (cat) playSfx(cat)
  })
  return null
}

export function SettingsSync() {
  const setSettings = useSettings((s) => s.setSettings)
  useListener<{ data: DomSettings }>('settings', ({ data }) => {
    if (data) setSettings(data)
  })
  return null
}

const toHex = (rgb: Rgb) =>
  '#' + rgb.map((c) => Math.max(0, Math.min(255, c | 0)).toString(16).padStart(2, '0')).join('')

const fromHex = (hex: string): Rgb => {
  const n = hex.replace('#', '')
  return [parseInt(n.slice(0, 2), 16) || 0, parseInt(n.slice(2, 4), 16) || 0, parseInt(n.slice(4, 6), 16) || 0]
}

function Row({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="set-row">
      <span className="set-row-lbl">{label}</span>
      <div className="set-row-ctrl">{children}</div>
    </div>
  )
}

function Toggle({ value, onChange }: { value: boolean; onChange: (v: boolean) => void }) {
  return (
    <button type="button" className={`set-toggle${value ? ' on' : ''}`} onClick={() => onChange(!value)}>
      <i />
      <span>{value ? 'ON' : 'OFF'}</span>
    </button>
  )
}

function Slider({
  value,
  min = 0,
  max = 100,
  onChange,
  suffix = '%',
}: {
  value: number
  min?: number
  max?: number
  onChange: (v: number) => void
  suffix?: string
}) {
  return (
    <div className="set-slider">
      <input
        type="range"
        min={min}
        max={max}
        value={value}
        onChange={(e) => onChange(Number(e.target.value))}
      />
      <span>
        {value}
        {suffix}
      </span>
    </div>
  )
}

function Color({ value, onChange }: { value: Rgb; onChange: (v: Rgb) => void }) {
  return (
    <input
      type="color"
      className="set-color"
      value={toHex(value)}
      onChange={(e) => onChange(fromHex(e.target.value))}
    />
  )
}

function Dropdown<T extends string>({
  value,
  options,
  onChange,
}: {
  value: T
  options: { value: T; label: string }[]
  onChange: (v: T) => void
}) {
  return (
    <select className="set-select" value={value} onChange={(e) => onChange(e.target.value as T)}>
      {options.map((o) => (
        <option key={o.value} value={o.value}>
          {o.label}
        </option>
      ))}
    </select>
  )
}

const TABS = [
  { key: 'hud', label: 'HUD' },
  { key: 'audio', label: 'ÁUDIO' },
  { key: 'game', label: 'JOGO' },
] as const

type TabKey = (typeof TABS)[number]['key']

export default function SettingsOverlays() {
  return (
    <>
      <SettingsSync />
      <AudioManager />
      <SettingsPanel />
    </>
  )
}

function SettingsPanel() {
  const [visible, setVisible] = useState(false)
  const [tab, setTab] = useState<TabKey>('hud')
  const [draft, setDraft] = useState<DomSettings>(DEFAULT_SETTINGS)
  const saveTimer = useRef<ReturnType<typeof setTimeout> | null>(null)

  useListener<{ value: boolean }>('settings:visible', ({ value }) => {
    if (value) setDraft(cloneSettings(useSettings.getState().settings))
    setVisible(!!value)
  })

  useEffect(() => {
    if (!visible) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') close()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [visible])

  function close() {
    setVisible(false)
    nuiPost('settings:close')
  }

  function commit(next: DomSettings) {
    setDraft(next)
    useSettings.getState().setSettings(cloneSettings(next))
    if (saveTimer.current) clearTimeout(saveTimer.current)
    saveTimer.current = setTimeout(() => nuiPost('settings:save', next), 200)
  }

  const setHud = <K extends keyof DomSettings['hud']>(key: K, val: DomSettings['hud'][K]) =>
    commit({ ...draft, hud: { ...draft.hud, [key]: val } })

  const setGame = <K extends keyof DomSettings['game']>(key: K, val: DomSettings['game'][K]) =>
    commit({ ...draft, game: { ...draft.game, [key]: val } })

  const setSfx = (cat: SfxKey, patch: Partial<{ effect: string; volume: number }>) =>
    commit({ ...draft, audio: { ...draft.audio, [cat]: { ...draft.audio[cat], ...patch } } })

  const setAudio = <K extends keyof DomSettings['audio']>(key: K, val: DomSettings['audio'][K]) =>
    commit({ ...draft, audio: { ...draft.audio, [key]: val } })

  function setHotbar(slotIndex: number, cat: string) {
    const order = [...draft.hud.hotbar]
    const prev = order[slotIndex]
    const dupe = order.indexOf(cat)
    if (dupe !== -1) order[dupe] = prev
    order[slotIndex] = cat
    setHud('hotbar', order)
  }

  return (
    <div id="dom-settings-overlay" className={visible ? 'shown' : ''}>
      <div id="dom-settings-panel">
        <div id="dom-settings-header">
          <span>CONFIGURAÇÕES</span>
          <button type="button" id="dom-settings-close" onClick={close}>
            ✕
          </button>
        </div>

        <div id="dom-settings-tabs">
          {TABS.map((t) => (
            <button
              key={t.key}
              type="button"
              className={`set-tab${tab === t.key ? ' active' : ''}`}
              onClick={() => setTab(t.key)}
            >
              {t.label}
            </button>
          ))}
        </div>

        <div id="dom-settings-body">
          {tab === 'hud' && (
            <>
              <div className="set-group">ATALHOS DA HOTBAR</div>
              {draft.hud.hotbar.map((cat, i) => (
                <Row key={i} label={`Tecla ${i + 1}`}>
                  <select className="set-select" value={cat} onChange={(e) => setHotbar(i, e.target.value)}>
                    {Object.keys(CATEGORY_LABELS).map((c) => (
                      <option key={c} value={c}>
                        {CATEGORY_LABELS[c]}
                      </option>
                    ))}
                  </select>
                </Row>
              ))}

              <div className="set-group">ELEMENTOS</div>
              <Row label="Anúncios de dominação">
                <Toggle value={draft.hud.announces} onChange={(v) => setHud('announces', v)} />
              </Row>
              <Row label="Barra de progresso (captura)">
                <Toggle value={draft.hud.progressBar} onChange={(v) => setHud('progressBar', v)} />
              </Row>

              <div className="set-group">MARCADORES</div>
              <Row label="Marcador de dano">
                <Toggle value={draft.hud.dmgMarker} onChange={(v) => setHud('dmgMarker', v)} />
              </Row>
              <Row label="Cor do marcador de dano">
                <Color value={draft.hud.dmgColor} onChange={(v) => setHud('dmgColor', v)} />
              </Row>
              <Row label="Marcador de kill">
                <Toggle value={draft.hud.killMarker} onChange={(v) => setHud('killMarker', v)} />
              </Row>
              <Row label="Cor do marcador de kill">
                <Color value={draft.hud.killColor} onChange={(v) => setHud('killColor', v)} />
              </Row>

              <div className="set-group">OCULTAR ELEMENTOS</div>
              <Row label="Ocultar vida">
                <Toggle value={draft.hud.hideHealth} onChange={(v) => setHud('hideHealth', v)} />
              </Row>
              <Row label="Ocultar arma selecionada">
                <Toggle value={draft.hud.hideWeapon} onChange={(v) => setHud('hideWeapon', v)} />
              </Row>
              <Row label="Ocultar hotbar">
                <Toggle value={draft.hud.hideHotbar} onChange={(v) => setHud('hideHotbar', v)} />
              </Row>
              <Row label="Ocultar level / XP">
                <Toggle value={draft.hud.hideLevel} onChange={(v) => setHud('hideLevel', v)} />
              </Row>
              <Row label="Ocultar kills / mortes / streak / online">
                <Toggle value={draft.hud.hideStats} onChange={(v) => setHud('hideStats', v)} />
              </Row>
              <Row label="Ocultar teclas de atalho (F1...)">
                <Toggle value={draft.hud.hideHints} onChange={(v) => setHud('hideHints', v)} />
              </Row>
              <Row label="Ocultar minimapa">
                <Toggle value={draft.hud.hideMinimap} onChange={(v) => setHud('hideMinimap', v)} />
              </Row>
              <Row label="Ocultar killfeed">
                <Toggle value={draft.hud.hideKillfeed} onChange={(v) => setHud('hideKillfeed', v)} />
              </Row>
              <Row label="Ocultar bússola">
                <Toggle value={draft.hud.hideCompass} onChange={(v) => setHud('hideCompass', v)} />
              </Row>
            </>
          )}

          {tab === 'audio' && (
            <>
              {(['saque', 'hit', 'kill', 'ping'] as SfxKey[]).map((cat) => (
                <div key={cat}>
                  <div className="set-group">
                    {cat === 'saque'
                      ? 'SOM DO SAQUE'
                      : cat === 'hit'
                        ? 'SOM DO HIT'
                        : cat === 'kill'
                          ? 'SOM DA KILL'
                          : 'SOM DO PING (LEVAR DANO)'}
                  </div>
                  <Row label="Efeito">
                    <select
                      className="set-select"
                      value={draft.audio[cat].effect}
                      onChange={(e) => setSfx(cat, { effect: e.target.value })}
                    >
                      {SFX_OPTIONS.map((o) => (
                        <option key={o} value={o}>
                          {o}
                        </option>
                      ))}
                    </select>
                  </Row>
                  <Row label="Volume">
                    <Slider value={draft.audio[cat].volume} onChange={(v) => setSfx(cat, { volume: v })} />
                  </Row>
                </div>
              ))}

              <div className="set-group">AMBIENTE</div>
              <Row label="Sons ambientes">
                <Dropdown
                  value={draft.audio.ambient ? 'on' : 'off'}
                  options={[
                    { value: 'off', label: 'Remover' },
                    { value: 'on', label: 'Normal' },
                  ]}
                  onChange={(v) => setAudio('ambient', v === 'on')}
                />
              </Row>
              <Row label="Sons de passos">
                <Dropdown
                  value={draft.audio.footsteps}
                  options={FOOTSTEP_OPTIONS}
                  onChange={(v) => setAudio('footsteps', v)}
                />
              </Row>
            </>
          )}

          {tab === 'game' && (
            <>
              <div className="set-group">HORÁRIO (SÓ VOCÊ VÊ)</div>
              <Row label="Sobrescrever horário">
                <Toggle value={draft.game.timeOverride} onChange={(v) => setGame('timeOverride', v)} />
              </Row>
              <Row label="Hora">
                <Slider
                  value={draft.game.hour}
                  min={0}
                  max={23}
                  suffix="h"
                  onChange={(v) => setGame('hour', v)}
                />
              </Row>
              <Row label="Minuto">
                <Slider
                  value={draft.game.minute}
                  min={0}
                  max={59}
                  suffix="m"
                  onChange={(v) => setGame('minute', v)}
                />
              </Row>

              <div className="set-group">CLIMA (SÓ VOCÊ VÊ)</div>
              <Row label="Sobrescrever clima">
                <Toggle value={draft.game.weatherOverride} onChange={(v) => setGame('weatherOverride', v)} />
              </Row>
              <Row label="Clima">
                <Dropdown value={draft.game.weather} options={WEATHER_OPTIONS} onChange={(v) => setGame('weather', v)} />
              </Row>
            </>
          )}
        </div>

        <div id="dom-settings-foot">
          <span>As configurações são salvas automaticamente neste PC.</span>
        </div>
      </div>
    </div>
  )
}
