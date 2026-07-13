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

## v0.4.5.1 Hardening

v0.4.5.1 fixes and verifies the first fire/status integration beyond helper-only tests.

### Effect Value Rules

- `deal_damage` continues to read `value`.
- `add_pulse_buildup` continues to read `value`.
- `reduce_pulse_buildup` continues to read `value`.
- `apply_status` now reads `stacks`, not `value`.

Real BattleScene card-play tests verify that an `apply_status` effect with:

```json
{"type": "apply_status", "status_id": "zhuomai", "stacks": 2, "target": "enemy"}
```

actually applies 2 stacks of `zhuomai` / 灼脉.

### V1 Effect Target Profile

BattleScene now uses a unified V1 effect target profile:

- enemy effects require the enemy target button
- self-only effects use the central battlefield entry
- mixed enemy/self cards use the enemy target button
- self effects on a mixed card still resolve on the player

Enemy effects:

- `deal_damage target=enemy`
- `add_pulse_buildup target=enemy`
- `reduce_pulse_buildup target=enemy`
- `apply_status target=enemy`

Self effects:

- `gain_formation`
- `draw`
- `gain_daoxi`
- `gain_reflux`
- `reduce_reflux`
- `summon`
- `add_pulse_buildup target=self/player`
- `reduce_pulse_buildup target=self/player`
- `apply_status target=self/player`

Adapter validation accepts only:

- `enemy`
- `self`
- `player`

Invalid targets such as `ghost` are rejected before cost payment, card movement, pile movement, status mutation, or pulse mutation.

### Zhuomai Standardization

All direct and fire-break status application paths normalize `zhuomai` / 灼脉:

- `status_id = "zhuomai"`
- `display_name = "灼脉"`
- `max_stacks = 6`
- `duration = -1`
- `tick_timing = "owner_turn_end"`
- `visible = true`
- `tags` includes `pulse`, `fire`, `damage_over_time`

Repeated application clamps stacks to 6.

### Enemy Fire Intent

Enemy `fire_attack` now displays fire pulse wording, not burning wording:

- `火脉攻击 X｜火脉积蓄 Y｜非传导`
- `火脉攻击 X｜火脉积蓄 Y｜传导`

The conductive text is dynamic.

If `fire_attack` has an empty `pulse_id`, BattleScene normalizes it to `fire` during execution.

### Lethal Ordering

Enemy attack resolution now checks game-over immediately after attack damage and its attached fire pulse.

If the player dies from the attack:

- the enemy turn ends immediately
- enemy owner-turn-end burning does not tick
- no new player turn starts

Normal enemy owner-turn-end burning only resolves when the player survived the enemy action.

### Real Card-Play Integration Tests

`TestPveStatusFirePulse.gd` now verifies real BattleScene card-play paths using synthetic V1 cards in the actual hand and selected-card flow:

- pure enemy `add_pulse_buildup`
- pure self `reduce_pulse_buildup`
- `apply_status` with `stacks`
- mixed `deal_damage enemy` plus `gain_formation self`
- illegal `target=ghost`

### Lifecycle Tests

The test suite also verifies:

- an ordinary V1 beast killed by 灼脉 returns the same source card object to discard
- beast status and pulse runtime data clear on death
- `songgui` notification triggers once
- owner-turn-end beast status ticks follow stable slot order
- burning damage does not add fire pulse or trigger another pulse break
- player burning death blocks enemy action
- enemy burning death blocks the next player turn
- enemy direct lethal attack blocks enemy self-burning tick

### Event Queue / Restart Tests

Additional coverage verifies:

- max events per drain guard stops at 256
- reset clears pending events, history, and processing state
- restart clears pending/history/status/pulse/beast registry/battlefield
- restart preserves the 12-card battle deck total

## Known Limitations

- Only fire pulse is implemented.
- Only 灼脉 is implemented.
- Burning does not yet support resistance or immunity.
- Pulse/status UI is intentionally minimal.
- Event queue is not yet a full reactive resolver for all combat effects.
- Beast burning tests use existing BattleScene lifecycle behavior and do not add new death destinations.
