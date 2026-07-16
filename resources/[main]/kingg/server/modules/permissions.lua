while not Core do
    Wait(100)
end

---@param user_id number
---@param role 'user' | 'admin' | 'spec'
---@return boolean
function Core.hasRole(user_id, role)
    local user_info = Core.users_info[user_id]
    if not user_info then
        log('error', ('User %s not found'):format(user_id))
        return false
    end
    return user_info.role == role
end