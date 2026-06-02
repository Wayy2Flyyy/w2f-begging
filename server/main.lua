local qbx = exports.qbx_core
local ox_inventory = exports.ox_inventory

local activeBeggars = {}
local lastDonationAt = {}
local earningsWindow = {}

local function nowMs()
    return GetGameTimer()
end

local function hasBeggingItem(source)
    for itemName in pairs(Config.Items) do
        if (ox_inventory:GetItemCount(source, itemName) or 0) > 0 then
            return true
        end
    end
    return false
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

RegisterNetEvent('w2f-begging:server:setActive', function(active)
    local src = source

    if active then
        if not hasBeggingItem(src) then
            return
        end

        activeBeggars[src] = true
        return
    end

    clearPlayerState(src)
end)

lib.callback.register('w2f-begging:requestDonation', function(source)
    if not activeBeggars[source] then
        return { ok = false, reason = 'inactive' }
    end

    if not hasBeggingItem(source) then
        clearPlayerState(source)
        return { ok = false, reason = 'item' }
    end

    local player = qbx:GetPlayer(source)
    if not player then
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
    if not player.Functions.AddMoney(account, amount, Config.Reward.reason or 'w2f-begging') then
        return { ok = false, reason = 'money' }
    end

    lastDonationAt[source] = t
    earningsWindow[source][#earningsWindow[source] + 1] = { t = t, amount = amount }

    if Config.Debug then
        print(('[w2f-begging] %s received $%d'):format(source, amount))
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
