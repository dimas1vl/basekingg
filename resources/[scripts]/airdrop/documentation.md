```lua
-- Abrir
SetNuiFocus(true, true)
SendNUIMessage({ action = 'show', data = true })

-- Fechar pelo servidor/client (opcional)
SendNUIMessage({ action = 'close' })
```

---

Callbacks

### `getAbilities`

```lua
RegisterNUICallback('getAbilities', function(_, cb)
  cb({
    { id = 'revive', title = 'REVIVE', description = 'REVIVER TODOS\nOS ALIADOS' },
    { id = 'vant',   title = 'VANT',   description = 'REVELAR\nINIMIGOS' },
    { id = 'radar',  title = 'RADAR',  description = 'REVELAR PROXIMA SAFE' },
  })
end)
```

### `selectAbility` — o jogador escolheu uma habilidade

```lua
RegisterNUICallback('selectAbility', function(data, cb)
  local id = data.id   -- 'revive' | 'vant' | 'radar'

  cb({ success = true })
end)
```

### `close` — a UI quer fechar

```lua
RegisterNUICallback('close', function(_, cb)
  SetNuiFocus(false, false)
  cb({})
end)
```

---

OBS:

O backend **nunca** envia ícone. Cada `id` é mapeado para um SVG bundlado em
[`src/modules/airdrop/data.ts`](src/modules/airdrop/data.ts):

```ts
export const ABILITY_VISUALS = {
  revive: { icon: iconRevive, iconWidth: '7.5rem', iconHeight: '4.6rem' },
  vant: { icon: iconVant, iconWidth: '7.5rem', iconHeight: '5rem' },
  radar: { icon: iconRadar, iconWidth: '7.5rem', iconHeight: '5rem' },
}
```
