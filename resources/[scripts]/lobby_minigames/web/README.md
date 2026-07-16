# Minigames NUI — Documentação Backend

### `Room`

```lua
{
  id         = string,   -- identificador único da sala
  owner      = string,   -- nome do dono (ex: "RACCO")
  map        = string,   -- nome do mapa (ex: "SANDY SHORES")
  players    = number,   -- jogadores atualmente na sala
  maxPlayers = number,   -- capacidade máxima
  isPrivate  = boolean   -- true = requer senha
}
```

### `GameModeCount`

```lua
{
  id        = string,         -- "clutch" | "gang" | "predios" | "dominacao"
  openRooms = number | nil    -- nil = modo sem salas abertas (ex: CLUTCH vai direto pro criar)
}
```

### `CreateRoomData` (recebido do frontend)

```lua
{
  map        = string,
  maxPlayers = number,
  isPrivate  = boolean,
  password   = string | nil   -- só presente se isPrivate = true
}
```

---

## Lua → NUI (SendNUIMessage)

### Abrir o painel principal

```lua
SendNUIMessage({ action = "show", data = true })
SetNuiFocus(true, true)
```

### Fechar o painel

```lua
SendNUIMessage({ action = "close" })
SetNuiFocus(false, false)
```

### "H - VOLTAR AO MENU PRINCIPAL"

```lua
SendNUIMessage({ action = "show-h" })
```

```lua
SendNUIMessage({ action = "hide-h" })
```

###

```lua
SendNUIMessage({
  action = "minigames:setGameModes",
  data = {
    { id = "clutch",    openRooms = nil }, -- nil = "CRIE UMA SALA"
    { id = "gang",      openRooms = 12  },
    { id = "predios",   openRooms = 8   },
    { id = "dominacao", openRooms = 5   }
  }
})
```

```lua
SendNUIMessage({
  action = "minigames:setRooms",
  data = {
    {
      id         = "1",
      owner      = "RACCO",
      map        = "SANDY SHORES",
      players    = 8,
      maxPlayers = 12,
      isPrivate  = false
    },
    -- ...
  }
})
```

---

### `close`

```lua
RegisterNUICallback("close", function(data, cb)
  SetNuiFocus(false, false)
  cb({})
end)
```

### `minigames:getRooms`

```lua
RegisterNUICallback("minigames:getRooms", function(data, cb)
  -- data.gameMode = "gang" | "predios" | "dominacao"
  local rooms = GetRoomsForMode(data.gameMode)
  cb(rooms) -- array de Room
end)
```

### `minigames:joinRoom`

```lua
RegisterNUICallback("minigames:joinRoom", function(data, cb)
  -- data.roomId   = string
  -- data.password = string | nil  (salas privadas)
  local success = TryJoinRoom(data.roomId, data.password)
  cb({ success = success })
end)
```

### `minigames:createRoom`

```lua
RegisterNUICallback("minigames:createRoom", function(data, cb)
  -- data.map        = string
  -- data.maxPlayers = number
  -- data.isPrivate  = boolean
  -- data.password   = string | nil
  local roomId = CreateRoom(data)
  cb({ roomId = roomId })
end)
```
