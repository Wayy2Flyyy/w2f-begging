-- ox_inventory integration (event + export entrypoints).

---@param ... any
---@return string?
local function resolveItemName(...)
    local a1, a2, a3 = ...

    if type(a3) == 'table' and a3.name then
        return a3.name
    end

    if type(a2) == 'table' and a2.name then
        return a2.name
    end

    if type(a1) == 'table' and a1.name then
        return a1.name
    end

    if type(a1) == 'string' then
        return a1
    end

    return nil
end

local function useFromInventory(itemName)
    if GetResourceState('w2f-begging') ~= 'started' then
        lib.notify({
            title = Config.Notify.title,
            description = Config.Notify.unavailable,
            type = 'error',
        })
        return false
    end

    if not itemName or not Config.Items[itemName] then
        lib.notify({
            title = Config.Notify.title,
            description = Config.Notify.invalidItem,
            type = 'error',
        })
        return false
    end

    return exports['w2f-begging']:UseBeggingItem(itemName)
end

RegisterNetEvent('w2f-begging:client:useItem', function(_data, itemInfo)
    useFromInventory(resolveItemName(_data, itemInfo) or (itemInfo and itemInfo.name))
end)

--- ox_inventory client.export (nil is always passed as the first argument).
exports('useCardboardSign', function(...)
    return useFromInventory(resolveItemName(...) or 'cardboard_sign')
end)

exports('useBeggingCup', function(...)
    return useFromInventory(resolveItemName(...) or 'begging_cup')
end)
