local isBegging = false
local begMode = 'sign' -- 'sign' | 'cup'
local activeItem = nil
local signProp = nil
local animThreadRunning = false
local npcThreadRunning = false
local pedCooldowns = {}
local activeApproachCount = 0
local approachingPeds = {}
local stopBegging

local function notify(description, nType)
    lib.notify({
        title = Config.Notify.title,
        description = description,
        type = nType or 'inform',
    })
end

local function setServerActive(active)
    TriggerServerEvent('w2f-begging:server:setActive', active)
end

local function requestServerActive(itemName)
    return lib.callback.await('w2f-begging:setActive', false, itemName) == true
end

local function canBeg()
    local ped = cache.ped or PlayerPedId()
    if IsEntityDead(ped) then return false end
    if Config.Begging.stopOnEnterVehicle and IsPedInAnyVehicle(ped, false) then return false end
    if Config.Begging.stopOnCombat and IsPedInMeleeCombat(ped) then return false end
    return true
end

local function shouldStopBegging()
    if not isBegging then return false end
    local ped = cache.ped or PlayerPedId()
    if IsEntityDead(ped) then return true end
    if Config.Begging.stopOnEnterVehicle and IsPedInAnyVehicle(ped, false) then return true end
    if Config.Begging.stopOnSprint and IsPedSprinting(ped) then return true end
    if Config.Begging.stopOnCombat and IsPedInMeleeCombat(ped) then return true end
    return false
end

local function destroySignProp()
    if signProp and DoesEntityExist(signProp) then
        DetachEntity(signProp, true, true)
        DeleteEntity(signProp)
    end
    signProp = nil
end

local function attachSignProp()
    if begMode ~= 'sign' then return end
    destroySignProp()
    local ped = cache.ped or PlayerPedId()
    local itemCfg = Config.Items[activeItem or 'cardboard_sign'] or Config.Items.cardboard_sign or {}
    local model = itemCfg.signProp or `prop_beggers_sign_03`
    if not lib.requestModel(model, 2000) then return end

    local coords = GetEntityCoords(ped)
    signProp = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)
    local bone = Config.Anim.bone or 28422
    local off = Config.Anim.propOffset or vec3(0.0, 0.0, 0.0)
    local rot = Config.Anim.propRotation or vec3(0.0, 0.0, 0.0)

    AttachEntityToEntity(
        signProp, ped, GetPedBoneIndex(ped, bone),
        off.x, off.y, off.z, rot.x, rot.y, rot.z,
        true, true, false, true, 1, true
    )
    SetModelAsNoLongerNeeded(model)
end

local function playBegAnim()
    local ped = cache.ped or PlayerPedId()
    if begMode == 'cup' then
        local scenario = (Config.Items.begging_cup or {}).scenario or 'WORLD_HUMAN_BUM_SLUMPED'
        if not IsPedUsingScenario(ped, scenario) and not IsPedActiveInScenario(ped) then
            TaskStartScenarioInPlace(ped, scenario, 0, true)
        end
        return
    end

    local dict, clip = Config.Anim.dict, Config.Anim.clip
    if lib.requestAnimDict(dict, 1000) and not IsEntityPlayingAnim(ped, dict, clip, 3) then
        TaskPlayAnim(ped, dict, clip, 3.0, 3.0, -1, Config.Anim.flag or 49, 0, false, false, false)
    end
end

local function stopBegAnim()
    local ped = cache.ped or PlayerPedId()
    if begMode == 'cup' then
        ClearPedTasks(ped)
        return
    end
    local dict, clip = Config.Anim.dict, Config.Anim.clip
    StopAnimTask(ped, dict, clip, 3.0)
end

local function isPedEligible(npc, playerCoords)
    if not npc or npc == 0 or not DoesEntityExist(npc) then return false end
    if IsPedAPlayer(npc) then return false end
    if IsPedDeadOrDying(npc, true) then return false end
    if IsPedInAnyVehicle(npc, false) then return false end
    if IsPedFleeing(npc) then return false end
    if IsPedInCombat(npc, 0) then return false end
    if approachingPeds[npc] then return false end

    local last = pedCooldowns[npc]
    if last and (GetGameTimer() - last) < (Config.Npc.cooldownPerPedMs or 180000) then
        return false
    end

    local dist = #(GetEntityCoords(npc) - playerCoords)
    if dist > (Config.Begging.scanRadius or 14.0) or dist < 2.0 then
        return false
    end

    return true
end

local function releaseNpc(npc, walkAway)
    if not npc or not DoesEntityExist(npc) then return end
    ClearPedTasks(npc)
    SetBlockingOfNonTemporaryEvents(npc, false)
    SetPedFleeAttributes(npc, 0, false)
    if walkAway then
        TaskWanderStandard(npc, 10.0, 10)
    end
end

local function markPedCooldown(npc)
    if npc and npc ~= 0 then
        pedCooldowns[npc] = GetGameTimer()
    end
end

local function prunePedCooldowns()
    local cutoff = GetGameTimer() - (Config.Npc.cooldownPerPedMs or 180000)
    for ped, last in pairs(pedCooldowns) do
        if last < cutoff or not DoesEntityExist(ped) then
            pedCooldowns[ped] = nil
        end
    end
end

local function trackApproach(npc, active)
    if not npc or npc == 0 then return end

    if active then
        if approachingPeds[npc] then return end
        approachingPeds[npc] = true
        activeApproachCount += 1
        return
    end

    if not approachingPeds[npc] then return end
    approachingPeds[npc] = nil
    activeApproachCount = math.max(activeApproachCount - 1, 0)
end

local function clearApproaches()
    for npc in pairs(approachingPeds) do
        if DoesEntityExist(npc) then
            releaseNpc(npc, true)
        end
    end

    approachingPeds = {}
    activeApproachCount = 0
end

local function handleNpcApproach(npc)
    local playerPed = cache.ped or PlayerPedId()
    local startedAt = GetGameTimer()
    local timeout = Config.Begging.approachTimeoutMs or 18000
    local targetDist = Config.Begging.approachDistance or 1.75

    trackApproach(npc, true)

    SetBlockingOfNonTemporaryEvents(npc, true)
    SetPedFleeAttributes(npc, 0, false)
    TaskGoToEntity(npc, playerPed, -1, targetDist, 1.0, 0, 0)

    while isBegging and DoesEntityExist(npc) do
        Wait(200)
        if shouldStopBegging() then
            releaseNpc(npc, true)
            markPedCooldown(npc)
            trackApproach(npc, false)
            return
        end
        if GetGameTimer() - startedAt > timeout then
            releaseNpc(npc, true)
            markPedCooldown(npc)
            trackApproach(npc, false)
            return
        end

        local pCoords = GetEntityCoords(playerPed)
        local nCoords = GetEntityCoords(npc)
        if #(pCoords - nCoords) <= targetDist + 0.35 then
            break
        end
    end

    if not isBegging or not DoesEntityExist(npc) then
        releaseNpc(npc, false)
        trackApproach(npc, false)
        return
    end

    TaskTurnPedToFaceEntity(npc, playerPed, 1200)
    Wait(900)

    if not isBegging or not DoesEntityExist(npc) or shouldStopBegging() then
        releaseNpc(npc, false)
        trackApproach(npc, false)
        return
    end

    if math.random() < (Config.Npc.walkAwayChance or 0.12) then
        notify(Config.Notify.walkedAway, 'inform')
        releaseNpc(npc, true)
        markPedCooldown(npc)
        trackApproach(npc, false)
        return
    end

    if lib.requestAnimDict('mp_common', 500) then
        TaskPlayAnim(npc, 'mp_common', 'givetake1_a', 8.0, -8.0, 2000, 0, 0, false, false, false)
        Wait(1600)
    end

    if not isBegging or shouldStopBegging() then
        releaseNpc(npc, true)
        trackApproach(npc, false)
        return
    end

    local result = lib.callback.await('w2f-begging:requestDonation', false)
    if result and result.ok and result.amount then
        notify(Config.Notify.donated:format(result.amount), 'success')
    elseif result and result.reason == 'capped' then
        notify(Config.Notify.capped, 'error')
    elseif result and result.reason == 'item' then
        stopBegging(true)
        notify(Config.Notify.missingItem, 'error')
    end

    releaseNpc(npc, true)
    markPedCooldown(npc)
    trackApproach(npc, false)
end

local function pickNearbyNpc()
    local playerPed = cache.ped or PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local nearby = lib.getNearbyPeds(playerCoords, Config.Begging.scanRadius or 14.0)
    if #nearby == 0 then return nil end

    local candidates = {}
    for i = 1, #nearby do
        local npc = nearby[i].ped
        if isPedEligible(npc, playerCoords) then
            candidates[#candidates + 1] = npc
        end
    end
    if #candidates == 0 then return nil end
    return candidates[math.random(#candidates)]
end

local function resolveItemMode(itemName)
    if itemName and Config.Items[itemName] then
        return Config.Items[itemName].mode or 'sign', itemName
    end
    return 'sign', 'cardboard_sign'
end

local function startedMessage()
    if begMode == 'cup' then
        return Config.Notify.startedCup
    end
    return Config.Notify.startedSign
end

local function stoppedMessage()
    if begMode == 'cup' then
        return Config.Notify.stoppedCup
    end
    return Config.Notify.stoppedSign
end

local function startNpcScanner()
    if npcThreadRunning then return end
    npcThreadRunning = true

    CreateThread(function()
        while isBegging do
            Wait(Config.Begging.scanIntervalMs or 2500)

            if shouldStopBegging() then
                break
            end

            prunePedCooldowns()

            if activeApproachCount >= (Config.Npc.maxConcurrentApproaches or 1) then
                goto continue
            end

            if math.random() > (Config.Npc.pickChance or 0.42) then
                goto continue
            end

            local npc = pickNearbyNpc()
            if npc then
                CreateThread(function()
                    handleNpcApproach(npc)
                end)
            end

            ::continue::
        end
        npcThreadRunning = false
    end)
end

local function startAnimThread()
    if animThreadRunning then return end
    animThreadRunning = true

    CreateThread(function()
        while isBegging do
            if shouldStopBegging() then
                stopBegging(false)
                break
            end
            playBegAnim()
            Wait(Config.Anim.refreshMs or 400)
        end
        if animThreadRunning then
            stopBegAnim()
            destroySignProp()
        end
        animThreadRunning = false
    end)
end

stopBegging = function(silent)
    if not isBegging then return end
    isBegging = false
    setServerActive(false)
    stopBegAnim()
    destroySignProp()
    clearApproaches()

    activeItem = nil

    if not silent then
        notify(stoppedMessage(), 'inform')
    end
end

local function startBegging(itemName)
    if isBegging then return end
    local mode, resolvedItem = resolveItemMode(itemName)
    begMode = mode
    activeItem = resolvedItem
    if not canBeg() then
        notify(Config.Notify.cannot, 'error')
        return false
    end

    if not requestServerActive(activeItem) then
        activeItem = nil
        notify(Config.Notify.missingItem, 'error')
        return false
    end

    isBegging = true
    attachSignProp()
    playBegAnim()
    startAnimThread()
    startNpcScanner()
    notify(startedMessage(), 'success')
    return true
end

local function toggleBegging(itemName)
    local mode = select(1, resolveItemMode(itemName))

    if isBegging then
        if activeItem and itemName and activeItem ~= itemName then
            notify(Config.Notify.wrongItem, 'error')
            return false
        end
        stopBegging(false)
        return true
    end

    return startBegging(itemName)
end

RegisterCommand(Config.StopCommand or 'stopbegging', function()
    if isBegging then stopBegging(false) end
end, false)

RegisterKeyMapping(Config.StopCommand or 'stopbegging', 'Stop begging', 'keyboard', Config.StopKey or 'X')

exports('UseBeggingItem', function(itemName)
    toggleBegging(itemName)
    return false
end)

exports('IsBegging', function()
    return isBegging
end)

exports('GetActiveBeggingItem', function()
    return activeItem
end)

exports('StartBegging', function(itemName)
    return startBegging(itemName or 'cardboard_sign')
end)

exports('StopBegging', stopBegging)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    stopBegging(true)
end)

AddEventHandler('gameEventTriggered', function(name)
    if name == 'CEventNetworkEntityDamage' and isBegging then
        local ped = cache.ped or PlayerPedId()
        if IsEntityDead(ped) then
            stopBegging(true)
        end
    end
end)
