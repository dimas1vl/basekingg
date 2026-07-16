# FiveM NUI Boilerplate

Boilerplate profissional para interfaces NUI (Native UI) do FiveM usando React, TypeScript e TailwindCSS.

---

## Estrutura do Projeto

```
src/
├── config/           # Configuracoes estaticas (navbar, icones)
├── hooks/            # Hooks customizados (listener, queries, mutations)
├── lib/              # Funcoes utilitarias de lib (cn)
├── modules/          # Paginas/features organizadas por modulo
│   └── home/
├── providers/        # Context providers (Visibility)
├── styles/           # CSS global
├── types/            # Tipos TypeScript compartilhados
└── utils/            # Funcoes utilitarias puras
```

---

## Arquitetura: Como Tudo se Conecta

```
Lua (FiveM Server/Client)
    │
    ├── SendNUIMessage({ action, data })  ──▶  useListener(event, handler)
    │                                           (recebe eventos do Lua)
    │
    └── RegisterNUICallback(event, cb)    ◀──  fetchData(event, payload)
                                                (envia dados pro Lua)
```

O frontend React roda dentro do CEF (Chromium Embedded Framework) do FiveM. A comunicacao e bidirecional:

- **Lua → React**: via `SendNUIMessage` → capturado pelo `useListener`
- **React → Lua**: via `fetchData` (HTTP POST) → capturado pelo `RegisterNUICallback`

---

## Hooks

### `useListener<T>(event, handler)` — Receber eventos do Lua

Escuta mensagens enviadas pelo Lua via `SendNUIMessage`.

```tsx
// Lua envia: SendNUIMessage({ action = "updateHealth", data = { current = 80, max = 100 } })

// React recebe:
useListener<{ current: number; max: number }>('updateHealth', (data) => {
  setHealth(data.current)
})
```

**Quando usar:**
- Receber dados em tempo real do servidor/client Lua
- Reagir a eventos do jogo (abrir menu, atualizar HUD, notificacoes)
- Qualquer dado que o Lua "empurra" para a UI

---

### `useNuiQuery<T>(options)` — Buscar dados do Lua (GET-like)

Wrapper do React Query para buscar dados do Lua. Usa cache, loading states, e refetch automatico.

```tsx
interface Player {
  name: string
  money: number
  job: string
}

function PlayerCard() {
  const { data, isLoading, error } = useNuiQuery<Player>({
    event: 'getPlayerData',
    mockData: { name: 'Dev Player', money: 50000, job: 'police' }, // usado no browser
  })

  if (isLoading) return <Skeleton />
  if (error) return <p>Erro ao carregar</p>

  return (
    <div>
      <h2>{data.name}</h2>
      <p>${formatAmount(data.money)}</p>
      <p>{data.job}</p>
    </div>
  )
}
```

**Com parametros:**

```tsx
const { data: items } = useNuiQuery<Item[]>({
  event: 'getInventory',
  data: { playerId: 123 },           // enviado como body do POST
  mockData: mockItems,                // fallback no browser
  enabled: opened,                    // so busca quando a UI ta aberta
  staleTime: 5000,                    // cache de 5 segundos
})
```

**Quando usar:**
- Buscar dados ao abrir a UI (inventario, status, configs)
- Qualquer dado que voce precisa "puxar" do Lua
- Dados que se beneficiam de cache (evitar requests repetidos)

**Quando NAO usar:**
- Para receber eventos push do Lua → use `useListener`
- Para enviar acoes/comandos → use `useNuiMutation`

---

### `useNuiMutation<TResponse, TPayload>(options)` — Enviar acoes pro Lua (POST-like)

Wrapper do React Query para enviar comandos/acoes para o Lua.

```tsx
function TransferForm() {
  const transfer = useNuiMutation<{ success: boolean }, { targetId: number; amount: number }>({
    event: 'transferMoney',
    onSuccess: (response) => {
      if (response.success) toast.success('Transferencia realizada!')
    },
    onError: () => {
      toast.error('Falha na transferencia')
    },
  })

  const handleSubmit = () => {
    transfer.mutate({ targetId: 42, amount: 1000 })
  }

  return (
    <button onClick={handleSubmit} disabled={transfer.isPending}>
      {transfer.isPending ? 'Enviando...' : 'Transferir'}
    </button>
  )
}
```

**Quando usar:**
- Enviar acoes do jogador (comprar item, transferir dinheiro, aceitar missao)
- Qualquer operacao que modifica estado no servidor
- Quando voce precisa de `isPending`, `onSuccess`, `onError`

**Quando NAO usar:**
- Para buscar dados → use `useNuiQuery`
- Para fechar a UI → use `useVisibility().close()`

---

### `useVisibility()` — Controlar visibilidade da UI

```tsx
function MyComponent() {
  const { opened, close } = useVisibility()

  return (
    <div>
      {opened && <Panel />}
      <button onClick={close}>Fechar</button>
    </div>
  )
}
```

**O que acontece internamente:**
1. Lua envia `SendNUIMessage({ action = "show" })` → UI abre, navega pra `/`, limpa cache
2. Usuario aperta `ESC` ou clica em fechar → `close()` é chamado → envia `fetchData('close')` pro Lua
3. Lua recebe o callback `close` e pode desativar o NUI focus

---

## Utils

### `fetchData<T>(event, data?, mockData?)` — RPC direto pro Lua

Funcao base de comunicacao. Os hooks `useNuiQuery` e `useNuiMutation` usam ela internamente. Use diretamente apenas quando nao precisa de loading states ou cache.

```tsx
// Uso direto (sem React Query)
const result = await fetchData<{ ok: boolean }>('doSomething', { id: 1 })

// Com mock para desenvolvimento no browser
const items = await fetchData<Item[]>('getItems', {}, mockItems)
```

**Quando usar direto:**
- Dentro de event handlers simples (fire-and-forget)
- No `VisibilityProvider` ou outros providers
- Quando React Query seria overkill

---

### `debugData<T>(events, timer?)` — Simular eventos no browser

Dispara eventos fake no modo desenvolvimento para testar sem abrir o FiveM.

```tsx
// No main.tsx ou no topo de um modulo
debugData([
  { event: 'show', data: true },
  { event: 'updateInventory', data: mockInventory },
])

// Com delay customizado (default: 750ms)
debugData([{ event: 'show', data: true }], 1000)
```

**Quando usar:**
- Sempre no `main.tsx` para abrir a UI no browser
- Para testar fluxos especificos sem FiveM rodando
- So roda em `development` + browser (ignorado no jogo)

---

### `cn(...classes)` — Merge de classes Tailwind

Combina `clsx` + `tailwind-merge` para resolver conflitos de classes.

```tsx
<div className={cn(
  'p-4 bg-red-500',
  isActive && 'bg-blue-500',   // sobrescreve bg-red-500 quando ativo
  className                     // aceita classes externas
)} />
```

**Quando usar:** Sempre que combinar classes condicionais do Tailwind.

---

### `isEnvBrowser()` — Detectar ambiente

```tsx
if (isEnvBrowser()) {
  // Rodando no browser normal (desenvolvimento)
} else {
  // Rodando dentro do FiveM (producao)
}
```

---

### `formatAmount(value, options?)` — Formatar numeros

```tsx
formatAmount(1500)                          // "1.5k"
formatAmount(2300000)                       // "2.3m"
formatAmount(1500, { currency: 'R$' })      // "R$1.5k"
formatAmount(1500, { compact: false })      // "1500.0"
formatAmount(0)                             // "0"
```

---

### `copyToClipboard(text)` — Copiar texto

```tsx
const copied = await copyToClipboard('Texto para copiar')
if (copied) toast.success('Copiado!')
```

---

### `openUrl(url)` — Abrir URL

Abre URL no browser do jogador (FiveM) ou em nova aba (browser).

```tsx
openUrl('https://discord.gg/meuservidor')
```

---

### `cdn(file)` — URL de CDN

Monta URL completa a partir da env var `VITE_CDN_URL`.

```env
# .env
VITE_CDN_URL=https://meu-cdn.com/assets/
```

```tsx
<img src={cdn('pistol.png')} />
// → https://meu-cdn.com/assets/pistol.png
```

---

### `clamp(value, min, max)` — Limitar valor

```tsx
clamp(150, 0, 100) // 100
clamp(-5, 0, 100)  // 0
clamp(50, 0, 100)  // 50
```

---

### `hslToHex(h, s, l)` — Converter cor

```tsx
hslToHex(219, 100, 65) // "#4d94ff"
```

---

## Config

### `src/config/navbar.ts` — Itens de navegacao

```tsx
import { Home, Settings, Package } from 'lucide-react'
import type { NavbarItem } from './navbar'

export const NAVBAR_ITEMS: NavbarItem[] = [
  { label: 'Inicio', path: '/', icon: Home },
  { label: 'Inventario', path: '/inventory', icon: Package },
  { label: 'Configs', path: '/settings', icon: Settings },
]
```

### `src/config/icons.ts` — Registro de icones

```tsx
import { Sword, Shield, Heart } from 'lucide-react'

export const ICONS: Record<string, ElementType> = {
  sword: Sword,
  shield: Shield,
  heart: Heart,
}
```

---

## Types

### `src/types/utils.ts`

```tsx
// Formato de evento NUI recebido do Lua
type NuiEvent<T> = { action: string; data: T }

// Formato padrao de resposta do Lua
type FetchResponse<T> = { ok: boolean; data: T; message?: string }
```

Use `FetchResponse` como tipo generico nas suas queries para manter consistencia:

```tsx
const { data } = useNuiQuery<FetchResponse<Player[]>>({
  event: 'getPlayers',
})

if (data?.ok) {
  // data.data contem Player[]
}
```

---

## Providers

### `VisibilityProvider`

Ja vem configurado no `main.tsx`. Controla o ciclo de vida da UI:

| Evento     | Origem | O que faz                                      |
|------------|--------|-------------------------------------------------|
| `show`     | Lua    | Abre a UI, navega pra `/`, limpa cache de query |
| `close`    | Lua    | Fecha a UI                                      |
| `ESC` key  | User   | Fecha a UI + notifica o Lua via `fetchData`     |

---

## Tema / Estilizacao

### Cor primaria

Definida como CSS variable em `src/styles/global.css`:

```css
:root {
  --primary-color: 219 100% 65%;
}
```

Uso no Tailwind: `bg-primary`, `text-primary`, `border-primary`

Para mudar a cor do projeto inteiro, altere apenas essa variavel.

### Responsividade

O CSS ja inclui media queries para todas as resolucoes comuns do FiveM (800px a 3840px). A unidade `rem` escala automaticamente.

---

## Scripts

| Comando          | O que faz                                             |
|------------------|-------------------------------------------------------|
| `pnpm dev`       | Servidor de desenvolvimento (browser)                 |
| `pnpm start:game`| Build com watch (usa no FiveM, rebuilda a cada save)  |
| `pnpm build`     | Build de producao (type-check + bundle)               |
| `pnpm format`    | Formata todo o codigo com Prettier                    |

---

## Exemplo Completo: Modulo de Inventario

```
src/modules/inventory/
├── page.tsx          # Pagina principal
├── components/
│   ├── item-slot.tsx
│   └── item-tooltip.tsx
└── types.ts          # Tipos do modulo
```

```tsx
// src/modules/inventory/types.ts
export interface Item {
  id: number
  name: string
  quantity: number
  weight: number
}

// src/modules/inventory/page.tsx
import { useNuiQuery } from '@/hooks/useNuiQuery'
import { useNuiMutation } from '@/hooks/useNuiMutation'
import { useListener } from '@/hooks/listener'
import { formatAmount } from '@/utils/formatAmount'
import type { Item } from './types'

const mockItems: Item[] = [
  { id: 1, name: 'Pistola', quantity: 1, weight: 2.5 },
  { id: 2, name: 'Bandagem', quantity: 5, weight: 0.2 },
]

export default function Inventory() {
  const { data: items, isLoading, refetch } = useNuiQuery<Item[]>({
    event: 'getInventory',
    mockData: mockItems,
  })

  const useItem = useNuiMutation<{ success: boolean }, { itemId: number }>({
    event: 'useItem',
    onSuccess: () => refetch(),
  })

  // Escuta atualizacoes em tempo real do Lua
  useListener('inventoryUpdated', () => refetch())

  if (isLoading) return <p>Carregando...</p>

  return (
    <div className="grid grid-cols-5 gap-2">
      {items?.map((item) => (
        <button
          key={item.id}
          onClick={() => useItem.mutate({ itemId: item.id })}
          className="p-2 bg-white/5 rounded hover:bg-primary/20 transition"
        >
          <p className="text-white text-sm">{item.name}</p>
          <p className="text-white/50 text-xs">x{item.quantity}</p>
        </button>
      ))}
    </div>
  )
}
```

---

## Resumo Rapido: Qual Hook Usar?

| Situacao                              | Hook/Funcao        |
|---------------------------------------|--------------------|
| Buscar dados do Lua (com cache)       | `useNuiQuery`      |
| Enviar acao pro Lua (com feedback)    | `useNuiMutation`   |
| Receber evento push do Lua            | `useListener`      |
| Abrir/fechar a UI                     | `useVisibility`    |
| Comunicacao simples sem React Query   | `fetchData`        |
| Simular eventos no browser            | `debugData`        |
