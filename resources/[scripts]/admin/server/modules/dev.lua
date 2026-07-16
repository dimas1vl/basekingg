if Config.allowAdminCommand then
    RegisterCommand('pegaradmin', function(src)
        src = tonumber(src)
        if not src or src == 0 then
            Admin.log('warning', '/pegaradmin nao pode ser usado pelo console.')
            return
        end

        local userId = Core.getUserId(src)
        if not userId then
            return Admin.notify(src, 'error', 'Nao foi possivel identificar seu usuario.')
        end

        Admin.act.setRole(src, userId, 'admin')
        Admin.notify(src, 'importante', 'Voce agora e admin (comando temporario).')
        Admin.log('warning', ('/pegaradmin usado por src=%s userId=%s'):format(src, userId))
    end, false)

    Admin.log('warning', '/pegaradmin ATIVO (Config.allowAdminCommand = true). Desative em producao.')
end
