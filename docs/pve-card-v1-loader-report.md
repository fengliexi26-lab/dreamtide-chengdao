# 《梦潮：承道》PVE Card v1 Loader 报告

版本：v0.4.3C-2
分支：`feature/pve-card-v1-loader`

## 1. 新增脚本

本阶段新增：

- `scripts/pve/PveCardV1Catalog.gd`
- `scripts/pve/PveCardEffectAdapter.gd`
- `scripts/pve/TestPveCardV1Loader.gd`
- `scenes/pve/TestPveCardV1Loader.tscn`
- `tools/RunPveCardV1LoaderTests.ps1`

本阶段未接入 BattleScene，未修改 `project.godot`，未修改旧运行流程。

## 2. Loader 职责

`PveCardV1Catalog.gd` 负责：

- 加载 `res://data/cards/pve/cards_pve_v1.json`
- 建立按 `card_id` 查询的目录
- 返回安全深拷贝，避免调用方修改原始定义
- 按 `owner_scope` 查询卡牌
- 判断卡牌是否与指定道主兼容
- 加载三套 `data/decks/pve_v1/` 初始牌组
- 校验 deck 中 card_id 是否存在、是否兼容、是否正好 12 张
- 根据 card_id 列表构造独立战斗卡牌实例

该类是 `RefCounted`，未注册为 Autoload。

## 3. Effect Adapter 职责

`PveCardEffectAdapter.gd` 负责：

- 读取结构化 `effects`
- 按类型查询 effects
- 计算简单数值效果总和
- 判断关键词
- 规范化伤害描述
- 规范化承道兽召唤描述
- 报告不支持的 effect 类型
- 校验 phase 1 effects 基础格式

该类本阶段不执行任何战斗效果，不修改敌人、玩家、手牌、牌堆或战场。

## 4. v1 与 legacy 区分方式

v1 卡牌判断：

- 存在 `effects` 数组，或
- `implementation_phase = phase_1_base`

v1 卡牌规则：

- 伤害、阵势、抽牌、道息、回潮、召唤等数值只读取 `effects`
- 不从 `effect_text` / `description` 搜索数值
- `凝梦` 和 `消耗` 优先只从 `keywords` 读取

legacy 卡牌兼容：

- `formation_gain`
- `draw_count`
- `damage_tier`
- 旧承道兽字段：`attack` / `power` / `offense`、`life` / `life_source`
- legacy-only 文本关键词 fallback

文本 fallback 不应用于 v1 卡牌。

## 5. owner_scope 兼容规则

- `universal`：所有道主兼容
- `exclusive`：仅当当前 `daomaster_id` 存在于 `owner_ids` 时兼容
- `shared`：优先使用 `owner_ids` 判断
- `shared` 且 `owner_ids` 为空时：可以使用卡牌 `pool_tags` 与道主 `dao_tags` 的交集判断
- `token` / `enemy_only`：不进入当前玩家卡池

当前 `cards_pve_v1.json` 只包含：

- `universal`
- `shared`
- `exclusive`

## 6. deck 加载规则

支持加载：

- `res://data/decks/pve_v1/starter_zaiheng_v1.json`
- `res://data/decks/pve_v1/starter_zhiye_v1.json`
- `res://data/decks/pve_v1/starter_fuguan_v1.json`

加载时检查：

- deck JSON 可解析
- `cards` 是数组
- 正好 12 张
- 每个 card_id 存在于 v1 catalog
- 每张卡与指定道主兼容
- 不包含 token / enemy_only
- 任一错误会使 `ok = false`

加载结果包含：

- `ok`
- `errors`
- `deck_id`
- `daomaster_id`
- `card_ids`
- `cards`

## 7. 实例深拷贝规则

`build_battle_instances(card_ids)` 会：

- 对每张卡使用 catalog 定义的深拷贝
- 支持重复 card_id
- 给每张实例增加 `base_card_id`
- 给每张实例增加唯一 `instance_id`
- 给每张实例增加独立 `runtime_state`
- 不修改 catalog 中的原始定义

## 8. instance_id 生成方式

当前格式：

```text
{card_id}#{counter}
```

示例：

```text
zaiheng_jieyue#1
zaiheng_jieyue#2
```

`counter` 在当前 catalog 实例中递增，保证同一次测试 / 构建过程内唯一。

## 9. 支持的 effects

adapter 支持 phase 1 effect 类型：

- `deal_damage`
- `gain_formation`
- `draw`
- `gain_daoxi`
- `gain_reflux`
- `reduce_reflux`
- `summon`

支持关键词：

- `凝梦`
- `消耗`

## 10. 当前 cards_pve_v1.json 中各 effect 实际出现数量

| effect type | 数量 |
| --- | ---: |
| `deal_damage` | 11 |
| `gain_formation` | 13 |
| `draw` | 9 |
| `gain_daoxi` | 2 |
| `gain_reflux` | 1 |
| `reduce_reflux` | 0 |
| `summon` | 11 |

`reduce_reflux` 当前没有实际卡牌使用，但 adapter 已支持查询。测试覆盖其空结果。

## 11. 当前仍未执行的效果

本阶段只做读取、规范化、校验，不执行以下行为：

- 对敌人造成伤害
- 获得阵势
- 抽牌
- 获得道息
- 增减回潮
- 召唤承道兽
- 卡牌升级
- 奖励池随机
- BattleScene 切换到 v1 卡池

## 12. 下一阶段 BattleScene 接入方式

建议 v0.4.3C-3 进行：

1. 在 PVE run 创建时使用 `PveCardV1Catalog` 加载 v1 starter deck。
2. 用 `build_battle_instances()` 构造战斗牌堆实例。
3. 在 BattleScene 的出牌逻辑中通过 `PveCardEffectAdapter` 读取 effects。
4. 保持旧卡池路径 fallback，直到 v1 完整接入稳定。
5. 将 legacy 兼容集中到 adapter，不再散落在 UI 或 BattleScene 中。

## 13. 已知限制

- loader 不负责奖励池随机。
- loader 不负责 RunState 切换。
- adapter 不执行战斗效果。
- adapter 对 legacy `damage_tier` 只返回 `legacy_tier`，不换算具体伤害。
- 当前 `reduce_reflux` 没有真实卡牌实例。
- v1 JSON 数字在 Godot JSON 中会按 number 读取，adapter 已兼容整数值的浮点表示。

## 14. 测试结果

新增测试 runner：

```powershell
powershell -ExecutionPolicy Bypass -File tools\RunPveCardV1LoaderTests.ps1
```

通过输出：

```text
[TestPveCardV1Loader] catalog loaded: 39
[TestPveCardV1Loader] starter decks passed
[TestPveCardV1Loader] instance isolation passed
[TestPveCardV1Loader] effect adapter passed
[TestPveCardV1Loader] malformed data passed
[TestPveCardV1Loader] all tests passed
```

同时应继续通过：

```powershell
powershell -ExecutionPolicy Bypass -File tools\ValidatePveData.ps1
powershell -ExecutionPolicy Bypass -File tools\ValidatePveCardV1.ps1
powershell -ExecutionPolicy Bypass -File tools\RunBattleSceneBoot.ps1
```
