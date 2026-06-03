    -- ========================================================================
    -- w2f-begging — passive homeless begging (cardboard sign + NPC donations)
    -- Requires: ensure w2f-begging (loads with [w2f])
    -- Icons: copy install/images/*.png → ox_inventory/web/images/
    -- ========================================================================

    ['cardboard_sign'] = {
        label = 'Cardboard Sign',
        weight = 350,
        stack = false,
        close = true,
        consume = 0,
        description = 'A worn sign for asking strangers for spare change. Use to start or stop begging.',
        client = {
            image = 'cardboard_sign.png',
            export = 'w2f-begging.useCardboardSign',
        },
    },

    ['begging_cup'] = {
        label = 'Begging Cup',
        weight = 120,
        stack = false,
        close = true,
        consume = 0,
        description = 'An old cup to catch coins from passersby. Use to start or stop begging.',
        client = {
            image = 'begging_cup.png',
            export = 'w2f-begging.useBeggingCup',
        },
    },
