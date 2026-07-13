# PVE Status / Fire Pulse v0.4.5 Report

## Scope

v0.4.5 adds the first combat-status vertical slice for PVE battles:

- combat event queue runtime
- status runtime
- pulse buildup runtime
- fire pulse buildup
- fire threshold break
- burning status: `zhuomai` / 灼脉
- owner-turn-end burning damage
- status decay
- minimal BattleScene UI display

This version does not add multiple pulse types, compound reactions, resistance, transfer, active Daomaster skills, multi-enemy combat, maps, rewards, shops, events, bosses, or card upgrades.

## Runtime Files

- `scripts/pve/PveCombatEventQueue.gd`
- `scripts/pve/PveStatusRuntime.gd`
- `scripts/pve/PvePulseRuntime.gd`

The runtimes are initialized and reset by `BattleScene` when a PVE battle starts or restarts.

## Event Queue

The event queue supports:

- FIFO ordering
- unique event ids
- parent event depth tracking
- max depth guard: `32`
- per-event trigger dedupe
- reset safety

BattleScene currently uses the queue as a structured event history and guard layer. Effect resolution remains direct and deterministic.

## Fire Pulse

Supported pulse:

- `fire`

Threshold:

- 10 buildup

On threshold break:

- consume 10 fire buildup
- preserve overflow
- apply 灼脉
- first break applies 3 stacks
- later breaks on an already burning target add 2 stacks
- stacks clamp at 6

## Attack Pulse Scaling

For damage effects or enemy intents that include pulse metadata:

- conductive pulse applies full buildup
- if life damage is dealt, full buildup applies
- if defense is broken, full buildup applies
- otherwise buildup is halved with floor rounding

This allows armor/block/formation to partially suppress fire buildup without fully blocking it.

## Burning Status

Status id:

- `zhuomai`

Display:

- 灼脉

Timing:

- `owner_turn_end`

Behavior:

- deal damage equal to current stacks
- player damage is reduced by formation first
- enemy damage is reduced by block first
- beast damage directly reduces beast life
- after resolving damage, if the target survives, stacks decay by 1
- stacks reaching 0 remove the status
- burning damage does not create additional pulse buildup

## BattleScene Integration

Integrated paths:

- v1 `deal_damage` with optional fire pulse metadata
- v1 `add_pulse_buildup`
- v1 `reduce_pulse_buildup`
- v1 `apply_status`
- enemy second intent: fire attack
- player owner-turn-end burning tick
- enemy owner-turn-end burning tick
- player beast burning tick
- death cleanup for enemy, player, and beasts

The central battlefield remains the display for sustained player cards and beasts. Burning and fire buildup are shown minimally on:

- enemy panel
- player resource summary
- battlefield beast card blocks

## Enemy Intent

The current single enemy keeps a three-step loop:

1. attack 12
2. fire attack 8 with fire buildup 4, non-conductive
3. buff 6 block

## Lifecycle Interaction

When a beast dies from burning or other damage, the existing v0.4.4 beast lifecycle remains responsible for source-card release and destination handling.

BattleScene clears pulse and status runtime state for defeated beasts.

## Tests

Added:

- `scripts/pve/TestPveStatusFirePulse.gd`
- `scenes/pve/TestPveStatusFirePulse.tscn`
- `tools/RunPveStatusFirePulseTests.ps1`

Coverage includes:

- event queue FIFO
- event depth guard
- trigger dedupe
- status stacking and clamp
- fire threshold and overflow
- pulse reduction
- adapter validation for new structured effects
- existing v1 catalog compatibility
- BattleScene fire break to burning
- player/enemy owner-turn-end burning tick
- formation/block interaction
- attack pulse scaling
- enemy fire intent
- restart isolation

## Known Limitations

- Only fire pulse is implemented.
- Only 灼脉 is implemented.
- Burning does not yet support resistance or immunity.
- Pulse/status UI is intentionally minimal.
- Event queue is not yet a full reactive resolver for all combat effects.
- Beast burning tests use existing BattleScene lifecycle behavior and do not add new death destinations.
