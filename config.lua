Config = {}

Config.Debug = false

-- Qbox is preferred when auto-detecting. Supported: 'auto', 'qbox', 'qbcore', 'esx'.
Config.Framework = 'auto'

-- ox_inventory is preferred when auto-detecting. Supported: 'auto', 'ox', 'qb', 'esx'.
-- Qbox requires ox_inventory; native QB and ESX inventories are also supported.
Config.Inventory = 'auto'

-- Inventory items that toggle begging. Add matching item definitions to your inventory.
Config.Items = {
    cardboard_sign = {
        signProp = `prop_beggers_sign_03`,
        mode = 'sign',
    },
    begging_cup = {
        mode = 'cup',
        scenario = 'WORLD_HUMAN_BUM_SLUMPED',
    },
}

Config.Anim = {
    dict = 'amb@world_human_bum_freeway@male@base',
    clip = 'base',
    flag = 49, -- upper body loop, allow movement
    refreshMs = 400,
    bone = 28422,
    propOffset = vec3(0.0, 0.0, 0.0),
    propRotation = vec3(0.0, 0.0, 0.0),
}

Config.Begging = {
    scanRadius = 14.0,
    approachDistance = 1.75,
    scanIntervalMs = 2500,
    approachTimeoutMs = 18000,
    stopOnSprint = true,
    stopOnEnterVehicle = true,
    stopOnCombat = true,
}

Config.Npc = {
    -- Chance a nearby pedestrian will be picked to approach (per scan tick).
    pickChance = 0.42,
    -- Chance they walk past without donating after approaching.
    walkAwayChance = 0.12,
    cooldownPerPedMs = 180000,
    maxConcurrentApproaches = 1,
}

Config.Reward = {
    account = 'cash',
    min = 2,
    max = 22,
    reason = 'w2f-begging',
    -- Server-side anti-farm caps.
    minIntervalMs = 6000,
    maxPerMinute = 95,
}

Config.Notify = {
    title = 'Begging',
    startedSign = 'You hold up your sign and start asking for spare change.',
    startedCup = 'You set out your cup and settle in for spare change.',
    stoppedSign = 'You put the sign away.',
    stoppedCup = 'You pick up your cup and move on.',
    wrongItem = 'Stop begging before switching to another item.',
    donated = 'Someone dropped $%d in your cup.',
    walkedAway = 'A passerby looked away and kept walking.',
    capped = 'You have had enough handouts for now — take a break.',
    cannot = 'You cannot beg right now.',
    unavailable = 'Begging is unavailable right now.',
    invalidItem = 'This item cannot be used.',
    missingItem = 'You no longer have the item needed to beg.',
}

-- Key to stop begging while the sign is out (rebind in GTA settings).
Config.StopKey = 'X'
Config.StopCommand = 'stopbegging'
