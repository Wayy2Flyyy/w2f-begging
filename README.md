# w2f-begging

Passive homeless begging roleplay for **Qbox**, **QBCore**, and **ESX**. Players can use a cardboard sign or begging cup, play an idle animation, attract nearby NPCs, and receive server-authorized random donations.

Qbox remains the primary and preferred setup. Framework and inventory selection is auto-detected in this order:

- Framework: `qbx_core` → `qb-core` → `es_extended`
- Inventory: `ox_inventory` → native QBCore inventory → native ESX inventory

## Features

- Qbox-first support with QBCore and ESX compatibility.
- ox_inventory support on all frameworks.
- Native QBCore and ESX usable-item registration when ox_inventory is not used.
- Server-side item checks, donation cooldowns, and per-minute earning caps.
- Sign prop and cup scenario modes.
- Configurable NPC behavior, rewards, animations, stop key, and notifications.

## Requirements

| Setup | Required resources |
|---|---|
| Qbox (recommended) | `ox_lib`, `qbx_core`, `ox_inventory` |
| QBCore + ox_inventory | `ox_lib`, `qb-core`, `ox_inventory` |
| QBCore native inventory | `ox_lib`, `qb-core` |
| ESX + ox_inventory | `ox_lib`, `es_extended`, `ox_inventory` |
| ESX native inventory | `ox_lib`, `es_extended` |

`ox_lib` is always required. Qbox must use `ox_inventory`.

## Install

1. Place the resource in your resources directory, such as `[w2f]/w2f-begging`.
2. Install the two items using the appropriate section below.
3. Ensure your framework, inventory, and `ox_lib` before `w2f-begging`.
4. Leave `Config.Framework` and `Config.Inventory` set to `auto`, or explicitly select your setup in `config.lua`.

### Qbox or ox_inventory

1. Paste `install/ox_inventory-items.lua` into `ox_inventory/data/items.lua`.
2. Copy both images from `install/images/` to `ox_inventory/web/images/`.
3. Ensure resources in this order:

```cfg
ensure ox_lib
ensure qbx_core # or qb-core / es_extended
ensure ox_inventory
ensure w2f-begging
```

### Native QBCore inventory

1. Add the entries from `install/qb-core-items.lua` to `qb-core/shared/items.lua`.
2. Copy both images from `install/images/` to your inventory's image directory, commonly `qb-inventory/html/images/`.
3. Ensure resources in this order:

```cfg
ensure ox_lib
ensure qb-core
ensure qb-inventory
ensure w2f-begging
```

### Native ESX inventory

1. Import `install/esx-items.sql` if your ESX inventory uses the standard `items` table. Adjust it if your schema differs.
2. Ensure resources in this order:

```cfg
ensure ox_lib
ensure es_extended
ensure w2f-begging
```

## Configuration

The defaults use auto-detection and prefer Qbox plus ox_inventory:

```lua
Config.Framework = 'auto' -- auto, qbox, qbcore, esx
Config.Inventory = 'auto' -- auto, ox, qb, esx
```

Explicit examples:

```lua
-- Qbox (recommended)
Config.Framework = 'qbox'
Config.Inventory = 'ox'

-- QBCore with native inventory
Config.Framework = 'qbcore'
Config.Inventory = 'qb'

-- ESX with native inventory
Config.Framework = 'esx'
Config.Inventory = 'esx'
```

Edit `config.lua` to customize scan radius, donation amounts, anti-farm caps, NPC pick rates, animations, and notification text.

For ESX, `Config.Reward.account = 'cash'` or `'money'` pays wallet money. Other values, such as `'bank'`, are passed to `addAccountMoney`. Qbox and QBCore pass the configured account to `Player.Functions.AddMoney`.

## Usage

| Item | Mode | Behavior |
|---|---|---|
| `cardboard_sign` | Sign | Upper-body animation with an attached sign prop |
| `begging_cup` | Cup | Slumped scenario animation |

Use an item to start begging. Use the same item again, press **X** by default, or run `/stopbegging` to stop.

## Testing

Give yourself either item using your framework or inventory command, then use it from the inventory. For ox_inventory, a common test command is:

```text
/giveitem [id] cardboard_sign 1
```

If initialization fails, the server console prints which framework or inventory could not be detected. Set `Config.Debug = true` to log successful donations and the active adapter pair.
