# Inventory NUI — Contrato com o Backend Lua

## Abrir o inventário

```lua
SetNuiFocus(true, true)
SendNUIMessage({ action = "show" })
SendNUIMessage({
  action = "setInventory",
  data = {
    items = {
      { name = "weapon_pistol", label = "Pistola",  quantity = 1,  image = "weapon_pistol"  },
      { name = "bread",         label = "Pão",      quantity = 5,  image = "bread"          },
      false, -- slot vazio
      { name = "water",         label = "Água",     quantity = 2,  image = "water"          },
      false, -- slot vazio
    }
  }
})
```

### `swapSlots` — arrastar item de um slot para outro.

```lua
RegisterNUICallback("swapSlots", function(data, cb)
  -- data.from  (number, 0-indexed)
  -- data.to    (number, 0-indexed)
  cb("ok")
end)
```

### `useItem` — botão USAR

```lua
RegisterNUICallback("useItem", function(data, cb)
  -- data.slot  (number, 0-indexed)
  cb("ok")
end)
```

### `moveItem` — botão MOVER

```lua
RegisterNUICallback("moveItem", function(data, cb)
  -- data.slot      (number, 0-indexed)
  -- data.quantity  (number)
  cb("ok")
end)
```

### `close`

```lua
RegisterNUICallback("close", function(_, cb)
  SetNuiFocus(false, false)
  cb("ok")
end)
```

---

## Atualizar o inventário em tempo real

```lua
SendNUIMessage({
  action = "setInventory",
  data   = { items = { ... } }
})
```
