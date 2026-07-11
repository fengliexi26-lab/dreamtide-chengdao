# PVE Card v1 Battle Integration Report

Version: v0.4.3C-3

## Scope

BattleScene now prefers the PVE card v1 runtime path when a RunState is created from DaoMasterSelectScene.

Normal PVE flow:

- DaoMasterSelectScene loads `data/cards/pve/cards_pve_v1.json`.
- DaoMasterSelectScene loads the selected daomaster's v1 starter deck from `data/decks/pve_v1/`.
- RunState records `card_data_version = "pve_v1"`, `starter_deck_path`, and `uses_pve_card_v1 = true`.
- BattleScene builds independent v1 battle card instances through `PveCardV1Catalog`.
- BattleScene executes phase 1 effects through `PveCardEffectAdapter`.

Legacy fallback remains available when BattleScene is run directly or when RunState does not opt into v1 cards.

## Supported Phase 1 Effects

BattleScene executes these v1 effect types:

- `deal_damage`
- `gain_formation`
- `draw`
- `gain_daoxi`
- `gain_reflux`
- `reduce_reflux`
- `summon`

Unsupported or malformed v1 effects fail safely before paying cost or moving the card.

## Pile Rules

Failed plays:

- do not pay cost
- do not leave hand
- do not enter discard pile
- do not enter exhaust pile
- do not enter battlefield

Successful v1 daofa:

- leaves hand once
- resolves effects
- enters discard pile, or exhaust pile when it has `keywords: ["消耗"]`
- does not remain in CentralBattlefieldArea

Successful v1 chengdao:

- leaves hand once
- creates a summoned chengdao beast in CentralBattlefieldArea
- card body does not immediately enter discard pile or exhaust pile
- summoned beast stores `death_destination`, `is_special`, `side`, `chengdao_kind`, `dao_tags`, attack, and life
- formal death pile handling remains deferred to v0.4.4

## RunState Sync

BattleScene syncs these player resources back into RunState during PVE combat:

- `current_life`
- `current_daoxi`
- `formation`
- `reflux`
- `daoxing`

## Fallback Behavior

Direct BattleScene boot still uses legacy fallback:

- old `starter_zaiheng`
- cards from `cards_v0.json`
- fallback log: `未检测到 RunState，使用测试道主 fallback。`

## Tests

Added:

- `scripts/pve/TestPveCardV1BattleIntegration.gd`
- `scenes/pve/TestPveCardV1BattleIntegration.tscn`
- `tools/RunPveCardV1BattleIntegrationTests.ps1`

The integration test covers:

- all three unlocked daomasters booting with v1 decks
- explicit v1 load failure blocking battle instead of silently falling back
- BattleScene v1 boot from RunState
- v1 opening hand and 12-card deck total
- `deal_damage`
- `gain_formation`
- `draw` plus `消耗`
- `summon`
- failed play keeps card in hand and does not enter piles

## Not Changed

- `scripts/core/`
- v1 card values
- v1 starter deck contents
- legacy card data
- PVP / Match flow

## Known Limitations Before v0.4.4

- v1 summoned chengdao beasts can enter the battlefield, attack, and die through existing hooks, but their formal death destination and card-body return rules still need a dedicated v0.4.4 pass.
- `reduce_reflux` is supported by the adapter and BattleScene execution branch, but the current 39-card v1 catalog has no formal card using it.
- BattleScene still contains legacy PVP/Match code paths for compatibility, but the normal project flow remains PVE.
