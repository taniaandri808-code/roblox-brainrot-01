# BRAINROT EMPIRE

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=github&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/taniaandri808-code/roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=github&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/taniaandri808-code/roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=github&utm_campaign=roblox-brainrot-01)

A 3D Roblox brainrot game built for the make.fun `roblox-brainrot-01` bounty: collect absurd
pasta-born brainrot figures from the display field, seat them on your base, watch the money
tick up, defend them from the Brainrot Storm and the Thief, and rebirth at the altar for a
permanent 2x income multiplier. Built as a Rojo project; every part of the world, every UI
panel and every figure is created in code — no assets, no plugins.

## The pitch

You arrive at the Plaza with $100 and one of six neon-colored bases. On the plaza ring,
glowing pads spawn random brainrot figures on a weighted rarity roll — 45% Common down to
1% Secret. Walk up, hold E, buy it: the figure waddles home to a free slot on your base and
starts earning its income every second. Buy a Base Lock ($500) so the storm and the thief
can't touch your collection, and rebirth at the golden altar once you've earned enough to
reset for a permanent doubling.

## The roster (22 originals)

| Rarity | Characters | Income |
| --- | --- | --- |
| Common | Soggy Croissantini, Brick Frogini, Coughing Pigeotto | $1–3/s |
| Uncommon | Marinara Meatballino, Espresso Gatorino, Gelato Gargoyle | $6–11/s |
| Rare | Noodle Necked Nino, Mozzarella Mammoth, Vespa Vulture | $22–36/s |
| Epic | Cannoli Colossus, Risotto Rhino, Tarantella Toad | $65–115/s |
| Legendary | Cappuccino Kraken, Tiramisu T-Rex, Focaccia Phantom | $230–400/s |
| Mythic | Ballerino Bison, Gorgonzola Godzilla, Parmesan Palpatine | $740–1250/s |
| Secret | Heron Zestini, Omega Bruschetta, Nonna's Final Form, Turbulent Tortellini | $1800–4200/s |

A figure costs `25 x income/s`, so rarer rolls are pricier and juicier. Every figure can
roll a mutation — Golden x2, Diamond x4, Rainbow x8, Galaxy x15 — which repaints it neon
and multiplies its income.

## Systems

- **Display field** (`BrainrotService:spawnFigure`) — a new figure appears on a free pad
  every 6 seconds with weighted rarity (`BrainrotCatalog.rollRarity`) and a 30% mutation
  chance (`rollMutation`).
- **Bases** (`WorldBuilder.makeBase`) — six colored stalls in a ring, 4 slots each, a lock
  pad and a neon LOCK sign.
- **Income loop** (`BrainrotService:startIncomeLoop`) — one server tick per second, adds
  `sum(characters) x 2^Rebirths` to leaderstats and fires the `Money` remote.
- **Brainrot Storm** (`StormService`) — every 90 seconds a 10-second warning banner with a
  countdown, then a huge dark cloud sweeps the map flashing purple; unlocked bases lose a
  random character. Locked bases are safe.
- **Thief** (`ThiefService`) — every 60 seconds a dark figure spawns at the Storm Gate,
  walks to a random unlocked base, steals a brainrot and flees. Catch it with E for $250.
- **Rebirth** (`RebirthService`) — at 10000 x (Rebirths+1) lifetime money, hold E at the
  altar to reset everything for a permanent x2 (then x4, x8...) multiplier.
- **HUD** (`Game.client.luau`) — money panel, income per second, rebirth progress bar,
  flashing storm banner with countdown, scrolling event feed, and a fading intro title
  card, all away from Roblox's menu corner.

## Structure

```
src/server/  init.server.luau   entry point; wires the services
             WorldBuilder.luau  builds the map in code
             BrainrotCatalog.luau  the data: cast, rarities, mutations, rolls
             BrainrotService.luau  state, purchasing, income, locks
             StormService.luau     the 90-second storm threat
             RebirthService.luau   the rebirth altar
             ThiefService.luau     the roving thief
src/client/  Game.client.luau   HUD: money, feed, storm banner, rebirth bar, intro
```

Client and server talk only through the `ReplicatedStorage.Remotes` folder
(`Money`, `BaseInfo`, `StormWarning`, `EventFeed`, `BrainrotPurchased`); the client never
touches server state. Each module has one job.

## Building

```sh
rojo build default.project.json --output game.rbxl
```

Open `game.rbxl` in Roblox Studio, press Play, and start collecting.
