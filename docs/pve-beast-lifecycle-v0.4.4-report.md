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
