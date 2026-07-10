# PVE 卡池审计 v0.4.3B

## 1. 当前卡池文件位置

- 卡池数据：`res://data/cards/cards_v0.json`
- BattleScene 加载常量：`CARD_DATA_PATH := "res://data/cards/cards_v0.json"`
- 道主选择界面加载常量：`CARD_DATA_PATH := "res://data/cards/cards_v0.json"`
- PVE 初始牌组目录：`res://data/decks/pve/`

## 2. 当前非人物卡总数

当前 `cards_v0.json` 共 30 张卡，其中：

- 人物牌：3 张
- 非人物牌：27 张

PVE 初始牌组不得放入 `type = character` 的人物牌。

## 3. 按卡牌类型统计

| 类型 | 数量 | 说明 |
|---|---:|---|
| `chengdao` | 10 | 承道兽，均可召唤到中央战场 |
| `daofa` | 6 | 道法，当前可对敌人造成伤害 |
| `formation` | 4 | 法阵，当前可作为持续牌入场，但文本持续效果多未实现 |
| `trap` | 3 | 伏法，当前可作为持续牌入场，触发器尚未实现 |
| `dao_mark` | 2 | 道痕，当前可作为持续牌入场 |
| `domain` | 1 | 域界，当前可入场并增加回潮 |
| `life_artifact` | 1 | 命器，当前有基础适格判断 |

## 4. 按功能统计

| 功能标签 | 数量 | 卡牌 |
|---|---:|---|
| `attack` | 6 | `daofa_tide_cut`, `daofa_moon_drop`, `daofa_fire_spark`, `daofa_mountain_seal`, `daofa_dream_thread`, `daofa_backflow_burst` |
| `formation` | 2 | `daofa_fire_spark`, `daofa_mountain_seal` |
| `draw` | 0 | 当前正式卡池无可结算抽牌卡 |
| `retain` | 2 | `daofa_dream_thread`, `trap_murk_snare` |
| `exhaust` | 1 | `daofa_fire_spark` |
| `summon` | 10 | 全部 `chengdao` 承道兽 |
| `summon_support` | 0 | 有描述倾向，但无代码结算 |
| `reflux_gain` | 6 | 混沌承道兽 5 张、`domain_tide_realm` |
| `reflux_use` | 0 | 暂无读取或消耗回潮的可结算牌 |
| `persistent` | 11 | `formation` / `trap` / `dao_mark` / `domain` / `life_artifact` |
| `utility` | 1 | `artifact_moon_ruler` 的基础适格判断 |
| `unsupported` | 多张 | 见第 6 节 |

## 5. 可以正常结算的卡牌

以下为“数据中写了效果，代码也支持”的能力：

- 道法伤害：所有 `type = daofa` 且有 `damage_tier` 的牌可对敌人结算伤害。
- 阵势获得：`daofa_fire_spark`、`daofa_mountain_seal` 通过 `formation_gain` / 文本兼容获得阵势，可触发衡界。
- 凝梦 / 保留：`daofa_dream_thread`、`trap_murk_snare` 通过 `keywords: ["凝梦"]` 可被 `card_has_retain()` 识别。
- 消耗：`daofa_fire_spark` 通过 `keywords: ["消耗"]` 可被 `card_has_exhaust()` 识别，成功使用后进入消耗堆。
- 承道兽召唤：所有 `chengdao_kind = order_beast / chaos_beast` 的承道牌可进入中央战场。
- 承道兽攻击：已上场承道兽可攻击敌人。
- 混沌承道兽登场回潮：`side = chaos` 或 `chengdao_kind = chaos_beast` 的承道兽登场增加回潮。
- 域界入场：`domain_tide_realm` 可作为持续牌入场，并增加回潮。
- 法阵 / 伏法 / 道痕 / 命器入场：可进入对应持续区并显示在中央战场。
- 命器基础适格：`artifact_moon_ruler` 有基础适格 / 命契判断。

## 6. 仅有描述但尚无代码支持的卡牌

以下属于“数据中写了效果，但当前代码尚未支持完整效果”：

- `chengdao_sunken_marsh_spirit`：文本写“长期站场时积蓄阵势值”，目前不会自动获得阵势。
- `formation_tide_gate`：文本写“回合结束时获得 40 道行值”，目前没有回合结束法阵效果。
- `formation_silent_court`：文本写“下一次伤害降低一级”，目前没有伤害降低逻辑。
- `formation_dragon_spine`：高阶测试文本，目前没有针对秩序侧兽的专门效果。
- `formation_bone_mist`：文本可针对混沌侧兽，目前没有专门效果。
- `trap_hidden_tide`、`trap_broken_law`、`trap_murk_snare`：触发条件字段存在，但敌人事件触发器尚未实现。
- `dao_mark_wake`、`dao_mark_ember`：能入场，但“记录一次道脉触发”尚未产生后续收益。
- `domain_tide_realm`：能入场并增加回潮，但“场上潮脉牌获得额外道行”尚未实现。
- `daofa_dream_thread`：“标记一次梦脉触发”尚未实现，当前只结算伤害与凝梦。
- `daofa_backflow_burst`：“若回潮值较高追加效果”尚未实现。

## 7. 支持宰衡君的卡牌

宰衡君当前需要稳定触发“衡界”。当前真正可触发阵势获得的牌：

- `daofa_mountain_seal`：小额伤害，获得 1 点阵势。
- `daofa_fire_spark`：微额伤害，获得 1 点阵势，消耗。

辅助方向：

- 秩序承道兽：`chengdao_linglu_order_beast`, `chengdao_sunken_marsh_spirit`, `chengdao_stele_stone_beast`
- 持续防御占位：`formation_tide_gate`, `trap_broken_law`

当前宰衡君初始牌组：

- `chengdao_linglu_order_beast`
- `chengdao_sunken_marsh_spirit`
- `chengdao_stele_stone_beast`
- `daofa_mountain_seal` x3
- `daofa_fire_spark` x2
- `daofa_tide_cut`
- `formation_tide_gate` x2
- `trap_broken_law`

其中阵势方向牌 5 张，能够稳定触发“衡界”。

## 8. 支持织夜君的卡牌

织夜君当前需要“凝梦 / 保留”以触发“留宵”。当前可被 `card_has_retain()` 识别的牌：

- `daofa_dream_thread`：凝梦道法，造成微额伤害。
- `trap_murk_snare`：凝梦伏法，触发器尚未实现，但可作为保留牌。

辅助方向：

- 梦脉承道兽：`chengdao_dream_crane`, `chengdao_warped_dream_beast`
- 长线持续牌：`domain_tide_realm`, `formation_tide_gate`

当前织夜君初始牌组：

- `chengdao_dream_crane` x2
- `chengdao_warped_dream_beast`
- `daofa_dream_thread` x3
- `daofa_tide_cut`
- `daofa_mountain_seal`
- `formation_tide_gate`
- `trap_murk_snare` x2
- `domain_tide_realm`

其中凝梦 / 保留方向牌 5 张，能够稳定触发“留宵”。

## 9. 支持负棺僧的卡牌

负棺僧当前需要承道兽死亡触发“送归”，并需要消耗牌作为未来归葬方向基础。

可召唤承道兽：

- `chengdao_huichao_chaos_beast`
- `chengdao_rift_bone_beast`
- `chengdao_backflow_ancient_beast`
- `chengdao_unwaking_shadow`
- 以及其他全部承道兽

可被当前代码识别为消耗：

- `daofa_fire_spark`

当前负棺僧初始牌组：

- `chengdao_huichao_chaos_beast` x2
- `chengdao_rift_bone_beast`
- `chengdao_backflow_ancient_beast`
- `chengdao_unwaking_shadow`
- `daofa_tide_cut` x2
- `daofa_fire_spark` x2
- `formation_tide_gate`
- `trap_murk_snare`
- `dao_mark_ember`

其中承道兽 5 张、消耗牌 2 张，能体现“送归”的死亡收益方向。但当前还没有主动献祭、复活或消耗堆取回机制。

## 10. 当前缺失的职业机制

- 宰衡君：缺少更多低费、非消耗的阵势牌；缺少“守阵后反击 / 转化道行”的牌。
- 织夜君：凝梦牌只有 2 个 card_id，虽然可通过重复满足 starter deck，但卡池深度不足。
- 负棺僧：缺少主动让己方承道兽死亡的牌；缺少从消耗堆取回、利用死亡次数、利用墓地的牌。
- 全局：没有正式抽牌牌；没有主动弃牌牌；没有回潮读取 / 消耗牌；伏法触发器和法阵持续效果尚未实现。

## 11. 后续建议新增的最小卡牌清单

本节只作为后续建议，本次不加入 `cards_v0.json`。

### 宰衡君建议

| 建议 id | 卡名 | 类型 | 费用 | 简单效果 | 关键词 | 服务对象 | 当前代码支持 | 需要新增处理 |
|---|---|---|---:|---|---|---|---|---|
| `daofa_balance_guard` | 衡守 | `daofa` | 1 | 获得 2 阵势 | 无 | 宰衡君 | 部分支持 | 需要通用 `formation_gain` UI 文本 |
| `dao_mark_order_scale` | 秩序衡痕 | `dao_mark` | 1 | 入场后每回合首次获得阵势 +1 | 持续 | 宰衡君 | 不支持 | 需要道痕持续钩子 |
| `formation_stable_border` | 稳界小阵 | `formation` | 1 | 回合开始获得 1 阵势 | 持续 | 宰衡君 | 不支持 | 需要法阵回合开始效果 |

### 织夜君建议

| 建议 id | 卡名 | 类型 | 费用 | 简单效果 | 关键词 | 服务对象 | 当前代码支持 | 需要新增处理 |
|---|---|---|---:|---|---|---|---|---|
| `daofa_night_keep` | 留夜 | `daofa` | 1 | 造成微额伤害，凝梦 | 凝梦 | 织夜君 | 支持 | 无 |
| `daofa_dream_draw` | 织梦 | `daofa` | 1 | 抽 1，凝梦 | 凝梦 | 织夜君 | 不支持抽牌 | 需要抽牌效果 |
| `dao_mark_sleepless_thread` | 不寐丝痕 | `dao_mark` | 1 | 保留牌数量达 3 时获得阵势 | 持续 | 织夜君 | 不支持 | 需要道痕持续钩子 |

### 负棺僧建议

| 建议 id | 卡名 | 类型 | 费用 | 简单效果 | 关键词 | 服务对象 | 当前代码支持 | 需要新增处理 |
|---|---|---|---:|---|---|---|---|---|
| `daofa_funeral_order` | 送葬令 | `daofa` | 1 | 牺牲 1 只己方承道兽，造成伤害 | 消耗 | 负棺僧 | 不支持牺牲 | 需要献祭目标逻辑 |
| `daofa_bone_return` | 骨归 | `daofa` | 1 | 从消耗堆取回 1 张承道兽牌 | 消耗 | 负棺僧 | 不支持 | 需要消耗堆检索 |
| `chengdao_coffin_wisp` | 棺前微魂 | `chengdao` | 1 | 低命源承道兽，死亡时获得阵势 | 无 | 负棺僧 | 部分支持召唤 | 需要死亡收益钩子 |

## 12. 本次调整说明

本次未新增 card_id，也未重构卡牌系统。为了让 starter deck 能够真实触发三位道主的 v0.4.3A 被动，只对少数已有卡做了轻量数据标注：

- `daofa_mountain_seal`：增加 `formation_gain: 1` 和 `effect_text`。
- `daofa_fire_spark`：增加 `formation_gain: 1`、`keywords: ["消耗"]` 和 `effect_text`。
- `daofa_dream_thread`：增加 `keywords: ["凝梦"]` 和 `effect_text`。
- `trap_murk_snare`：增加 `keywords: ["凝梦"]` 和 `effect_text`。

这些标注均使用当前 BattleScene 已支持的 `formation_gain`、`card_has_retain()`、`card_has_exhaust()` 路径，不需要修改 battle-core。
