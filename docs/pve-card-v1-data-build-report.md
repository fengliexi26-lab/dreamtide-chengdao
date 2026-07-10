# 《梦潮：承道》PVE 卡池 v1 数据落地报告

版本：v0.4.3C-1
生成范围：

- `data/cards/pve/cards_pve_v1.json`
- `data/decks/pve_v1/starter_zaiheng_v1.json`
- `data/decks/pve_v1/starter_zhiye_v1.json`
- `data/decks/pve_v1/starter_fuguan_v1.json`
- `tools/ValidatePveCardV1.ps1`

本次只完成数据落地与验证，不接入 BattleScene，不修改旧运行流程。

## 1. 卡牌总数

`cards_pve_v1.json` 实际生成 39 张卡。

## 2. owner_scope 数量

| owner_scope | 数量 |
| --- | ---: |
| universal | 6 |
| shared | 9 |
| exclusive | 24 |
| 合计 | 39 |

## 3. 各道主 exclusive 数量

| 道主 | exclusive 数量 |
| --- | ---: |
| 宰衡君 `zaiheng_jun` | 8 |
| 织夜君 `zhiye_jun` | 8 |
| 负棺僧 `fuguan_seng` | 8 |

## 4. card_type 数量

| card_type | 数量 |
| --- | ---: |
| daofa | 28 |
| chengdao | 11 |

首批 active 卡池不包含 character、dao_mark、artifact、formation、trap、domain、enemy_only、token。

## 5. rarity 分布

| rarity | 数量 |
| --- | ---: |
| basic | 12 |
| common | 15 |
| uncommon | 8 |
| rare | 4 |

所有 `basic` 卡均设置为：

- `starter_allowed = true`
- `reward_allowed = false`

## 6. 三套 starter deck

### 6.1 宰衡君 starter_zaiheng_v1

| card_id | 数量 | 来源 |
| --- | ---: | --- |
| `zaiheng_jieyue` | 2 | exclusive |
| `zaiheng_chengliang` | 2 | exclusive |
| `zaiheng_dingce` | 1 | exclusive |
| `zaiheng_lingxu` | 1 | exclusive |
| `zaiheng_order_lawbeast` | 1 | exclusive |
| `shared_order_boundary_cut` | 1 | shared |
| `shared_guard_still_wall` | 1 | shared |
| `shared_order_jade_deer` | 1 | shared |
| `universal_breaking_style` | 1 | universal |
| `universal_body_guard` | 1 | universal |

统计：

- 总数：12
- 不同 card_id：10
- exclusive / shared / universal = 7 / 3 / 2
- 直接伤害实例：4
- 防御 / 生存实例：7
- 承道兽实例：2
- 能稳定触发衡界。

### 6.2 织夜君 starter_zhiye_v1

| card_id | 数量 | 来源 |
| --- | ---: | --- |
| `zhiye_liuxiao` | 1 | exclusive |
| `zhiye_changye` | 1 | exclusive |
| `zhiye_weixing` | 1 | exclusive |
| `zhiye_jueye_cut` | 1 | exclusive |
| `zhiye_night_crane` | 2 | exclusive |
| `zhiye_sleepless_shadow` | 1 | exclusive |
| `shared_night_lantern_thread` | 1 | shared |
| `shared_dream_mist_cut` | 1 | shared |
| `shared_night_crane` | 1 | shared |
| `universal_breaking_style` | 1 | universal |
| `universal_draw_breath` | 1 | universal |

统计：

- 总数：12
- 不同 card_id：11
- exclusive / shared / universal = 7 / 3 / 2
- 直接伤害实例：4
- 防御 / 生存实例：8
- 承道兽实例：3
- 凝梦实例：5
- 凝梦不同 card_id：5
- 能稳定触发留宵。

### 6.3 负棺僧 starter_fuguan_v1

| card_id | 数量 | 来源 |
| --- | ---: | --- |
| `fuguan_songlu` | 2 | exclusive |
| `fuguan_angui` | 1 | exclusive |
| `fuguan_guizang_spark` | 1 | exclusive |
| `fuguan_wuzang_order` | 1 | exclusive |
| `fuguan_coffin_wisp` | 1 | exclusive |
| `fuguan_burial_beast` | 1 | exclusive |
| `shared_return_bone_spark` | 1 | shared |
| `shared_burial_road_sign` | 1 | shared |
| `shared_return_rift_beast` | 1 | shared |
| `universal_breaking_style` | 1 | universal |
| `universal_body_guard` | 1 | universal |

统计：

- 总数：12
- 不同 card_id：11
- exclusive / shared / universal = 7 / 3 / 2
- 直接伤害实例：5
- 防御 / 生存实例：5
- 不同承道兽 card_id：3
- 消耗实例：4
- 不依赖主动献祭。

## 7. 0 费牌检查

| card_id | 效果 | 是否抽牌 | 是否消耗 | 结论 |
| --- | --- | --- | --- | --- |
| `universal_clear_mind` | 抽 1 | 是 | 是 | 通过 |
| `zaiheng_lingxu` | 获得 3 阵势 | 否 | 是 | 通过 |
| `zhiye_muye_breath` | 获得 1 道息 | 否 | 是 | 通过 |
| `fuguan_wuzang_order` | 抽 1 | 是 | 是 | 通过 |

未出现“0 费、无条件抽牌、不消耗”的无限循环风险。

## 8. 凝梦牌数量

正式卡池中具有 `凝梦` 关键词的 card_id 共 7 个：

- `shared_night_lantern_thread`
- `shared_dream_mist_cut`
- `zhiye_liuxiao`
- `zhiye_changye`
- `zhiye_canwang`
- `zhiye_weixing`
- `zhiye_muye_breath`

织夜君 v1 初始牌组中凝梦实例为 5 张，来自 5 个不同 card_id。

## 9. 消耗牌数量

正式卡池中具有 `消耗` 关键词的 card_id 共 9 个：

- `universal_clear_mind`
- `shared_return_bone_spark`
- `shared_burial_road_sign`
- `zaiheng_lingxu`
- `zhiye_muye_breath`
- `fuguan_guizang_spark`
- `fuguan_wuzang_order`
- `fuguan_yugu`
- `fuguan_guiyuan`

负棺僧 v1 初始牌组中消耗实例为 4 张。

## 10. 承道兽数量

正式卡池中 `card_type = chengdao` 的 card_id 共 11 个。

每张承道兽均包含：

- `summon_id`
- `attack`
- `life`
- `side`
- `dao_tags`
- `chengdao_kind`
- `death_destination`
- `is_special`

所有首批承道兽均为普通承道兽：

- `death_destination = discard`
- `is_special = false`

## 11. 旧卡迁移数量

| migration_type | 数量 |
| --- | ---: |
| rename_and_rebuild / concept rebuild | 21 |
| new | 18 |
| 合计 | 39 |

新版卡牌均为独立数据，没有直接引用旧 JSON Dictionary。

## 12. 与 roster 文档的差异

卡牌 id、卡名、owner_scope、owner_ids、pool_tags、rarity、cost、target_type、effects、keywords、side、starter_allowed、reward_allowed 均按 `docs/pve-card-roster-v1.md` 落地。

存在 1 处 starter deck 草案差异：

- `starter_zhiye_v1` 为满足本次提示词冻结的“织夜君正式初始牌组包含 4-5 张凝梦牌实例”要求，将 roster 草案中偏高的凝梦密度调整为 5 张凝梦实例。
- 调整后仍保持 exclusive / shared / universal = 7 / 3 / 2。
- 调整后仍使用 roster 中已定义的 card_id，没有新增或改名。

除上述 starter 实例选择差异外，无字段冲突。

## 13. 仍需要人工决定的问题

1. `universal_clear_mind` 与 `fuguan_wuzang_order` 都是 0 费抽 1 消耗，当前符合规则，但后续实测若过强可调整为 1 费。
2. 织夜君 starter 已压到 5 张凝梦实例，是否还需要进一步降低凝梦密度由后续实战决定。
3. 负棺僧第一版暂不做主动献祭，送归主要依赖承道兽自然死亡和消耗牌，是否满足职业手感需要实测。
4. `gain_reflux` 当前只在 `fuguan_guiyuan` 使用，回潮风险系统尚未展开。

## 14. 下一步兼容层需要支持的 effects

v1 兼容层需要从结构化 `effects` 读取并结算：

- `deal_damage`
- `gain_formation`
- `draw`
- `gain_daoxi`
- `gain_reflux`
- `reduce_reflux`
- `summon`

其中当前运行时已接近支持或已有旧逻辑：

- 伤害
- 阵势
- 抽牌
- 承道兽召唤
- 凝梦
- 消耗

需要特别确认的 v1 映射：

- `gain_daoxi`
- `gain_reflux`
- `reduce_reflux`
- `summon_data` / `effects.summon` 到战场承道兽实例的转换

## 15. 校验结果

已新增专用脚本：

```powershell
powershell -ExecutionPolicy Bypass -File tools\ValidatePveCardV1.ps1
```

本报告生成时，v1 数据校验结果为通过。
