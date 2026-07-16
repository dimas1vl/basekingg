// Tracking config panel — opens with F7, sends updates to Lua via fetchNui.

(() => {
  'use strict'

  const root = document.getElementById('tracking-config')
  if (!root) return

  const tabs = Array.from(document.querySelectorAll('.tc-tab'))
  const sections = Array.from(document.querySelectorAll('.tc-section'))
  const closeBtn = document.getElementById('tc-close')

  function getResourceName() {
    if (typeof window.GetParentResourceName === 'function') {
      return window.GetParentResourceName()
    }
    return 'tracking'
  }

  async function fetchNui(eventName, data) {
    if (typeof window.invokeNative === 'undefined') return { ok: true }
    try {
      const resp = await fetch(`https://${getResourceName()}/${eventName}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data || {}),
      })
      return await resp.json()
    } catch (e) {
      return null
    }
  }

  function setActiveTab(name) {
    tabs.forEach((tab) => tab.classList.toggle('active', tab.dataset.tab === name))
    sections.forEach((sec) => sec.classList.toggle('active', sec.dataset.section === name))
  }

  tabs.forEach((tab) => {
    tab.addEventListener('click', () => setActiveTab(tab.dataset.tab))
  })

  function valueOf(key, raw) {
    if (raw === null || raw === undefined) return raw
    if (key.endsWith('Ms') || /spawnCooldownMs|pedLifetimeMs|rollDeleteDelayMs/.test(key)) {
      return Math.round((raw / 1000) * 10) / 10
    }
    return raw
  }

  function rawOf(input) {
    const dataUnit = input.dataset.unit
    let v
    if (input.type === 'checkbox') {
      v = input.checked
    } else if (input.type === 'range') {
      v = parseFloat(input.value)
      if (dataUnit === 'ms-seconds') v = Math.round(v * 1000)
    } else if (input.tagName === 'SELECT') {
      v = input.value
    } else {
      v = input.value
    }
    return v
  }

  function refreshBoundValue(key) {
    const out = root.querySelector(`[data-bind="${key}"]`)
    const input = root.querySelector(`[data-key="${key}"]`)
    if (!out || !input) return
    if (input.type === 'range') {
      const v = parseFloat(input.value)
      out.textContent = v % 1 === 0 ? v.toFixed(0) : v.toFixed(1)
    }
  }

  root.querySelectorAll('[data-key]').forEach((input) => {
    const eventName = input.tagName === 'SELECT' ? 'change' : 'input'
    input.addEventListener(eventName, () => {
      const key = input.dataset.key
      refreshBoundValue(key)
      const [category, setting] = key.split('.')
      fetchNui('setConfig', {
        category,
        key: setting,
        value: rawOf(input),
      })
    })
  })

  function applyConfig(payload) {
    if (!payload || typeof payload !== 'object') return
    Object.entries(payload).forEach(([category, settings]) => {
      if (!settings || typeof settings !== 'object') return
      Object.entries(settings).forEach(([k, v]) => {
        const fullKey = `${category}.${k}`
        const input = root.querySelector(`[data-key="${fullKey}"]`)
        if (!input) return
        if (input.type === 'checkbox') {
          input.checked = !!v
        } else if (input.type === 'range') {
          let val = v
          if (input.dataset.unit === 'ms-seconds') val = (v || 0) / 1000
          input.value = val
          refreshBoundValue(fullKey)
        } else if (input.tagName === 'SELECT') {
          input.value = v != null ? String(v) : ''
        }
      })
    })
  }

  function close() {
    root.classList.add('hidden')
    fetchNui('closeConfig', {})
  }

  closeBtn.addEventListener('click', close)

  window.addEventListener('keydown', (e) => {
    if (root.classList.contains('hidden')) return
    if (e.key === 'Escape' || e.key === 'F7') {
      e.preventDefault()
      close()
    }
  })

  const statusRoot = document.getElementById('tracking-status')
  const tsMode     = document.getElementById('ts-mode')

  const refs = {
    vehicles: {
      block: document.querySelector('.ts-block[data-block="vehicles"]'),
      count: document.getElementById('ts-vehicles'),
      speed: document.getElementById('ts-speed'),
      interval: document.getElementById('ts-interval'),
    },
    parachute: {
      block: document.querySelector('.ts-block[data-block="parachute"]'),
      count: document.getElementById('ts-parachute'),
      interval: document.getElementById('ts-parachute-interval'),
    },
    runner: {
      block: document.querySelector('.ts-block[data-block="runner"]'),
      count: document.getElementById('ts-runner'),
      speed: document.getElementById('ts-runner-speed'),
      interval: document.getElementById('ts-runner-interval'),
    },
    roll: {
      block: document.querySelector('.ts-block[data-block="roll"]'),
      count: document.getElementById('ts-roll'),
      interval: document.getElementById('ts-roll-interval'),
    },
    area: {
      block: document.querySelector('.ts-block[data-block="area"]'),
      count: document.getElementById('ts-area'),
      lifetime: document.getElementById('ts-area-lifetime'),
    },
  }

  function toSeconds(ms) { return (ms / 1000).toFixed(2) + 's' }

  function setBlockActive(block, isActive) {
    if (!block) return
    block.classList.toggle('active', !!isActive)
  }

  function updateStatus(payload) {
    if (!statusRoot || !payload) return

    const isCategorized = payload.vehicles && typeof payload.vehicles === 'object'

    if (tsMode) tsMode.textContent = isCategorized ? 'Tracking' : String(payload.mode || 'Tracking')

    if (isCategorized) {
      const isVisible = (sec) => (sec && (sec.eligible || (sec.active || 0) > 0))

      const v = payload.vehicles
      if (refs.vehicles.count) refs.vehicles.count.textContent = `${v.active}/${v.max}`
      if (refs.vehicles.speed) refs.vehicles.speed.textContent = (v.speedMul).toFixed(1) + 'x'
      if (refs.vehicles.interval) refs.vehicles.interval.textContent = toSeconds(v.intervalMs)
      setBlockActive(refs.vehicles.block, v.enabled !== false && isVisible(v))

      const p = payload.parachute || {}
      if (refs.parachute.count) refs.parachute.count.textContent = `${p.active || 0}/${p.max || 0}`
      if (refs.parachute.interval) refs.parachute.interval.textContent = toSeconds(p.intervalMs || 0)
      setBlockActive(refs.parachute.block, p.enabled !== false && isVisible(p))

      const r = payload.runner || {}
      if (refs.runner.count) refs.runner.count.textContent = `${r.active || 0}/${r.max || 0}`
      if (refs.runner.speed) refs.runner.speed.textContent = (r.speed || 0).toFixed(1)
      if (refs.runner.interval) refs.runner.interval.textContent = toSeconds(r.intervalMs || 0)
      setBlockActive(refs.runner.block, isVisible(r))

      const rl = payload.roll || {}
      if (refs.roll.count) refs.roll.count.textContent = `${rl.active || 0}/${rl.max || 0}`
      if (refs.roll.interval) refs.roll.interval.textContent = toSeconds(rl.intervalMs || 0)
      setBlockActive(refs.roll.block, isVisible(rl))

      const a = payload.area || {}
      if (refs.area.count) refs.area.count.textContent = `${a.active || 0}/${a.max || 0}`
      if (refs.area.lifetime) refs.area.lifetime.textContent = toSeconds(a.lifetimeMs || 0)
      setBlockActive(refs.area.block, isVisible(a))
    } else {
      if (payload.active != null && payload.max != null && refs.vehicles.count) {
        refs.vehicles.count.textContent = `${payload.active}/${payload.max}`
      }
      if (payload.speedMul != null && refs.vehicles.speed) {
        refs.vehicles.speed.textContent = (payload.speedMul).toFixed(1) + 'x'
      }
      if (payload.intervalMs != null && refs.vehicles.interval) {
        refs.vehicles.interval.textContent = toSeconds(payload.intervalMs)
      }
      setBlockActive(refs.vehicles.block, payload.hasVehicles !== false)
    }
  }

  window.addEventListener('message', (event) => {
    const { action, data } = event.data || {}
    if (action === 'showConfig') {
      applyConfig(data || {})
      root.classList.remove('hidden')
      setActiveTab('general')
    } else if (action === 'hideConfig') {
      root.classList.add('hidden')
    } else if (action === 'configValues') {
      applyConfig(data || {})
    } else if (action === 'statusShow') {
      if (statusRoot) statusRoot.classList.remove('hidden')
      updateStatus(data || {})
    } else if (action === 'statusHide') {
      if (statusRoot) statusRoot.classList.add('hidden')
    } else if (action === 'statusUpdate') {
      updateStatus(data || {})
    }
  })
})()
