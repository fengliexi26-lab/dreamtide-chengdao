# PVE 承道兽生命周期 v0.4.4 报告

## 实现范围

- 新增 `PveBeastRuntime`，集中管理承道兽来源卡登记、占位容量、阶级默认值和死亡归堆。
- BattleScene 的 PVE v1 召唤流程改为：
  1. 扣费前校验目标、效果数据、承道兽占位容量。
  2. 成功后从手牌移除来源卡。
  3. 战场只放轻量承道兽单位。
  4. 来源卡保存在 `active_beast_card_instances`。
  5. 承道兽死亡时释放来源卡并进入对应牌堆。
- BoardView 增加战场承道兽列表读取、战场卡更新、行动点重置。
- 保留旧 `clear_attack_flags()` 作为兼容别名。

## 修改文件

- `scripts/ui/BattleScene.gd`
- `scripts/ui/BoardView.gd`
- `scripts/pve/TestPveCardV1BattleIntegration.gd`

## 新增文件

- `scripts/pve/PveBeastRuntime.gd`
- `scripts/pve/TestPveBeastLifecycle.gd`
- `scenes/pve/TestPveBeastLifecycle.tscn`
- `tools/RunPveBeastLifecycleTests.ps1`
- `docs/pve-beast-lifecycle-v0.4.4-report.md`

本阶段没有修改 `scripts/core/`、`project.godot`、`cards_pve_v1.json`、`cards_v0.json`、starter deck JSON、地图、敌人、Boss 或脉冲相关数据。

## Source Registry

`PveBeastRuntime.active_beast_card_instances` 保存：

```text
beast_instance_id -> original battle card instance
```

- 召唤成功后，来源卡从 hand 移除。
- 战场单位只保存 `source_card_instance_id`、`beast_instance_id` 等轻量字段。
- 来源卡本体保存在 registry 中，直到承道兽死亡。
- 死亡时释放同一个来源卡实例，并按阶级进入弃牌堆或消耗堆。
- 测试已覆盖“源卡在 hand / draw / discard / exhaust / registry 之间只有一个归属”。

## 战场轻量对象

战场承道兽单位只保存运行时战斗字段：

- `beast_instance_id`
- `source_card_instance_id`
- `name`
- `type`
- `attack_value`
- `current_life`
- `max_life`
- `side`
- `chengdao_kind`
- `dao_tags`
- `beast_rank`
- `beast_role`
- `board_cost`
- `death_destination`
- `is_token`
- `action_points`
- `action_points_remaining`
- `has_attacked`
- `has_acted`

战场单位不保存完整 `effects`、`runtime_state`、`summon_data` 或完整来源卡数据。

## 阶级与占位

- 普通承道兽 `ordinary`
  - 默认阶级。
  - 占位 `1`。
  - 死亡后来源卡进入弃牌堆。
- 进阶承道兽 `advanced`
  - 占位 `2`。
  - 死亡后来源卡进入消耗堆。
  - 同时最多存在 `1` 只。
- 衍生承道兽 `token`
  - 占位 `1`。
  - 不登记来源卡。
  - 死亡后消失，不进入弃牌堆或消耗堆。
- 唯一承道兽 `unique`
  - 已识别，但 v0.4.4 拒绝召唤，提示后续版本开放。

当前正式 39 张 PVE v1 卡没有真实 `advanced` 或 `token` 卡。所有现有 V1 承道兽默认按 `ordinary` 处理。`advanced` 与 `token` 仅通过合成测试数据验证运行时能力。

## 容量规则

- 当前 PVE 承道兽总占位上限为 `3`。
- 允许示例：
  - 普通 + 普通 + 普通
  - 进阶 + 普通
  - 进阶 + 衍生
- 拒绝示例：
  - 进阶 + 普通 + 普通
  - 进阶 + 进阶
  - 任何超过 3 点占位的组合

容量校验在扣费和移牌之前执行。失败时不扣道息、不移出手牌、不登记来源卡、不进入弃牌堆或消耗堆，保持事务安全。

## 行动点

- 承道兽默认 `action_points = 1`。
- 每次基础攻击消耗 1 点行动点。
- `action_points_remaining <= 0` 时同步视为 `has_attacked = true`。
- 玩家回合开始时重置所有己方承道兽行动点。
- 新召唤承道兽本回合可以行动。
- `has_acted` 与 `has_attacked` 兼容同步。

## Restart 清理

重新开始 PVE 战斗时：

- 重建 draw / discard / exhaust 三堆。
- 清空战场。
- 清空 selected card / attacker。
- 重建并 reset `PveBeastRuntime`。
- 来源卡 registry 不会跨战斗残留。

## Legacy 兼容

- PVE v1 召唤使用正式 source registry 生命周期。
- 旧 legacy fallback 路径仍保持可运行，主要服务 BattleScene 直接启动和旧数据调试。
- BoardView 的旧 `clear_attack_flags()` 保留为 `reset_beast_actions()` 的别名，避免旧调用断裂。

## 测试覆盖

新增：

- `scripts/pve/TestPveBeastLifecycle.gd`
- `scenes/pve/TestPveBeastLifecycle.tscn`
- `tools/RunPveBeastLifecycleTests.ps1`

覆盖内容：

- 普通承道兽来源卡死亡后进入弃牌堆。
- 进阶承道兽来源卡死亡后进入消耗堆。
- 衍生承道兽死亡后消失。
- 来源卡在手牌、三堆、来源登记表之间保持单一归属。
- 3 点承道兽占位限制生效。
- 承道兽每回合行动点限制与重置生效。

已运行并通过：

- `tools/ValidatePveData.ps1`
- `tools/ValidatePveCardV1.ps1`
- `tools/RunPveCardV1LoaderTests.ps1`
- `tools/RunPveCardV1BattleIntegrationTests.ps1`
- `tools/RunPveBeastLifecycleTests.ps1`
- `tools/RunBattleSceneBoot.ps1`
- `TestDaoMasterRunStateBoot.tscn`
- `TestPveTurnFlow.tscn`
- `TestDaomasterPassives.tscn`

Godot headless 退出时仍可能输出 RID/ObjectDB cleanup noise；测试退出码为 0，且稳定测试标记均通过。

## 未实现内容

- 高级承道兽专属技能。
- 主动献祭。
- 复活和从消耗堆取回。
- 敌人正式攻击承道兽。
- 多敌人、多波次和 Boss 机制。
- 脉冲、燃烧、道主技能。
- guardian 拦截。
- 跨波次保留。

## v0.4.4.1 稳定性补充

本次补充修复了召唤事务边界，并扩展自动化测试覆盖。

### 召唤 preflight 与异常回滚

- v1 手牌在扣费前通过 `_get_selected_hand_entry()` 使用 `is_same()` 定位真实手牌对象和索引。
- 如果选中牌已不在手牌中，直接失败，不扣费、不执行效果、不移动牌、不登记 registry。
- 承道兽召唤在扣费前构建 summon plan。
- summon plan 包含：
  - `source_card`
  - `source_hand_index`
  - `summon_spec`
  - `metadata`
  - `beast_instance_id`
  - `slot_index`
  - `board_index`
- 当前阶段拒绝单牌多次 summon effect，返回“v0.4.4 暂不支持单牌多次召唤”。
- source registry 在执行 effects 前完成预登记；登记失败时恢复手牌和扣费前道息。
- summon commit 阶段只使用 plan 中预先生成的 metadata 和 beast_instance_id，不再重新生成。

### Source registry 预检

`PveBeastRuntime` 新增 `validate_source_registration()`，并且 `register_source_card()` 自身也重复执行同一套检查。

检查内容：

- `beast_instance_id` 非空。
- 同名 `beast_instance_id` 未登记。
- `source_card` 非空。
- `source_card.instance_id` 非空。
- 同一 `source_card.instance_id` 未被其他承道兽登记。

### Advanced 检查顺序

`validate_summon()` 已调整为：

1. rank 与 source 校验。
2. 高阶承道兽数量校验。
3. 总占位容量校验。

因此第二只 `advanced` 会优先返回“场上同时最多存在 1 只高阶承道兽”，不会被容量不足覆盖。

### 死亡一致性

`_resolve_pve_beast_defeat()` 现在校验：

```text
beast_data.source_card_instance_id == source_card.instance_id
```

- 找不到 registry 来源卡时 `push_error`，并记录 beast_instance_id、expected source、rank。
- source id 不一致时 `push_error`，并记录 beast_instance_id、expected source、actual source、rank。
- 不再伪造归堆卡。
- 不把战场 beast unit 当作来源卡归堆。
- 一致性失败时不触发承道兽死亡通知。

### 新增测试覆盖

`TestPveBeastLifecycle.gd` 增加：

- 通过 `is_same()` 验证 ordinary 死亡归堆返回原始 source card 对象。
- 验证战场 beast 是轻量对象，不包含 `effects/runtime_state/summon_data/implementation_phase`。
- 验证 registry 保存的是原手牌对象，战场 beast 不是源卡对象。
- 三只 ordinary 成功，第四只 ordinary 事务失败且不扣道息、不移牌、不新增 registry。
- 第二只 advanced 返回 advanced 专属限制原因。
- token 强制 `board_cost = 1`，满容量时 token 失败且不改 registry。
- 重复 source instance 和重复 beast_instance_id 登记失败，registry 数量保持不变。
- duplicate source preflight 失败时不扣道息、不移手牌、不执行效果、不生成战场兽。
- 真实 12 张 starter deck 在战斗开始、召唤、死亡、洗弃牌堆后总数保持 12。
- 同一槽位死亡处理不会重复通知、重复归堆或重复释放 registry。
- restart 后 registry 清空、旧战场兽清空、新牌组总数为 12、新卡实例与旧 source card 对象隔离。

### 测试结果

以下测试在 v0.4.4.1 后通过，退出码均为 0：

- `tools/ValidatePveData.ps1`
- `tools/ValidatePveCardV1.ps1`
- `tools/RunPveCardV1LoaderTests.ps1`
- `tools/RunPveCardV1BattleIntegrationTests.ps1`
- `tools/RunPveBeastLifecycleTests.ps1`
- `tools/RunBattleSceneBoot.ps1`
- `TestDaoMasterRunStateBoot.tscn`
- `TestPveTurnFlow.tscn`
- `TestDaomasterPassives.tscn`

Godot headless 的 RID/ObjectDB cleanup noise 仍视为非阻塞退出噪声。
