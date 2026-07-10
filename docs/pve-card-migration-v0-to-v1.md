# 《梦潮：承道》旧卡池 v0 向 PVE 卡池 v1 迁移方案

## 一、迁移原则

- 不直接删除 `cards_v0.json`。
- `cards_v0.json` 继续作为旧 PVP / 原型兼容数据。
- 新正式 PVE 卡池未来放在：`data/cards/pve/cards_pve_v1.json`。
- 迁移不是简单复制。
- 每张旧卡必须重新判断名称、归属、功能和世界观定位。
- 只有实际可以结算的效果才能进入 v1 active 牌池。

## 二、迁移分类

每张旧卡必须标记为以下之一：

- `keep_as_reference`
- `rename_and_rebuild`
- `migrate_universal`
- `migrate_shared`
- `migrate_exclusive`
- `migrate_enemy_only`
- `migrate_relic`
- `migrate_equipment`
- `disable`
- `remove_from_pve`

## 三、逐张迁移表

| 旧 id | 旧名称 | 旧类型 | 当前实际效果 | 当前问题 | 建议迁移分类 | 建议新名称 | 建议 owner_scope | 建议 owner_ids | 建议 pool_tags | 保留世界观 | 进入 v1 | 需要新效果系统 | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `character_jinghui_youth` | 镜回少年 | character | 旧人物 / fallback 数据 | 非九道主职业牌 | `keep_as_reference` | 镜回少年 | - | - | 剧情、镜、潮梦 | 是 | 否 | 否 | 保留给剧情、事件或旧兼容 |
| `character_jiang_hengyue` | 姜蘅枂 | character | 旧人物数据 | 非九道主职业牌 | `keep_as_reference` | 姜蘅枂 | - | - | 姜氏、月衡 | 是 | 否 | 否 | 可作为剧情或未来装备适格引用 |
| `character_pei_zhaochuan` | 裴照川 | character | 旧人物数据 | 非九道主职业牌 | `keep_as_reference` | 裴照川 | - | - | 火、川、回潮 | 是 | 否 | 否 | 可作为剧情或事件角色 |
| `chengdao_linglu_order_beast` | 青玉灵鹿 | chengdao | 可召唤、可攻击 | 数值偏旧，缺 v1 归属 | `migrate_shared` | 青玉灵鹿 | shared | `zaiheng_jun`, `shoudeng_hou` | 木、守、秩序、守界 | 是 | 是 | 否 | 适合秩序 / 守界共享承道兽 |
| `chengdao_dream_crane` | 观梦灵鹤 | chengdao | 可召唤、可攻击 | 梦夜功能未实现 | `migrate_shared` | 观梦灵鹤 | shared | `zhiye_jun` | 梦、月、夜、凝梦 | 是 | 是 | 可能 | 适合梦 / 夜方向承道兽 |
| `chengdao_sunken_marsh_spirit` | 沉泽水灵 | chengdao | 可召唤、可攻击 | “积蓄阵势”未实现 | `rename_and_rebuild` | 沉泽水灵 | shared | `zaiheng_jun`, `shoudeng_hou` | 水、守、阵势 | 是 | 暂缓 | 是 | 可重做为守阵承道兽 |
| `chengdao_stele_stone_beast` | 碑前石兽 | chengdao | 可召唤、可攻击 | 缺少锚点机制 | `migrate_shared` | 碑前石兽 | shared | `zaiheng_jun`, `shoudeng_hou` | 山、守、秩序 | 是 | 是 | 否 | 适合守界 / 秩序共享 |
| `chengdao_echo_river_spirit` | 余响川灵 | chengdao | 可召唤、可攻击 | 回响机制未实现 | `rename_and_rebuild` | 余响川灵 | shared | 待定 | 川、音、回响 | 是 | 暂缓 | 是 | 等回响关键词实现后再迁移 |
| `chengdao_huichao_chaos_beast` | 回潮孽物 | chengdao | 可召唤、可攻击、加回潮 | 名称也作为当前敌人，身份混淆 | `migrate_enemy_only` | 回潮孽物 | enemy_only | - | 回潮、混沌、敌人 | 是 | 否 | 否 | 更适合作为敌人单位，不进玩家池 |
| `chengdao_warped_dream_beast` | 畸梦兽 | chengdao | 可召唤、可攻击、加回潮 | 可作为混沌梦兽，但需风险设计 | `migrate_shared` | 畸梦兽 | shared | `zhiye_jun`, `yinchao_wang` | 梦、祟、混沌、回潮 | 是 | 可选 | 可能 | 织夜可少量兼容，饮潮更适合 |
| `chengdao_rift_bone_beast` | 裂界骨兽 | chengdao | 可召唤、可攻击、加回潮 | 与归葬方向可兼容，但数值需重做 | `migrate_shared` | 裂界骨兽 | shared | `fuguan_seng`, `yinchao_wang` | 骨、墟、归葬、混沌 | 是 | 是 | 可能 | 可作为负棺僧共享承道兽 |
| `chengdao_unwaking_shadow` | 不醒祟影 | chengdao | 可召唤、可攻击、加回潮 | 更像敌人或诅咒召唤 | `migrate_enemy_only` | 不醒祟影 | enemy_only | - | 祟、月、梦魇 | 是 | 否 | 可能 | 优先 enemy_only |
| `chengdao_backflow_ancient_beast` | 倒灌古兽 | chengdao | 可召唤、可攻击、加回潮 | 体量像 rare / unique | `rename_and_rebuild` | 倒灌古兽 | shared | `fuguan_seng`, `yinchao_wang` | 潮、古、回潮、特殊承道兽 | 是 | 暂缓 | 可能 | 优先 rare / unique / special reward |
| `daofa_tide_cut` | 潮刃 | daofa | 小额伤害 | 不应永久充当所有职业基础攻击 | `rename_and_rebuild` | 潮刃 | shared | `yinchao_wang` 或潮系兼容 | 潮、攻击 | 是 | 暂缓 | 否 | 可留给潮 / 海 / 回潮共享池 |
| `daofa_moon_drop` | 月落 | daofa | 中额伤害，境界需求残留 | 境界需求不适合 v1 基础牌 | `keep_as_reference` | 月落 | shared | 未来月系角色 | 月、姜氏 | 是 | 否 | 否 | 可留作月衡 / 姜氏相关未来卡 |
| `daofa_fire_spark` | 烬星 | daofa | 微额伤害、加阵势、消耗 | 与前三位道主世界观不完全匹配 | `rename_and_rebuild` | 烬星 | shared | `fuguan_seng`, 未来火系 | 火、消耗、阵势 | 可保留 | 可选 | 否 | 当前支撑消耗测试，v1 可改名或停用 |
| `daofa_mountain_seal` | 山印 | daofa | 小额伤害、加阵势 | 名称可用但归属需明确 | `migrate_shared` | 山印 | shared | `zaiheng_jun`, `shoudeng_hou` | 山、守界、阵势 | 是 | 是 | 否 | 可重做为守界共享牌 |
| `daofa_dream_thread` | 梦缕 | daofa | 微额伤害、凝梦 | “梦脉触发”未实现 | `migrate_exclusive` | 梦缕 | exclusive | `zhiye_jun` | 梦、夜、凝梦 | 是 | 是 | 可能 | 可成为织夜低阶核心牌 |
| `daofa_backflow_burst` | 回潮逆涌 | daofa | 大额伤害，境界需求残留 | 回潮追加效果未实现，当前不适合前三位初始牌组 | `rename_and_rebuild` | 回潮逆涌 | shared | `yinchao_wang` | 潮、墟、回潮 | 是 | 暂缓 | 是 | 留给饮潮王或回潮共享池 |
| `formation_tide_gate` | 潮门法阵 | formation | 可入场 | 回合结束道行未实现 | `keep_as_reference` | 潮门法阵 | shared | `yinchao_wang` 或潮系 | 潮、域门、法阵 | 是 | 否 | 是 | 等法阵系统完成后再迁移 |
| `formation_silent_court` | 静庭法阵 | formation | 可入场 | 减伤未实现，旧命源需求残留 | `keep_as_reference` | 静庭法阵 | shared | `zhiye_jun`, `zaiheng_jun` | 月、静庭、防护 | 是 | 否 | 是 | 等持续减伤系统 |
| `formation_dragon_spine` | 龙脊阵图 | formation | 可入场但高阶条件过旧 | 高阶测试牌，不适合早期 PVE | `disable` | 龙脊阵图 | - | - | 山、龙脊、法阵 | 是 | 否 | 是 | 暂停迁入 |
| `formation_bone_mist` | 骨雾逆阵 | formation | 可入场 | 混沌侧兽关联未实现 | `keep_as_reference` | 骨雾逆阵 | shared | `fuguan_seng` | 骨、墟、法阵 | 是 | 否 | 是 | 等法阵系统 |
| `trap_hidden_tide` | 伏潮 | trap | 可入场 | 触发器未实现 | `keep_as_reference` | 伏潮 | shared | 潮系兼容 | 潮、伏法 | 是 | 否 | 是 | 等 trap trigger system |
| `trap_broken_law` | 断律伏法 | trap | 可入场 | 触发器未实现 | `keep_as_reference` | 断律伏法 | shared | `zaiheng_jun` | 月、律、反制 | 是 | 否 | 是 | 可保留概念，暂不进 active |
| `trap_murk_snare` | 浊梦缚 | trap | 可入场、凝梦保留 | 触发器未实现，不应因凝梦直接进正式牌组 | `rename_and_rebuild` | 浊梦缚 | exclusive | `zhiye_jun` | 梦、祟、凝梦、伏法 | 是 | 暂缓 | 是 | 需未来重新设计触发条件 |
| `dao_mark_wake` | 醒潮道痕 | dao_mark | 可入场 | 道痕应改为遗物，不进手牌 | `migrate_relic` | 醒潮道痕 | - | - | 潮、道痕 | 是 | 否 | 是 | 未来迁入 `data/relics/relics_v1.json` |
| `dao_mark_ember` | 余烬道痕 | dao_mark | 可入场 | 道痕应改为遗物，不进手牌 | `migrate_relic` | 余烬道痕 | - | - | 火、道痕 | 是 | 否 | 是 | 未来迁入遗物 |
| `domain_tide_realm` | 潮生域界 | domain | 可入场、加回潮 | 域界持续规则未完成 | `keep_as_reference` | 潮生域界 | shared | `yinchao_wang` | 潮、海、回潮、域界 | 是 | 否 | 是 | 等域界系统完成后迁移 |
| `artifact_moon_ruler` | 月衡 | life_artifact | 基础适格 / 命契判断 | 命器不应是普通手牌 | `migrate_equipment` | 月衡 | - | - | 月、衡、命器、姜氏 | 是 | 否 | 是 | 未来迁入 `data/equipment/weapons_v1.json` |

## 四、人物牌迁移

三张人物牌：

- 镜回少年
- 姜蘅枂
- 裴照川

建议：

- 不进入 `cards_pve_v1.json` 普通牌池。
- 保留在旧文件供剧情、旧 PVP 和历史兼容。
- 未来作为剧情角色、事件角色、特殊召唤或独立数据资源。
- 不作为九道主职业牌。

## 五、承道兽迁移

逐张判断：

- 青玉灵鹿、碑前石兽适合秩序或守界方向。
- 观梦灵鹤适合梦 / 夜方向。
- 裂界骨兽可与负棺僧、归葬、骨、墟方向兼容。
- 回潮孽物更适合作为敌人单位。
- 不醒祟影优先考虑 `enemy_only`。
- 倒灌古兽优先考虑 rare / unique / special reward。
- 沉泽水灵、余响川灵有不错设定，但需要等待阵势持续或回响系统。

不要因为现有卡存在，就强制全部迁入第一批正式卡池。

## 六、道法迁移

旧道法：

- 潮刃
- 月落
- 烬星
- 山印
- 梦缕
- 回潮逆涌

判断：

- 山印可以保留概念，但重做为守界共享牌或宰衡方向牌。
- 梦缕可以重做为织夜君专属或梦夜共享牌。
- 烬星若与三位开放道主世界观不匹配，可以停用或改名。
- 回潮逆涌可以留给饮潮王或回潮共享池，不必强行放入前三位初始牌组。
- 潮刃不应自动成为所有人的永久基础攻击牌。
- 月落可以留作月衡 / 姜氏相关未来卡，而不是当前通用牌。

## 七、法阵迁移

4 张旧法阵当前主要只有入场，没有正式持续效果。

建议：

- 潮门法阵：保留名称和设定，等待域界 / 潮门 / 法阵系统。
- 静庭法阵：保留为月 / 防护方向参考，等待减伤系统。
- 龙脊阵图：高阶测试牌，暂时停用。
- 骨雾逆阵：保留为骨 / 墟 / 负棺僧方向参考。

禁止把未实现法阵直接迁入正式初始牌组。

## 八、伏法迁移

3 张旧伏法当前没有触发器。

要求：

- 保留为未来设计参考。
- 等 trap trigger system 完成后再迁移。
- 不因为带凝梦关键词就进入织夜君正式牌组。
- 浊梦缚可以保留名称概念，但需要未来重新设计真正触发条件。

## 九、道痕迁移

- 醒潮道痕
- 余烬道痕

全部迁移规划为遗物，不进入 `cards_pve_v1.json` 普通手牌。

未来建议路径：

```text
data/relics/relics_v1.json
```

## 十、域界迁移

潮生域界：

- 保留世界观概念。
- 等域界系统完成后再迁移。
- 不进入第一批初始牌组。
- 未来可归属潮 / 海 / 回潮共享池或饮潮王。

## 十一、命器迁移

月衡：

- 从普通手牌移出。
- 未来迁移到命器装备数据。
- 可能与姜氏、秩序或衡界方向存在兼容。
- 不进入 `cards_pve_v1.json` 普通手牌。

未来建议路径：

```text
data/equipment/weapons_v1.json
```

## 十二、第一批正式 PVE 卡池范围建议

第一批 `cards_pve_v1.json` 不要追求迁移全部 30 张。

建议只包含：

- 4-6 张通用基础牌。
- 宰衡君 8-12 个专属 / 共享 card_id。
- 织夜君 8-12 个专属 / 共享 card_id。
- 负棺僧 8-12 个专属 / 共享 card_id。
- 6-10 个兼容承道兽。
- 总量先控制在约 35-50 个 card_id。

其中很多卡可被初始牌组和奖励池共享。

## 十三、前三位道主初始牌组迁移目标

本节只提出结构草案，本次不创建 JSON。

### 宰衡君

- 专属牌 6-7。
- 守界 / 秩序共享牌 3-4。
- 通用牌 1-2。
- 至少 2 个秩序承道兽 card_id。
- 能稳定触发衡界。

### 织夜君

- 专属牌 6-7。
- 梦 / 夜共享牌 3-4。
- 通用牌 1-2。
- 至少 3 个凝梦 card_id。
- 至少 1-2 个梦夜承道兽。
- 能稳定触发留宵。

### 负棺僧

- 专属牌 6-7。
- 归 / 葬共享牌 3-4。
- 通用牌 1-2。
- 至少 3 个承道兽 card_id。
- 至少 2 个消耗 card_id。
- 能稳定触发送归。

## 十四、迁移风险

- `BattleScene` 当前仍主要读取旧字段。
- 当前 `damage_tier` 不是正式数值伤害结构。
- 当前 `formation_gain` 和 `draw_count` 尚未统一到 `effects`。
- 当前通过 `effect_text` 判断凝梦和消耗存在误判风险。
- 当前法阵、伏法、域界持续系统未完成。
- 当前承道兽死亡归堆规则尚未正式重构。
- 当前奖励池过滤系统尚未实现。
- 当前升级系统尚未实现。

## 十五、推荐实施顺序

1. 完成两份设计文档。
2. 人工确认三位道主卡牌风格和命名。
3. 创建 `cards_pve_v1.json`。
4. 建立 v1 卡牌加载与兼容层。
5. 创建三套正式初始牌组。
6. 实现第一批基础 `effects`。
7. 联合测试三位道主。
8. 再制作奖励卡池。
9. 最后停用旧 `cards_v0.json` 的 PVE 主加载职责。

## 十六、本次边界

本迁移方案只创建文档。

本次不修改：

- `cards_v0.json`
- starter deck
- GDScript
- 场景
- `project.godot`
- battle-core

本次不新增：

- `cards_pve_v1.json`
- 新 card_id
- 新效果实现
