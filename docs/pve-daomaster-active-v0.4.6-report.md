# PVE Daomaster Active Skills v0.4.6 Report

## Scope

v0.4.6 adds Daomaster power and the first three PVE Daomaster active skills for the unlocked Daomasters:

- 宰衡君 / `hengjie`: 封脉界约
- 织夜君 / `liuxiao`: 夜覆残世
- 负棺僧 / `songgui`: 负棺代受

Normal PVE V1 battles now use Daomaster active skills in the former Daomaster strike button slot. Legacy fallback, PVP, and Match paths keep the old free micro-damage Daomaster strike.

## Added Files

- `scripts/pve/PveDaomasterActiveRuntime.gd`
- `scripts/pve/TestPveDaomasterActives.gd`
- `scenes/pve/TestPveDaomasterActives.tscn`
- `tools/RunPveDaomasterActiveTests.ps1`
- `docs/pve-daomaster-active-v0.4.6-report.md`

## Modified Files

- `scripts/ui/BattleScene.gd`
- `scripts/pve/DaomasterPassiveRuntime.gd`
- `scripts/pve/PvePulseRuntime.gd`

No `scripts/core/`, `RunState.gd`, card JSON, starter deck JSON, map, Boss, reward, shop, or event content was changed.

## ActiveRuntime Interface

`PveDaomasterActiveRuntime` owns battle-local Daomaster active state:

- `setup(daomaster_id, passive_id, daomaster_name)`
- `reset_for_battle()`
- `begin_player_turn()`
- `try_gain_power(source_id)`
- `can_spend_for_active()`
- `spend_for_active()`
- `get_power()`
- `get_max_power()`
- `get_active_cost()`
- `get_skill_id()`
- `get_skill_name()`
- `get_skill_description()`
- `get_target_mode()`
- `is_active_used_this_turn()`
- `get_visible_state_lines()`

The runtime does not directly mutate UI, player life, formation, pulse containers, card piles, or battlefield units.

## Daomaster Power Rules

- Starts each battle at `1`.
- Maximum is `3`.
- Active skill cost is `3`.
- A player turn can gain Daomaster power at most once.
- Reaching the cap does not exceed `3`.
- A capped gain attempt does not consume the turn's gain opportunity.
- Successful active use is limited to once per player turn.
- Restart resets power to `1`, clears active usage, gain usage, target mode, and all temporary active states.

## Power Sources

### 宰衡君

When `衡界` actually triggers and grants the extra `+2` formation, BattleScene receives:

```text
_on_daomaster_power_source("hengjie")
```

Plain formation gain without `衡界` does not grant Daomaster power.

### 织夜君

When `留宵` grants at least `2` formation from retained 凝梦 cards, BattleScene receives:

```text
_on_daomaster_power_source("liuxiao")
```

Gaining only `1` formation from 留宵 does not grant Daomaster power.

### 负棺僧

Each valid own beast death calls:

```text
_on_daomaster_power_source("chengdao_death")
```

This is independent from `送归`'s once-per-battle reward. `送归` still grants `+1` daoxi and draws `2` only for the first valid beast death in a battle.

## Events

Daomaster power gain enqueues:

```text
daomaster_power_gained
```

payload:

- `daomaster_id`
- `source_id`
- `before`
- `after`

Active use enqueues:

```text
daomaster_active_used
```

payload:

- `daomaster_id`
- `skill_id`
- `cost`
- `power_before`
- `power_after`

负棺代受 marked beast death enqueues:

```text
fuguan_marked_beast_died
```

## 封脉界约

Current implementation:

1. Validate normal V1 PVE active timing.
2. Check Daomaster power and once-per-turn active usage.
3. Spend `3` Daomaster power.
4. Mark active used this turn.
5. Enable one-use fire pulse guard.
6. `gain_formation(6, "封脉界约")`.
7. This can trigger `衡界`.
8. If `衡界` is the first formation trigger of the turn, formation becomes `8` and Daomaster power can regain `1`.

### Fire Pulse Order

The fire pulse entry order is now:

```text
attack/defense pulse scaling
→ 封脉界约 reduction
→ 夜覆 deferred check
→ PulseRuntime add / deferred add
→ threshold break and 灼脉
```

`封脉界约` only affects `player:p1 / fire`, reduces one incoming positive buildup by up to `4`, then expires.

Examples:

- `5 -> 1`
- `2 -> 0`

If the buildup is fully blocked, `fengmai_hengyin_eligible = true` is recorded as a future 衡印 hook. No formal 衡印 resource is implemented in v0.4.6.

Unused guard expires at the next player turn start and does not refund power.

## 夜覆残世

Current version only supports player fire:

```text
player:p1 / fire
```

Use conditions:

- player fire buildup > 0
- no current 夜覆 deferred state
- not in the unlock-block turn
- Daomaster power >= 3
- active not used this turn

During 夜覆:

- player can keep gaining fire
- buildup can reach or exceed `10`
- no immediate threshold break happens
- no immediate 灼脉 is applied
- UI displays raw buildup as `火脉 X / 10（夜覆封存）`

At the next player turn start:

1. Reduce player fire by `3`, minimum `0`.
2. Clear deferred state.
3. Resolve thresholds.
4. Apply 灼脉 for each break.
5. Preserve overflow.
6. Lock 夜覆 for the current newly-started player turn.
7. Clear that lock on the following player turn start.

灼脉 created at turn start does not tick immediately. It still ticks at player owner-turn-end.

## PvePulseRuntime Deferred Support

`PvePulseRuntime` now provides:

- `add_buildup_deferred(target_id, pulse_id, amount)`
- `resolve_thresholds(target_id, pulse_id)`

`add_buildup_deferred` only adds raw buildup and never triggers breaks.

`resolve_thresholds` loops threshold consumption, returns `breaks`, and preserves overflow.

Existing `add_buildup()` behavior is preserved by internally using deferred add followed by threshold resolution.

## 负棺代受

Use conditions:

- player fire buildup > 0
- at least one own beast on board
- Daomaster power >= 3
- active not used this turn

Button behavior:

1. First click enters `fuguan_beast_target` mode.
2. No power is spent yet.
3. Current hand and attacker selections are cleared.
4. Own beasts are highlighted.
5. Clicking the active button again cancels the mode.

Target confirmation:

1. Revalidate target beast.
2. Transfer `min(5, player fire)` to the selected beast.
3. Spend `3` Daomaster power.
4. Mark active used this turn.
5. Reduce player fire.
6. Add fire to beast and immediately resolve threshold.
7. Mark the beast until next player turn start.

If the marked beast dies before the next player turn start:

- the mark clears
- `fuguan_mark_triggered = true`
- `yugu_eligible = true`
- `fuguan_marked_beast_died` is queued
- normal beast lifecycle and `送归` notification still run once

If the marked beast survives until next player turn start, the mark expires without refunding power or moving fire back to the player.

`yugu_eligible` is only a future 余骨 hook. No formal 余骨 resource is implemented in v0.4.6.

## Button Replacement

BattleScene continues to reuse `dao_strike_button`.

Normal PVE V1:

- button text shows active skill name
- button shows `道主势 x/3｜消耗 3`
- button tooltip shows description, current power, cost, unavailable reason, and temporary states
- old free micro-damage Dao strike cannot execute

Legacy fallback / PVP / Match:

- old Dao strike remains available
- legacy tests and debug direct BattleScene startup remain supported

## Card Resolution Lock

BattleScene now uses:

```text
is_resolving_v1_card
```

It is set while V1 card effects are resolving. Daomaster active skills refuse to execute if:

- `is_resolving_v1_card`
- `pve_event_queue.is_processing()`
- battle is over
- active was already used this turn
- power is insufficient

Failures do not spend Daomaster power or mutate pulse, formation, or marks.

## UI Display

Resource summary now includes:

- `道主势：x / 3`
- active skill name
- temporary lines:
  - `界约：下一次火脉 -4`
  - `夜覆：火脉失衡暂缓`
  - `夜覆：本回合无法再次封存`
  - `代受：已标记 <beast_id>`

The operation help dialog now states:

- Daomaster power at `3` enables active skills.
- normal V1 PVE active skills replace old Dao strike.
- 负棺代受 requires selecting a beast target.

## Restart Cleanup

Restart clears:

- Daomaster power back to `1`
- active used this turn
- power gained this turn
- 封脉界约 guard
- 夜覆 deferred state
- 夜覆 lock
- 负棺 marked beast
- future 衡印 / 余骨 eligibility flags
- active target mode

Existing event queue, status runtime, pulse runtime, beast registry, battlefield, and 12-card battle deck conservation remain handled by existing restart code.

## Tests

Added:

- `TestPveDaomasterActives`
- `RunPveDaomasterActiveTests.ps1`

Coverage includes:

- Daomaster power starts at 1, caps at 3, costs 3.
- Same-turn power gain limit.
- Capped gain does not consume gain opportunity.
- Restart resets active runtime.
- Skill metadata mapping for the three unlocked Daomasters.
- 封脉界约 fire reduction, once-only guard, and 衡印 eligibility hook.
- 夜覆 deferred buildup and threshold resolution.
- 负棺代受 target mode, transfer, beast break, marked death, and 余骨 eligibility hook.
- Normal V1 PVE button no longer performs old Dao strike damage.
- Card resolution lock rejects active use without spending power.

## Validation

Validated during implementation:

- `tools/ValidatePveData.ps1`
- `tools/ValidatePveCardV1.ps1`
- `tools/RunPveStatusFirePulseTests.ps1`
- `tools/RunPveDaomasterActiveTests.ps1`

Full regression is tracked in the final v0.4.6 validation pass.

## Known Limitations

- Only fire pulse is supported.
- 夜覆 automatically targets player fire; there is no pulse selection UI.
- 衡印 and 余骨 are eligibility hooks only, not formal resources.
- Active skills are not written to `RunState`.
- Only the three unlocked Daomasters have active skills.
- No icons or active skill equipment UI are implemented.
- Legacy Dao strike remains only for fallback/PVP compatibility.
