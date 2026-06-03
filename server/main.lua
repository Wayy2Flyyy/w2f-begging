local activeBeggars = {}
local lastDonationAt = {}
local earningsWindow = {}

local frameworkName
local framework
local inventoryName

local function resourceStarted(name)
    return GetResourceState(name) == 'started'
end

local function detectFramework()
    local configured = (Config.Framework or 'auto'):lower()

    if configured == 'auto' then
        if resourceStarted('qbx_core') then
            configured = 'qbox'
        elseif resourceStarted('qb-core') then
            configured = 'qbcore'
        elseif resourceStarted('es_extended') then
            configured = 'esx'
        end
    end

    if configured == 'qbox' and resourceStarted('qbx_core') then
        frameworkName = 'qbox'
        framework = exports.qbx_core
    elseif configured == 'qbcore' and resourceStarted('qb-core') then
        frameworkName = 'qbcore'
        framework = exports['qb-core']:GetCoreObject()
    elseif configured == 'esx' and resourceStarted('es_extended') then
        frameworkName = 'esx'
        framework = exports.es_extended:getSharedObject()
    else
        error(('[w2f-begging] Unable to initialize framework "%s". Start qbx_core, qb-core, or es_extended before this resource.'):format(configured))
    end
end

local function detectInventory()
    local configured = (Config.Inventory or 'auto'):lower()

    if configured == 'auto' then
        if resourceStarted('ox_inventory') then
            configured = 'ox'
        elseif frameworkName == 'qbcore' then
            configured = 'qb'
        elseif frameworkName == 'esx' then
            configured = 'esx'
        end
    end

    if configured == 'ox' and resourceStarted('ox_inventory') then
        inventoryName = 'ox'
    elseif configured == 'qb' and frameworkName == 'qbcore' then
        inventoryName = 'qb'
    elseif configured == 'esx' and frameworkName == 'esx' then
        inventoryName = 'esx'
    else
        error(('[w2f-begging] Unable to initialize inventory "%s" for framework "%s".'):format(configured, frameworkName))
    end
end

local function getPlayer(source)
    if frameworkName == 'qbox' then
        return framework:GetPlayer(source)
    end

    if frameworkName == 'qbcore' then
        return framework.Functions.GetPlayer(source)
    end

    return framework.GetPlayerFromId(source)
end

local function getItemCount(source, itemName)
    if inventoryName == 'ox' then
        return exports.ox_inventory:GetItemCount(source, itemName) or 0
    end

    local player = getPlayer(source)
    if not player then return 0 end

    if inventoryName == 'qb' then
        local item = player.Functions.GetItemByName(itemName)
        return item and (item.amount or item.count or 0) or 0
    end

    local item = player.getInventoryItem(itemName)
    return item and (item.count or item.amount or 0) or 0
end

local function hasBeggingItem(source, itemName)
    if itemName then
        return Config.Items[itemName] ~= nil and getItemCount(source, itemName) > 0
    end

    for name in pairs(Config.Items) do
        if getItemCount(source, name) > 0 then
            return true
        end
    end

    return false
end

local function addMoney(source, account, amount, reason)
    local player = getPlayer(source)
    if not player then return false end

    if frameworkName == 'esx' then
        if account == 'cash' or account == 'money' then
            player.addMoney(amount, reason)
        else
            player.addAccountMoney(account, amount, reason)
        end
        return true
    end

    return player.Functions.AddMoney(account, amount, reason) == true
end

local function registerUsableItems()
    -- ox_inventory invokes the client exports configured in install/ox_inventory-items.lua.
    if inventoryName == 'ox' then return end

    for itemName in pairs(Config.Items) do
        local usableItem = itemName
        if frameworkName == 'qbcore' then
            framework.Functions.CreateUseableItem(usableItem, function(source)
                TriggerClientEvent('w2f-begging:client:useItem', source, usableItem)
            end)
        elseif frameworkName == 'esx' then
            framework.RegisterUsableItem(usableItem, function(source)
                TriggerClientEvent('w2f-begging:client:useItem', source, usableItem)
            end)
        end
    end
end

local function nowMs()
    return GetGameTimer()
end

local function pruneEarnings(source)
    local window = earningsWindow[source]
    if not window then return 0 end

    local cutoff = nowMs() - 60000
    local total = 0
    local i = 1

    while i <= #window do
        if window[i].t < cutoff then
            table.remove(window, i)
        else
            total += window[i].amount
            i += 1
        end
    end

    earningsWindow[source] = window
    return total
end

local function clearPlayerState(source)
    activeBeggars[source] = nil
    lastDonationAt[source] = nil
    earningsWindow[source] = nil
end

detectFramework()
detectInventory()
registerUsableItems()

print(('[w2f-begging] Initialized with framework=%s inventory=%s'):format(frameworkName, inventoryName))

RegisterNetEvent('w2f-begging:server:setActive', function(active)
    if active == false then
        clearPlayerState(source)
    end
end)

lib.callback.register('w2f-begging:setActive', function(source, itemName)
    if type(itemName) ~= 'string' or not hasBeggingItem(source, itemName) then
        clearPlayerState(source)
        return false
    end

    activeBeggars[source] = itemName
    return true
end)

lib.callback.register('w2f-begging:requestDonation', function(source)
    local activeItem = activeBeggars[source]
    if not activeItem then
        return { ok = false, reason = 'inactive' }
    end

    if not hasBeggingItem(source, activeItem) then
        clearPlayerState(source)
        return { ok = false, reason = 'item' }
    end

    if not getPlayer(source) then
        clearPlayerState(source)
        return { ok = false, reason = 'player' }
    end

    local t = nowMs()
    local last = lastDonationAt[source] or 0
    if t - last < (Config.Reward.minIntervalMs or 6000) then
        return { ok = false, reason = 'cooldown' }
    end

    earningsWindow[source] = earningsWindow[source] or {}
    local earned = pruneEarnings(source)
    if earned >= (Config.Reward.maxPerMinute or 95) then
        return { ok = false, reason = 'capped' }
    end

    local minAmt = Config.Reward.min or 1
    local maxAmt = Config.Reward.max or 15
    local amount = math.random(minAmt, maxAmt)

    local remaining = (Config.Reward.maxPerMinute or 95) - earned
    if amount > remaining then
        amount = math.max(remaining, 0)
    end
    if amount <= 0 then
        return { ok = false, reason = 'capped' }
    end

    local account = Config.Reward.account or 'cash'
    if not addMoney(source, account, amount, Config.Reward.reason or 'w2f-begging') then
        return { ok = false, reason = 'money' }
    end

    lastDonationAt[source] = t
    earningsWindow[source][#earningsWindow[source] + 1] = { t = t, amount = amount }

    if Config.Debug then
        print(('[w2f-begging] %s received $%d (%s/%s)'):format(source, amount, frameworkName, inventoryName))
    end

    return { ok = true, amount = amount }
end)

AddEventHandler('playerDropped', function()
    clearPlayerState(source)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    activeBeggars = {}
    lastDonationAt = {}
    earningsWindow = {}
end)
