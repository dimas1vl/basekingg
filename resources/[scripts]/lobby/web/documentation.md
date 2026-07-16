### `show`

```lua
SetNuiFocus(true, true)
SendNUIMessage({
    action = "show",
    data = {
        player = {
            name   = "rAccoZr",
            avatar = "https://cdn.example.com/avatars/123.png",  -- URL pública
            banner = "https://cdn.example.com/banners/456.png",  -- URL pública
            team   = "LOUD",
            coins  = 1500,
            points = 2800
        },
        friends = {
            {
                id     = "steam:abc123",
                name   = "Player2",
                team   = "NIP",
                avatar = "https://cdn.example.com/avatars/789.png",
                banner = "https://cdn.example.com/banners/789.png",
                online = true
            }
        },
        squad = {
            { id = "steam:abc123", name = "rAccoZr", avatar = "https://...", isLeader = true  },
            { id = "steam:def456", name = "Player2",  avatar = "https://...", isLeader = false }
        },
        news = {
            {
                id          = "news-001",
                image       = "https://cdn.example.com/news/temporada.png",
                title       = "NOVA TEMPORADA",
                date        = "14/04/2026",
                description = "Descrição da notícia aqui."
            }
        },
        online = 142,
        selectedMode = {
            category = "battle-royale",  -- modo selecionado anteriormente
            submode  = "casual"
        }
    }
})
```

### `close`

```lua
SendNUIMessage({ action = "close", data = {} })
```

---

### `updateCoins`

Atualiza somente o saldo de coins em tempo real (ex: após compra na loja).

```lua
SendNUIMessage({ action = "updateCoins", data = { coins = 2000 } })
```

---

### `updatePoints`

Atualiza somente o saldo de Kingg Points.

```lua
SendNUIMessage({ action = "updatePoints", data = { points = 3500 } })
```

---

### `updateFriends`

Substitui a lista completa de amigos (ex: amigo ficou online/offline).

```lua
SendNUIMessage({
    action = "updateFriends",
    data = {
        { id = "steam:abc", name = "Amigo1", team = "FaZe", avatar = "https://...", banner = "https://...", online = true  },
        { id = "steam:def", name = "Amigo2", team = "MIBR", avatar = "https://...", banner = "https://...", online = false }
    }
})
```

---

### `updateSquad`

Substitui a lista completa do squad (ex: membro entrou ou saiu).

```lua
SendNUIMessage({
    action = "updateSquad",
    data = {
        { id = "steam:abc", name = "rAccoZr", avatar = "https://...", isLeader = true  },
        { id = "steam:def", name = "Player2",  avatar = "https://...", isLeader = false }
    }
})
```

---

### `updateOnline`

Atualiza o contador de jogadores online exibido no footer.

```lua
SendNUIMessage({ action = "updateOnline", data = { online = 213 } })
```

---

### `updateNews`

Substitui a lista de notícias do slider na home.

```lua
SendNUIMessage({
    action = "updateNews",
    data = {
        { id = "n1", image = "https://...", title = "EVENTO", date = "01/05/2026", description = "..." },
        { id = "n2", image = "https://...", title = "UPDATE",  date = "05/05/2026", description = "..." }
    }
})
```

---

### `updateSelectedMode`

Confirma ou sobrescreve o modo selecionado (ex: modo expirou, confirmação server-side).

```lua
SendNUIMessage({
    action = "updateSelectedMode",
    data = { category = "battle-royale", submode = "casual" }
})
```

---

## 2. Callbacks NUI (React → Lua)

### `close`

Disparado quando o jogador pressiona **ESC**. Deve remover o foco da NUI.

```lua
RegisterNUICallback("close", function(data, cb)
    SetNuiFocus(false, false)
    cb({ ok = true })
end)
```

---

### `selectMode`

Disparado quando o jogador muda de **categoria** ou **subcategoria** na tela de modos.

```lua
RegisterNUICallback("selectMode", function(data, cb)
    -- data.category: string (ver tabela abaixo)
    -- data.submode:  string (ver tabela abaixo)
    SalvarModoSelecionado(GetPlayerServerId(PlayerId()), data.category, data.submode)
    cb({ ok = true })
end)
```

**Payload**: `{ category: string, submode: string }`

---

### `joinQueue`

Disparado quando o jogador clica em **JOGAR**.

```lua
RegisterNUICallback("joinQueue", function(data, cb)
    -- data.category: string
    -- data.submode:  string
    -- data.fillSlot: boolean (checkbox "PREENCHER" marcado)
    local sucesso = TentarEntrarFila(data.category, data.submode, data.fillSlot)
    if sucesso then
        SetNuiFocus(false, false)
    end
    cb({ ok = sucesso })
end)
```

**Payload**: `{ category: string, submode: string, fillSlot: boolean }`

---

### `inviteToSquad`

Disparado quando o jogador clica em **+** em um slot vazio do squad no footer.

```lua
RegisterNUICallback("inviteToSquad", function(data, cb)
    AbrirMenuConviteSquad()
    cb({ ok = true })
end)
```

**Payload**: `{}`

---

### `openActivity`

Disparado quando o jogador clica no botão de **jogadores online** no footer.

```lua
RegisterNUICallback("openActivity", function(data, cb)
    AbrirPainelAtividade()
    cb({ ok = true })
end)
```

**Payload**: `{}`

---

### `openSettings`

Disparado quando o jogador clica no botão de **configurações** no footer.

```lua
RegisterNUICallback("openSettings", function(data, cb)
    AbrirConfiguracoes()
    cb({ ok = true })
end)
```

**Payload**: `{}`

---

## 3. Perfil (`/perfil`)

Aberto ao clicar no card **SEU PERFIL** na home. Tem 3 abas: **INFORMAÇÕES**, **INVENTÁRIO**, **CONFIGURAÇÕES**.

> As **estatísticas** (Proporção K/D, Eliminações, Vitórias) já são calculadas a partir do `player` enviado no `show` (`kills`, `deaths`, `wins`). O restante do conteúdo (conquistas, clã, comentários, inventário, configurações) está **mockado** e precisa vir do backend.

### Callbacks já disparados pela UI

#### `setProfileSetting`

Disparado ao ligar/desligar um toggle na aba **CONFIGURAÇÕES**.

```lua
RegisterNUICallback("setProfileSetting", function(data, cb)
    -- data.key:   string  (ver lista abaixo)
    -- data.value: boolean
    SalvarConfigPerfil(GetPlayerServerId(PlayerId()), data.key, data.value)
    cb({ ok = true })
end)
```

**Payload**: `{ key: string, value: boolean }`
**Keys**: `public`, `stats`, `wins`, `kills`, `kd`, `comments`, `achievements`, `clan`

#### `sendProfileComment`

Disparado ao enviar um comentário no perfil.

```lua
RegisterNUICallback("sendProfileComment", function(data, cb)
    -- data.text: string
    cb({ ok = true })
end)
```

**Payload**: `{ text: string }` → resposta esperada: `{ ok: boolean, error?: string }`

### Dados necessários (hoje mock)

Recomendado: um callback de leitura (ex: `getProfile`) que retorne o objeto abaixo, **ou** empurrar via `SendNUIMessage({ action = "setProfileData", data = {...} })`.

```lua
-- Estrutura esperada
{
    unlockedAchievements = 2,   -- número de conquistas desbloqueadas (total fixo = 32)
    clan = {
        tag      = "KZN",
        name     = "KillZone",
        members  = 8,
        trophies = { 8, 8, 8 },   -- lista de troféus
        leader   = 8
    },
    comments = {
        { id = "c1", name = "rAccoZr", avatar = "https://...", date = "21/06/2026", text = "Melhor jogador!" }
    },
    inventory = {   -- itens consumíveis (aba INVENTÁRIO)
        { id = "i1", name = "NOME DO ITEM - 30 DIAS", image = "https://...", status = "ADQUIRIDO" }
    },
    settings = {    -- valores iniciais dos toggles
        public = true, stats = false, wins = true, kills = true,
        kd = true, comments = true, achievements = true, clan = true
    }
}
```

---

## 4. Loja (`/store`)

Sidebar de categorias + banner + grade de itens. Clicar num item abre o modal **COMPRA** (confirmar/cancelar).

### Callbacks já disparados pela UI

#### `buyStoreItem`

Disparado ao clicar **CONFIRMAR** no modal de compra.

```lua
RegisterNUICallback("buyStoreItem", function(data, cb)
    -- data.itemId: string
    local ok, err = ComprarItemLoja(GetPlayerServerId(PlayerId()), data.itemId)
    cb({ ok = ok, error = err })   -- em caso de sucesso, envie também updateCoins/updatePoints
end)
```

**Payload**: `{ itemId: string }` → resposta: `{ ok: boolean, error?: string }`

#### `openStorePackage`

Disparado ao clicar **APROVEITE AGORA** no banner de destaque.

```lua
RegisterNUICallback("openStorePackage", function(data, cb)
    cb({ ok = true })
end)
```

**Payload**: `{}`

### Dados necessários (hoje mock)

As **categorias** são estáticas no front (`TODOS OS ITENS`, `DOMINAÇÃO`, `BATTLE ROYALE / END GAME` → `PACOTES`/`CAIXAS`/`CLAN`, `MINI GAMES`). Os **itens** precisam vir do backend (ex: callback `getStoreItems` ou push):

```lua
-- Lista de itens da loja
{
    { id = "s1", name = "NOME DO ITEM - 30 DIAS", image = "https://...", price = 1000, category = "pacotes", isNew = true }
    -- category deve casar com o id da categoria/subcategoria selecionada
}
```

---

## 5. Ranking (`/ranking`)

Somente leitura. Abas **JOGADOR** e **CLAN** (as abas `ALGO` são placeholders). Top 3 do ranking de jogador recebem destaque ouro/prata/bronze.

### Dados necessários (hoje mock)

Recomendado um callback `getRanking` (ou push `SendNUIMessage`) com as duas listas. Cada linha tem `rank`, `name` e um array `values` **na ordem das colunas**:

```lua
{
    player = {
        -- colunas: NOME | ELO | VITÓRIAS | KILLS | K/D%
        { rank = 1, name = "RACCO COSTA", values = { "DIAMANTE III", "151", "543", "76%" } }
    },
    clan = {
        -- colunas: CLAN | VITORIAS | PARTIDAS | PONTOS
        { rank = 1, name = "KillZone", values = { "DIAMANTE III", "151", "543" } }
    }
}
```

---

## 6. Caixas (`/boxes`) + Roleta

Lista das caixas do jogador. Clicar numa caixa abre a **roleta** (abertura estilo CS/keydrop).

> ⚠️ **A roleta ainda não está finalizada no Figma.** A animação já está implementada no front, mas o **resultado é decidido no cliente (mock)**. Quando o design fechar, o prêmio deve ser **autoritativo no servidor** (ver observação no fim).

### Callback já disparado pela UI

#### `openBox`

Disparado ao clicar numa caixa para abri-la.

```lua
RegisterNUICallback("openBox", function(data, cb)
    -- data.boxId: string
    cb({ ok = true })
end)
```

**Payload**: `{ boxId: string }`

### Dados necessários (hoje mock)

Lista de caixas do jogador (grade da página `/boxes`):

```lua
{
    { id = "box1", name = "NOME DO ITEM - 30 DIAS", image = "https://...", status = "ADQUIRIDO" }
}
```

### Observação para quando a roleta for finalizada

Para a abertura ser justa/anti-cheat, o ideal é o servidor decidir o prêmio. Sugestão de contrato:

- `openBox` retorna o prêmio já sorteado pelo servidor: `cb({ ok = true, prize = { id, name, image, rarity } })`.
- O front usa esse `prize` como item vencedor da roleta (a animação apenas revela o resultado já definido).
- `rarity` ∈ `blue` | `green` | `orange` | `purple` | `gold` (cor do divisor do card).

---
