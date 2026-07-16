## `hud:update` — Status do Jogador

```lua
SendNUIMessage({
    action = "hud:update",
    data = {
        health     = 100,
        armor      = 100,
        ammo       = 30,
        maxAmmo    = 140,
        activeSlot = 1,
        slots = {
            { ammo = 1   },
            { ammo = nil },
            { ammo = 3   },
            { ammo = 2   },
            { ammo = nil },
        },
        speed  = 165,
        kills  = 4,
    }
})
```

---

## `hud:squad` — Membros do Squad

```lua
SendNUIMessage({
    action = "hud:squad",
    data = {
        {
            slot       = 1,
            name       = "Dimas1VL",
            health     = 100,
            armor      = 100,
            alive      = true,
            speaking   = false,
            badgeColor = "#cd6f3c",
        },
        {
            slot       = 3,
            name       = "BlvRevolution",
            health     = 47,
            armor      = 0,
            alive      = true,
            speaking   = true,
            badgeColor = "#4972ca",
        },
    }
})
```

---

## `hud:killfeed` — Feed de Kills

```lua
SendNUIMessage({
    action = "hud:killfeed",
    data = {
        killer        = "[KZN] rACCOZr",
        victim        = "Flaash",
        killerIsTeam  = true,
        victimIsTeam  = false,
    }
})
```

## `hud:phase` — Fase / Zona

```lua
SendNUIMessage({
    action = "hud:phase",
    data = {
        timer       = "02:45",
        phase       = 3,
        totalPhases = 12,
        progress    = 0.46,
    }
})
```

## `hud:safezone` — Alerta de Safe Zone

```lua
SendNUIMessage({
    action = "hud:safezone",
    data = {
        visible = true,
        title   = "SAFE ZONE",
        message = "A PRÓXIMA ZONA FECHARÁ EM 30 SEGUNDOS",
    }
})

SendNUIMessage({
    action = "hud:safezone",
    data = {
        visible = false,
        title   = "",
        message = "",
    }
})
```

---

## `hud:interaction` — Prompt de Interação

```lua
SendNUIMessage({
    action = "hud:interaction",
    data = {
        visible     = true,
        key         = "E",
        action      = "PEGAR MUNIÇÃO",
        detail      = "QUANTIDADE",
        detailValue = "x30",
    }
})

SendNUIMessage({
    action = "hud:interaction",
    data = { visible = false, key = "", action = "", detail = "", detailValue = "" }
})
```

---

## `hud:action` — Barra de Ação (Progress Bar)

```lua

    SendNUIMessage({
        action = "hud:action",
        data = { visible = true, type = "medkit", text = "USANDO KIT MEDICO", cancelKey = "F", progress = 0.0 }
    })

    SendNUIMessage({
        action = "hud:action",
        data = { visible = false, type = nil, cancelKey = "", progress = 0.0 }
    })
```

### Recarga

```lua
SendNUIMessage({
    action = "hud:action",
    data = { visible = true, type = "reload", cancelKey = "", progress = 0.0 }
})

SendNUIMessage({
    action = "hud:action",
    data = { visible = false, type = nil, cancelKey = "", progress = 0.0 }
})
```

---

## `hud:meters` — Medidores + Bússola

```lua
SendNUIMessage({
    action = "hud:meters",
    data = {
        distance      = 166,
        distanceLabel = "MAR",
        vehicleSpeed  = 134,
        altitude      = 155,
        heading       = 270,
    }
})
```

## Mostrar / Ocultar o HUD completo

```lua
SendNUIMessage({ action = "show", data = true })

SendNUIMessage({ action = "close", data = true })
```
