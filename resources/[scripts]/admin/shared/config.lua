---@class AdminConfig
---@field role string Required role to use admin commands
---@field bypassConsole boolean Allow the server console (source 0) to run commands without a role
---@field permanentBanDate string expires_at value used for permanent bans
---@field notifyDuration number Default notify duration (seconds)
---@field lobbyResource string Resource that owns the lobby (for /setarlobby)
---@field allowAdminCommand boolean TEMPORARIO/DEV: habilita /pegaradmin (qualquer jogador vira admin)
Config = {
    role = 'admin',
    bypassConsole = true,
    permanentBanDate = '2099-12-31 23:59:59',
    notifyDuration = 5,
    lobbyResource = 'lobby',
    -- ⚠️ TEMPORARIO/DEV: habilita /pegaradmin. DEIXE false EM PRODUCAO.
    allowAdminCommand = true,
}

---@type table<string, { title: string, color: string }>
Config.notifyTypes = {
    success    = { title = 'Sucesso',     color = '#3ad17a' },
    error      = { title = 'Erro',        color = '#e0566b' },
    info       = { title = 'Informacao',  color = '#4f8dff' },
    warning    = { title = 'Atencao',     color = '#e0a73a' },
    importante = { title = 'Importante',  color = '#c8fe4e' },
}
