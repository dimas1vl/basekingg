-- Shared helper exposed similarly to kingg/lobby resources: GetInventario()
-- returns the server-side Inventario API. The client-side counterpart returns
-- nil because no client export is registered with that name here.

local isServer = IsDuplicityVersion()

if isServer then
    ---@return table Inventario server API
    function GetInventario()
        return exports['lobby_inventory']:GetInventario()
    end
end

---Helper used by catalog loaders to register items at file scope.
---Each catalog/<category>/<file>.lua simply returns a list of items; this
---registry is the in-process bridge between shared script load order and
---the server-side catalog module.
---@class _InventarioCatalogRegistry
---@field items table[] Items collected from all catalog files at load time
_InventarioCatalogRegistry = _InventarioCatalogRegistry or { items = {} }

---Append a list of items to the registry (used by catalog files).
---@param list table[]
function _InventarioCatalogRegistry:add(list)
    if type(list) ~= 'table' then return end
    for i = 1, #list do
        self.items[#self.items + 1] = list[i]
    end
end
