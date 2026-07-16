while not Core do
    Wait(100)
end

---@class SafeZoneData
---@field center vector3
---@field radius number

---@class SafeZoneDynamicOpts
---@field candidates number
---@field areaRadius number
---@field minImprovement number
---@field gasOverlap number
---@field radiusJitter number

local DEFAULT_OPTS = {
    candidates = 8,
    areaRadius = 250.0,
    minImprovement = 0.25,
    gasOverlap = 0.5,
    radiusJitter = 0.15,
}

--- Conta jogadores (peds owned) dentro de um raio, filtrando pelo routing bucket da partida.
--- @param bucket number
--- @param coords vector3
--- @param radius number
--- @return number count
local function getPlayersInArea(bucket, coords, radius)

    local count = 0

    for _, entity in ipairs(GetEntitiesInRadius(coords.x, coords.y, coords.z, radius, 1, true)) do
        local owner = NetworkGetEntityOwner(entity)

        if owner and owner > 0 and GetPlayerRoutingBucket(owner) == bucket then
            count += 1
        end
    end

    return count
end

--- Aplica variacao aleatoria ao raio do preset, mantendo a invariante de que
--- o novo raio e sempre estritamente menor que o raio da zona atual.
--- @param currentRadius number raio da zona atual
--- @param baseRadius number raio alvo do preset
--- @param jitter number fracao de variacao (0 a 1) em torno do baseRadius
--- @return number
local function jitterRadius(currentRadius, baseRadius, jitter)

    assert(type(baseRadius) == 'number' and baseRadius > 0, 'baseRadius invalid')
    assert(type(currentRadius) == 'number' and currentRadius > baseRadius, 'currentRadius must be larger than baseRadius')

    jitter = math.max(0, math.min(1, jitter or 0))

    if jitter <= 0 then
        return baseRadius
    end

    -- Janela simetrica em torno do baseRadius, limitada a (currentRadius - epsilon)
    -- para garantir que o proximo raio sempre seja menor que o atual.
    local maxRadius = math.min(baseRadius * (1 + jitter), currentRadius * 0.99)
    local minRadius = baseRadius * (1 - jitter)

    if maxRadius <= minRadius then
        return baseRadius
    end

    return minRadius + math.random() * (maxRadius - minRadius)
end

--- Algoritmo original: offset aleatorio dentro de [minOffset, maxOffset].
--- Mantido como fallback quando a busca por menor densidade nao encontra melhora significativa.
--- @param currentZone SafeZoneData
--- @param nextRadius number
--- @return SafeZoneData
local function getNextSafeZoneLegacy(currentZone, nextRadius)

    assert(currentZone and currentZone.center and currentZone.radius, 'currentZone invalid!')
    assert(type(nextRadius) == 'number' and nextRadius > 0, 'nextRadius invalid')
    assert(currentZone.radius > nextRadius, 'next radius must be smaller than current')

    local maxOffset = currentZone.radius - nextRadius
    local minOffset = maxOffset * 0.3
    local angle = math.random() * 2 * math.pi
    local distance = minOffset + math.random() * (maxOffset - minOffset)

    local x = currentZone.center.x + math.cos(angle) * distance
    local y = currentZone.center.y + math.sin(angle) * distance

    return {
        center = vector3(x, y, currentZone.center.z),
        radius = nextRadius,
    }
end

--- Gera um unico candidato de zona usando a logica original de offset.
--- @param currentZone SafeZoneData
--- @param nextRadius number
--- @return SafeZoneData, number angle, number distance
local function sampleCandidate(currentZone, nextRadius)

    local maxOffset = currentZone.radius - nextRadius
    local minOffset = maxOffset * 0.3
    local angle = math.random() * 2 * math.pi
    local distance = minOffset + math.random() * (maxOffset - minOffset)

    local x = currentZone.center.x + math.cos(angle) * distance
    local y = currentZone.center.y + math.sin(angle) * distance

    return {
        center = vector3(x, y, currentZone.center.z),
        radius = nextRadius,
    }, angle, distance
end

--- Escolhe o melhor candidato entre N amostras, priorizando menor densidade de jogadores.
--- Retorna tambem a contagem de jogadores do candidato escolhido (para log/debug).
--- @param currentZone SafeZoneData
--- @param nextRadius number
--- @param bucket number
--- @param opts SafeZoneDynamicOpts
--- @return SafeZoneData zone, number playerCount
local function getNextSafeZoneWeighted(currentZone, nextRadius, bucket, opts)

    assert(currentZone and currentZone.center and currentZone.radius, 'currentZone invalid!')
    assert(type(nextRadius) == 'number' and nextRadius > 0, 'nextRadius invalid')
    assert(currentZone.radius > nextRadius, 'next radius must be smaller than current')
    assert(type(bucket) == 'number', 'bucket invalid')

    opts = opts or DEFAULT_OPTS
    local candidates = math.max(1, math.floor(opts.candidates or DEFAULT_OPTS.candidates))
    local areaRadius = opts.areaRadius or DEFAULT_OPTS.areaRadius
    local minImprovement = opts.minImprovement or DEFAULT_OPTS.minImprovement
    local jitter = opts.radiusJitter or DEFAULT_OPTS.radiusJitter

    -- Raio final da zona: jitter aplicado uma vez (consistente entre candidatos),
    -- garantindo que seja sempre menor que o raio atual.
    local nextRadius = jitterRadius(currentZone.radius, nextRadius, jitter)

    local samples = {}
    local total = 0

    for i = 1, candidates do
        local zone = sampleCandidate(currentZone, nextRadius)
        local count = getPlayersInArea(bucket, zone.center, areaRadius)
        samples[i] = { zone = zone, count = count }
        total += count
    end

    local avg = total / candidates
    local best = samples[1]

    for i = 2, candidates do
        if samples[i].count < best.count then
            best = samples[i]
        end
    end

    -- Se nenhum candidato tiver densidade significativamente abaixo da media,
    -- usa o algoritmo atual (offset puro aleatorio) para nao enviesar a partida.
    local improvement = (avg > 0) and ((avg - best.count) / avg) or 0

    if best.count == 0 or improvement >= minImprovement then
        return best.zone, best.count
    end

    return getNextSafeZoneLegacy(currentZone, nextRadius), best.count
end

--- Centro posicionado em torno da borda da zona atual, controlado por gasOverlap.
--- gasOverlap = 0.5 → centro na borda (metade dentro, metade fora do gas).
--- @param currentZone SafeZoneData
--- @param nextRadius number
--- @param bucket number
--- @param opts SafeZoneDynamicOpts
--- @return SafeZoneData zone, number playerCount
local function getNextFinalSafeZone(currentZone, nextRadius, bucket, opts)

    assert(currentZone and currentZone.center and currentZone.radius, 'currentZone invalid!')
    assert(type(nextRadius) == 'number' and nextRadius > 0, 'nextRadius invalid')
    assert(currentZone.radius > nextRadius, 'next radius must be smaller than current')
    assert(type(bucket) == 'number', 'bucket invalid')

    opts = opts or DEFAULT_OPTS
    local candidates = math.max(1, math.floor(opts.candidates or DEFAULT_OPTS.candidates))
    local areaRadius = opts.areaRadius or DEFAULT_OPTS.areaRadius
    local overlap = math.max(0, math.min(1, opts.gasOverlap or 0.5))
    local jitter = opts.radiusJitter or DEFAULT_OPTS.radiusJitter

    nextRadius = jitterRadius(currentZone.radius, nextRadius, jitter)

    local baseDist = currentZone.radius - nextRadius * (1 - 2 * overlap)
    local distJitter = 0.20
    local minDist = baseDist * (1 - distJitter)
    local maxDist = baseDist * (1 + distJitter)
    local hardLimit = currentZone.radius + nextRadius * 0.9

    if maxDist > hardLimit then maxDist = hardLimit end
    if minDist < 0 then minDist = 0 end

    local best, bestCount

    for i = 1, candidates do

        local angle = math.random() * 2 * math.pi
        local distance = minDist + math.random() * (maxDist - minDist)

        local x = currentZone.center.x + math.cos(angle) * distance
        local y = currentZone.center.y + math.sin(angle) * distance
        local zone = {
            center = vector3(x, y, currentZone.center.z),
            radius = nextRadius,
        }

        local count = getPlayersInArea(bucket, zone.center, areaRadius)

        if not best or count < bestCount then
            best = zone
            bestCount = count
        end
    end

    return best, bestCount or 0
end

--- Assinatura legada: getNextSafeZone(currentZone, nextRadius) -> fallback aleatorio.
--- Assinatura dinamica: getNextSafeZone(currentZone, nextRadius, bucket, opts) -> menor densidade.
--- @param currentZone SafeZoneData
--- @param nextRadius number
--- @param bucket? number
--- @param opts? SafeZoneDynamicOpts
--- @return SafeZoneData
Core.getNextSafeZone = function(currentZone, nextRadius, bucket, opts)

    if bucket and opts then
        local zone = getNextSafeZoneWeighted(currentZone, nextRadius, bucket, opts)
        return zone
    end

    -- Path legacy (sem bucket): ainda assim aplica jitter no raio quando opts
    -- estiver presente, mantendo a invariante de encolhimento.
    if opts and opts.radiusJitter then
        nextRadius = jitterRadius(currentZone.radius, nextRadius, opts.radiusJitter)
    end

    return getNextSafeZoneLegacy(currentZone, nextRadius)
end

--- @param currentZone SafeZoneData
--- @param nextRadius number
--- @param bucket number
--- @param opts? SafeZoneDynamicOpts
--- @return SafeZoneData
Core.getNextFinalSafeZone = function(currentZone, nextRadius, bucket, opts)
    local zone = getNextFinalSafeZone(currentZone, nextRadius, bucket, opts or DEFAULT_OPTS)
    return zone
end
