# w2f-begging

Passive homeless begging roleplay for **Qbox** — use a cardboard sign or cup, play idle animations, and receive random NPC donations.

**Deps:** `ox_lib`, `ox_inventory`, `qbx_core`

---

## Install

1. Place the resource in `[w2f]` and `ensure [w2f]` after `[ox]` and `qbx_core`.
2. Paste `install/ox_inventory-items.lua` into `ox_inventory/data/items.lua`.
3. Copy icons from `install/images/` to `ox_inventory/web/images/`:
   - `cardboard_sign.png`
   - `begging_cup.png`

```text
restart ox_inventory
ensure w2f-begging
```

**Test:** `/giveitem [id] cardboard_sign 1` then use the item from inventory.

---

## Usage

| Item | Mode | Behaviour |
|------|------|-----------|
| `cardboard_sign` | Sign | Upper-body anim + attached sign prop |
| `begging_cup` | Cup | Slumped scenario anim |

Use the item again, press **X** (default), or run `/stopbegging` to stop.

---

## Config

Edit `config.lua` for scan radius, donation amounts, anti-farm caps, NPC pick rates, and notify text.
