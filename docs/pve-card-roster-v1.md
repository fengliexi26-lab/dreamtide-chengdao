# 《梦潮：承道》首批正式 PVE 卡池清单 v1

版本：v0.4.3C-roster
用途：为 PVE 肉鸽卡牌方向定义第一批正式可实现卡池、三套初始牌组、奖励池草案与旧卡迁移关系。
范围：本文件只定义设计清单，不代表已经写入 `cards_v1.json` 或运行时代码。

## 1. 总览

首批正式 PVE active 卡池固定为 39 个 `card_id`：

| 分类 | 数量 |
| --- | ---: |
| 通用牌 universal | 6 |
| 共享牌 shared | 9 |
| 宰衡君专属 zaiheng | 8 |
| 织夜君专属 zhiye | 8 |
| 负棺僧专属 fuguan | 8 |
| 合计 | 39 |

首批 active 卡牌只使用两种 `card_type`：

| card_type | 数量 | 说明 |
| --- | ---: | --- |
| daofa | 28 | 即时道法牌，结算后进入弃牌堆或消耗堆 |
| chengdao | 11 | 召唤承道兽，生成战场单位 |

首批 active 卡池不包含：

- `formation`
- `trap`
- `domain`
- `dao_mark`
- `artifact`
- `character`
- `enemy_only`

这些类型可以保留为未来系统概念，但不进入首批 active PVE 卡池。

## 2. 命名与职业语言

### 2.1 通用牌

通用牌命名应古朴、实用、克制，不做宏大叙事。它们是任何道主都能理解和使用的基础道法或基础承道兽。

推荐词感：破、护、引、定、行、游、石、灵。

### 2.2 宰衡君

宰衡君语言围绕秩序、衡量、边界、律令、稳定循环。

推荐字根：衡、序、册、界、约、令、裁、定、称量。
关联被动：`衡界`，本回合第一次获得阵势时额外获得阵势。

### 2.3 织夜君

织夜君语言应有王庭、长夜、残世、未醒的冷感，不走软梦妖媚方向。

推荐字根：夜、宵、幕、缝、残世、王庭、未醒、留存、长夜。
关联被动：`留宵`，回合结束时每保留一张凝梦牌获得阵势，上限 3。

### 2.4 负棺僧

负棺僧语言应肃穆、送别、归葬、安魂，不做传统死灵法师。

推荐字根：归、葬、棺、送、安、路、余骨、无葬、归寂。
关联被动：`送归`，围绕承道兽死亡、消耗和归葬方向发展。

## 3. 数值基线

当前 PVE 基线：

- 基础道息：3
- 每回合抽牌：5
- 玩家生命约：70
- 敌人生命约：60-100
- 承道兽上限：3

首批数值建议：

| 类型 | 建议数值 |
| --- | --- |
| 0 费牌 | 低效果、消耗、或偏功能 |
| 1 费直接伤害 | 5-8 |
| 1 费阵势 | 5-7 |
| 1 费抽牌 | 抽 1；条件抽 2 放到后续阶段 |
| 2 费直接伤害 | 11-16 |
| 2 费阵势 | 10-14 |
| 1 费承道兽 | 攻 2-5，命源 5-12 |
| 2 费承道兽 | 攻 5-8，命源 9-17 |

## 4. 稀有度分布

| rarity | 数量 | 说明 |
| --- | ---: | --- |
| basic | 12 | starter 常用，通常不进奖励池 |
| common | 15 | 主要奖励池骨架 |
| uncommon | 8 | 职业方向强化 |
| rare | 4 | 构筑转折或强节奏牌 |
| unique | 0 | 首批暂不使用 |
| 合计 | 39 | 符合首批目标 |

## 5. 首批 39 张正式 PVE 卡牌

字段说明：

- `effects` 使用 phase 1 可实现基础效果：`deal_damage`、`gain_formation`、`draw`、`gain_daoxi`、`gain_reflux`、`reduce_reflux`、`summon`。
- `keywords` 只使用 `凝梦`、`消耗`。
- 所有 39 张牌的 `implementation_phase` 都是 `phase_1_base`。

### 5.1 通用牌 universal，6 张

| # | 建议 id | 卡名 | card_type | subtype | owner_scope | owner_ids | pool_tags | rarity | cost | target_type | effects | keywords | side | starter_allowed | reward_allowed | implementation_phase | 效果文本 | 设计职责 | 服务的构筑方向 | 升级方向 | 世界观说明 | 是否由旧卡迁移 | 对应旧卡 id | 命名备注 |
| ---: | --- | --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `universal_breaking_style` | 破界式 | daofa | attack | universal | [] | [attack] | basic | 1 | enemy | `deal_damage:7` | [] | neutral | true | false | phase_1_base | 造成 7 点伤害。 | 基础攻击 | 全职业基础输出 | 伤害 +2 | 行旅者常用破界术 | 是 | `basic_strike` / `潮刃` 概念拆分 | 不再让潮刃承担通用基础攻击 |
| 2 | `universal_body_guard` | 护身诀 | daofa | defense | universal | [] | [formation] | basic | 1 | self | `gain_formation:6` | [] | neutral | true | false | phase_1_base | 获得 6 点阵势。 | 基础防御 | 全职业生存 | 阵势 +2 | 入梦前的护身诀 | 是 | `basic_guard` | 名称朴素实用 |
| 3 | `universal_draw_breath` | 引息 | daofa | utility | universal | [] | [draw] | common | 1 | self | `draw:1` | [] | neutral | true | true | phase_1_base | 抽 1 张牌。 | 基础过牌 | 所有循环构筑 | 费用 -1 或抽牌后获得 1 道息 | 调息引梦，续接手牌 | 是 | `breath_draw` | 保持通用感 |
| 4 | `universal_clear_mind` | 定神 | daofa | utility | universal | [] | [draw, exhaust] | common | 0 | self | `draw:1` | [消耗] | neutral | true | true | phase_1_base | 抽 1 张牌。消耗。 | 低费过滤 | 短循环、压缩牌堆 | 可不消耗，或额外获得 1 阵势 | 稳住神识，换取一息清明 | 是 | `minor_focus` | 不做宏大命名 |
| 5 | `universal_roaming_spirit_hound` | 游灵犬 | chengdao | beast | universal | [] | [summon] | basic | 1 | self | `summon:{attack:3,life:8}` | [] | neutral | true | false | phase_1_base | 召唤 1 只攻 3 / 命源 8 的游灵犬。 | 基础承道兽 | 站场、承伤、攻击 | 攻 +1 / 命源 +2 | 跟随行旅的弱小灵兽 | 是 | `minor_spirit_beast` | 保持低阶感 |
| 6 | `universal_wayfarer_stone` | 行路石灵 | chengdao | beast | universal | [] | [summon] | uncommon | 2 | self | `summon:{attack:5,life:14}` | [] | neutral | true | true | phase_1_base | 召唤 1 只攻 5 / 命源 14 的行路石灵。 | 中型承道兽 | 通用站场 | 攻 +1 / 命源 +3 | 古道边石灵，被梦潮唤醒 | 是 | `stone_spirit` | 比游灵犬更稳 |

### 5.2 共享牌：守界 / 秩序，3 张

| # | 建议 id | 卡名 | card_type | subtype | owner_scope | owner_ids | pool_tags | rarity | cost | target_type | effects | keywords | side | starter_allowed | reward_allowed | implementation_phase | 效果文本 | 设计职责 | 服务的构筑方向 | 升级方向 | 世界观说明 | 是否由旧卡迁移 | 对应旧卡 id | 命名备注 |
| ---: | --- | --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 7 | `shared_order_boundary_cut` | 界裁 | daofa | attack_defense | shared | [zaiheng_jun] | [attack, formation, order] | common | 1 | enemy | `deal_damage:5; gain_formation:3` | [] | order | true | true | phase_1_base | 造成 5 点伤害，获得 3 点阵势。 | 攻防混合 | 宰衡君稳定触发衡界 | 伤害 +2 或阵势 +2 | 以界为尺，裁去失衡 | 是 | `boundary_cut` | 符合宰衡语言 |
| 8 | `shared_guard_still_wall` | 静垣诀 | daofa | defense | shared | [zaiheng_jun] | [formation, guard, order] | common | 2 | self | `gain_formation:12` | [] | order | true | true | phase_1_base | 获得 12 点阵势。 | 强防御 | 守界、稳定循环 | 阵势 +3 | 静垣立界，止潮于外 | 是 | `mountain_seal` / `山印` 概念 | 山印转为守界材料 |
| 9 | `shared_order_jade_deer` | 青玉守鹿 | chengdao | order_beast | shared | [zaiheng_jun] | [summon, order] | common | 1 | self | `summon:{attack:3,life:11}` | [] | order | true | true | phase_1_base | 召唤 1 只攻 3 / 命源 11 的青玉守鹿。 | 防守承道兽 | 守界、承伤 | 命源 +3 | 青玉灵鹿的守界分支 | 是 | `chengdao_linglu_order_beast` | 旧青玉灵鹿正式化 |

### 5.3 共享牌：梦 / 夜，3 张

| # | 建议 id | 卡名 | card_type | subtype | owner_scope | owner_ids | pool_tags | rarity | cost | target_type | effects | keywords | side | starter_allowed | reward_allowed | implementation_phase | 效果文本 | 设计职责 | 服务的构筑方向 | 升级方向 | 世界观说明 | 是否由旧卡迁移 | 对应旧卡 id | 命名备注 |
| ---: | --- | --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 10 | `shared_night_lantern_thread` | 夜灯丝 | daofa | utility | shared | [zhiye_jun] | [draw, retain, night] | common | 1 | self | `draw:1` | [凝梦] | neutral | true | true | phase_1_base | 抽 1 张牌。凝梦。 | 凝梦基础件 | 织夜君留宵触发 | 抽牌后获得 2 阵势 | 长夜里不灭的一缕灯丝 | 是 | `dream_thread` / `梦缕` 概念 | 梦缕改造成织夜语言 |
| 11 | `shared_dream_mist_cut` | 梦雾裁 | daofa | attack_utility | shared | [zhiye_jun] | [attack, draw, retain] | uncommon | 1 | enemy | `deal_damage:5; draw:1` | [凝梦] | neutral | true | true | phase_1_base | 造成 5 点伤害，抽 1 张牌。凝梦。 | 凝梦攻击 | 织夜长线输出 | 伤害 +2 | 在梦雾里裁开敌影 | 是 | `dream_cut` | 不使用柔媚梦妖语感 |
| 12 | `shared_night_crane` | 宵庭灵鹤 | chengdao | order_beast | shared | [zhiye_jun] | [summon, night] | uncommon | 1 | self | `summon:{attack:2,life:9}` | [] | order | true | true | phase_1_base | 召唤 1 只攻 2 / 命源 9 的宵庭灵鹤。 | 低攻保护兽 | 织夜防守、站场 | 命源 +4 | 王庭夜色中的灵鹤 | 是 | `chengdao_dream_crane` | 观梦灵鹤改名 |

### 5.4 共享牌：归 / 葬，3 张

| # | 建议 id | 卡名 | card_type | subtype | owner_scope | owner_ids | pool_tags | rarity | cost | target_type | effects | keywords | side | starter_allowed | reward_allowed | implementation_phase | 效果文本 | 设计职责 | 服务的构筑方向 | 升级方向 | 世界观说明 | 是否由旧卡迁移 | 对应旧卡 id | 命名备注 |
| ---: | --- | --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 13 | `shared_return_bone_spark` | 归骨火 | daofa | attack | shared | [fuguan_seng] | [attack, exhaust, burial] | common | 1 | enemy | `deal_damage:6` | [消耗] | neutral | true | true | phase_1_base | 造成 6 点伤害。消耗。 | 消耗攻击 | 负棺僧送归素材 | 伤害 +3 | 骨灰中短暂亮起的归火 | 是 | `fire_spark` / `烬星` 部分概念 | 烬星本体不迁入首批 |
| 14 | `shared_burial_road_sign` | 葬路记 | daofa | defense_utility | shared | [fuguan_seng] | [formation, draw, exhaust] | uncommon | 1 | self | `gain_formation:5; draw:1` | [消耗] | neutral | true | true | phase_1_base | 获得 5 点阵势，抽 1 张牌。消耗。 | 消耗防御过牌 | 负棺僧过渡生存 | 阵势 +2 | 记下亡者归路 | 否 | - | 新牌，服务归葬 |
| 15 | `shared_return_rift_beast` | 归裂骨兽 | chengdao | chaos_beast | shared | [fuguan_seng] | [summon, burial] | common | 2 | self | `summon:{attack:7,life:11}` | [] | chaos | true | true | phase_1_base | 召唤 1 只攻 7 / 命源 11 的归裂骨兽。 | 中型承道兽 | 负棺僧承道兽密度 | 命源 +3 | 裂界骨兽被葬路收束后的形态 | 是 | `chengdao_rift_bone_beast` | 避免纯怪物化 |

### 5.5 宰衡君专属，8 张

| # | 建议 id | 卡名 | card_type | subtype | owner_scope | owner_ids | pool_tags | rarity | cost | target_type | effects | keywords | side | starter_allowed | reward_allowed | implementation_phase | 效果文本 | 设计职责 | 服务的构筑方向 | 升级方向 | 世界观说明 | 是否由旧卡迁移 | 对应旧卡 id | 命名备注 |
| ---: | --- | --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 16 | `zaiheng_jieyue` | 界约 | daofa | defense | exclusive | [zaiheng_jun] | [formation, order] | basic | 1 | self | `gain_formation:6` | [] | order | true | false | phase_1_base | 获得 6 点阵势。 | 基础衡界触发 | 宰衡防御核心 | 阵势 +2 | 与边界立约 | 否 | - | 宰衡基础语言牌 |
| 17 | `zaiheng_chengliang` | 称量 | daofa | attack_defense | exclusive | [zaiheng_jun] | [attack, formation] | basic | 1 | enemy | `deal_damage:5; gain_formation:3` | [] | order | true | false | phase_1_base | 造成 5 点伤害，获得 3 点阵势。 | 攻防基础 | 攻守稳定循环 | 伤害 +2 | 先称其失衡，再落裁量 | 否 | - | 名称稳定 |
| 18 | `zaiheng_dingce` | 定册 | daofa | utility | exclusive | [zaiheng_jun] | [draw, formation] | common | 1 | self | `draw:1; gain_formation:3` | [] | order | true | true | phase_1_base | 抽 1 张牌，获得 3 点阵势。 | 过牌兼触发 | 衡界小循环 | 阵势 +2 | 册页一定，界线自明 | 否 | - | 稳定书册意象 |
| 19 | `zaiheng_lingxu` | 令序 | daofa | defense | exclusive | [zaiheng_jun] | [formation, exhaust] | common | 0 | self | `gain_formation:3` | [消耗] | order | true | true | phase_1_base | 获得 3 点阵势。消耗。 | 0 费启动 | 衡界首触发 | 阵势 +2 | 令下则序立 | 否 | - | 低费律令 |
| 20 | `zaiheng_caijie` | 裁界 | daofa | attack_defense | exclusive | [zaiheng_jun] | [attack, formation] | uncommon | 2 | enemy | `deal_damage:12; gain_formation:4` | [] | order | false | true | phase_1_base | 造成 12 点伤害，获得 4 点阵势。 | 中费攻防 | 稳定收尾 | 伤害 +3 | 裁开混乱边界 | 是 | `boundary_cut` 强化方向 | 界裁的职业版 |
| 21 | `zaiheng_wushang_ce` | 无伤册 | daofa | defense_utility | exclusive | [zaiheng_jun] | [formation, draw] | rare | 2 | self | `gain_formation:10; draw:1` | [] | order | false | true | phase_1_base | 获得 10 点阵势，抽 1 张牌。 | 强防御过牌 | 宰衡高稳定 | 阵势 +3 | 无伤不是免难，而是计量后避灾 | 否 | - | 稀有牌命名更重 |
| 22 | `zaiheng_order_lawbeast` | 律前石兽 | chengdao | order_beast | exclusive | [zaiheng_jun] | [summon, order] | basic | 1 | self | `summon:{attack:3,life:12}` | [] | order | true | false | phase_1_base | 召唤 1 只攻 3 / 命源 12 的律前石兽。 | 防守承道兽 | 宰衡承道位 | 命源 +3 | 碑前石兽被律令唤醒 | 是 | `chengdao_stele_stone_beast` | 旧碑前石兽迁移 |
| 23 | `zaiheng_boundary_keeper` | 守界册灵 | chengdao | order_beast | exclusive | [zaiheng_jun] | [summon, order] | rare | 2 | self | `summon:{attack:5,life:16}` | [] | order | false | true | phase_1_base | 召唤 1 只攻 5 / 命源 16 的守界册灵。 | 高稳定承道兽 | 长线防守 | 攻 +1 / 命源 +3 | 册中生灵，代主守界 | 否 | - | 稀有承道兽 |

### 5.6 织夜君专属，8 张

| # | 建议 id | 卡名 | card_type | subtype | owner_scope | owner_ids | pool_tags | rarity | cost | target_type | effects | keywords | side | starter_allowed | reward_allowed | implementation_phase | 效果文本 | 设计职责 | 服务的构筑方向 | 升级方向 | 世界观说明 | 是否由旧卡迁移 | 对应旧卡 id | 命名备注 |
| ---: | --- | --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 24 | `zhiye_liuxiao` | 留宵 | daofa | defense | exclusive | [zhiye_jun] | [formation, retain] | basic | 1 | self | `gain_formation:5` | [凝梦] | neutral | true | false | phase_1_base | 获得 5 点阵势。凝梦。 | 留宵基础触发 | 保留防御 | 阵势 +2 | 她把一夜留到下一次醒来 | 是 | `dream_thread` 概念 | 与被动同名可保留 |
| 25 | `zhiye_changye` | 长夜 | daofa | utility | exclusive | [zhiye_jun] | [draw, retain] | basic | 1 | self | `draw:1` | [凝梦] | neutral | true | false | phase_1_base | 抽 1 张牌。凝梦。 | 保留过牌 | 长线运营 | 抽牌后获得 2 阵势 | 长夜并不结束，只是被折起 | 否 | - | 职业核心语汇 |
| 26 | `zhiye_canwang` | 残王庭 | daofa | defense | exclusive | [zhiye_jun] | [formation, retain] | uncommon | 2 | self | `gain_formation:10` | [凝梦] | neutral | false | true | phase_1_base | 获得 10 点阵势。凝梦。 | 大防御保留 | 织夜防守上限 | 阵势 +3 | 残世里的王庭仍未倒下 | 否 | - | 王庭冷感 |
| 27 | `zhiye_weixing` | 未醒令 | daofa | attack | exclusive | [zhiye_jun] | [attack, retain] | common | 1 | enemy | `deal_damage:6` | [凝梦] | neutral | true | true | phase_1_base | 造成 6 点伤害。凝梦。 | 保留攻击 | 留牌找窗口 | 伤害 +2 | 未醒之人仍奉夜令 | 否 | - | 避免软梦感 |
| 28 | `zhiye_muye_breath` | 幕夜息 | daofa | utility | exclusive | [zhiye_jun] | [gain_daoxi, retain, exhaust] | common | 0 | self | `gain_daoxi:1` | [凝梦, 消耗] | neutral | true | true | phase_1_base | 获得 1 点道息。凝梦。消耗。 | 0 费留牌启动 | 爆发回合 | 可不消耗 | 幕落之前的一息 | 否 | - | 短而冷 |
| 29 | `zhiye_jueye_cut` | 绝夜裁 | daofa | attack | exclusive | [zhiye_jun] | [attack] | rare | 2 | enemy | `deal_damage:14` | [] | neutral | false | true | phase_1_base | 造成 14 点伤害。 | 高伤害 | 织夜终结牌 | 伤害 +4 | 绝夜之中，裁去归路 | 否 | - | 继承裁字但偏夜 |
| 30 | `zhiye_night_crane` | 王庭夜鹤 | chengdao | order_beast | exclusive | [zhiye_jun] | [summon, night] | basic | 1 | self | `summon:{attack:2,life:10}` | [] | order | true | false | phase_1_base | 召唤 1 只攻 2 / 命源 10 的王庭夜鹤。 | 防守承道兽 | 织夜站场 | 命源 +3 | 王庭中守夜的灵鹤 | 是 | `chengdao_dream_crane` | 比共享版更职业化 |
| 31 | `zhiye_sleepless_shadow` | 未醒守影 | chengdao | neutral_beast | exclusive | [zhiye_jun] | [summon, night] | uncommon | 2 | self | `summon:{attack:4,life:15}` | [] | neutral | false | true | phase_1_base | 召唤 1 只攻 4 / 命源 15 的未醒守影。 | 长线守护 | 保留体系承压 | 命源 +3 | 未醒者身后的长夜影卫 | 是 | `不醒祟影` 命名材料 | 不迁移其敌怪属性 |

### 5.7 负棺僧专属，8 张

| # | 建议 id | 卡名 | card_type | subtype | owner_scope | owner_ids | pool_tags | rarity | cost | target_type | effects | keywords | side | starter_allowed | reward_allowed | implementation_phase | 效果文本 | 设计职责 | 服务的构筑方向 | 升级方向 | 世界观说明 | 是否由旧卡迁移 | 对应旧卡 id | 命名备注 |
| ---: | --- | --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 32 | `fuguan_songlu` | 送路 | daofa | attack | exclusive | [fuguan_seng] | [attack, burial] | basic | 1 | enemy | `deal_damage:6` | [] | neutral | true | false | phase_1_base | 造成 6 点伤害。 | 基础攻击 | 负棺僧稳定输出 | 伤害 +2 | 为敌送上一段归路 | 否 | - | 肃穆，不戏谑 |
| 33 | `fuguan_angui` | 安归 | daofa | defense | exclusive | [fuguan_seng] | [formation, burial] | basic | 1 | self | `gain_formation:6` | [] | neutral | true | false | phase_1_base | 获得 6 点阵势。 | 基础防御 | 归葬生存 | 阵势 +2 | 使亡者安归，也护生者一程 | 否 | - | 温和但沉重 |
| 34 | `fuguan_guizang_spark` | 归葬火 | daofa | attack | exclusive | [fuguan_seng] | [attack, exhaust] | common | 1 | enemy | `deal_damage:8` | [消耗] | chaos | true | true | phase_1_base | 造成 8 点伤害。消耗。 | 强消耗攻击 | 送归素材 | 伤害 +3 | 棺前一炬，照其归处 | 是 | `烬星` 概念材料 | 烬星本体留未来 |
| 35 | `fuguan_wuzang_order` | 无葬令 | daofa | utility | exclusive | [fuguan_seng] | [draw, exhaust] | common | 0 | self | `draw:1` | [消耗] | neutral | true | true | phase_1_base | 抽 1 张牌。消耗。 | 消耗过滤 | 压缩牌堆 | 抽牌后获得 1 阵势 | 无葬不是无归，是不留执念 | 否 | - | 负棺核心语感 |
| 36 | `fuguan_yugu` | 余骨 | daofa | utility | exclusive | [fuguan_seng] | [gain_daoxi, exhaust] | uncommon | 1 | self | `gain_daoxi:1` | [消耗] | neutral | false | true | phase_1_base | 获得 1 点道息。消耗。 | 资源回补 | 消耗循环 | 再抽 1 张 | 葬路旁余骨仍有一息 | 否 | - | 留给中后期 |
| 37 | `fuguan_guiyuan` | 归愿 | daofa | attack_reflux | exclusive | [fuguan_seng] | [attack, reflux_gain, exhaust] | rare | 2 | enemy | `deal_damage:13; gain_reflux:1` | [消耗] | chaos | false | true | phase_1_base | 造成 13 点伤害，回潮值 +1。消耗。 | 高压消耗攻击 | 以风险换爆发 | 伤害 +4 | 归愿未必安宁，潮也随愿而来 | 否 | - | 回潮只做增量，不做复杂阈值 |
| 38 | `fuguan_coffin_wisp` | 棺前微魂 | chengdao | neutral_beast | exclusive | [fuguan_seng] | [summon, burial] | basic | 1 | self | `summon:{attack:4,life:6}` | [] | neutral | true | false | phase_1_base | 召唤 1 只攻 4 / 命源 6 的棺前微魂。 | 脆弱承道兽 | 死亡收益伏笔 | 攻 +1 / 命源 +2 | 棺前尚未归去的一缕魂 | 否 | - | 不做亡灵军团感 |
| 39 | `fuguan_burial_beast` | 葬路骨兽 | chengdao | chaos_beast | exclusive | [fuguan_seng] | [summon, burial] | uncommon | 2 | self | `summon:{attack:7,life:12}` | [] | chaos | true | true | phase_1_base | 召唤 1 只攻 7 / 命源 12 的葬路骨兽。 | 主力承道兽 | 送归和站场 | 命源 +3 | 葬路上被引渡的骨兽 | 是 | `chengdao_rift_bone_beast` | 更贴负棺僧 |

## 6. 三套正式 12 张初始牌组

规则：

- 每套正好 12 张。
- 每套至少 8 个不同 `card_id`。
- 单个 `card_id` 最多 2 张。
- 每套至少 3 张直接伤害牌。
- 每套至少 3 张防御 / 生存牌。
- 每套 1-2 张承道兽。
- 每套至少 2 张直接支持道主被动的牌。
- 不包含 formation / trap / domain / dao_mark / equipment / character。

### 6.1 宰衡君 starter_zaiheng_v1

定位：阵势、防御、秩序、稳定循环、触发衡界。

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
- 不同 `card_id`：10
- exclusive / shared / universal：7 / 3 / 2
- 直接伤害：`zaiheng_chengliang` x2、`shared_order_boundary_cut`、`universal_breaking_style`
- 防御 / 生存：`zaiheng_jieyue` x2、`zaiheng_dingce`、`zaiheng_lingxu`、`shared_guard_still_wall`、`universal_body_guard`
- 承道兽：`zaiheng_order_lawbeast`、`shared_order_jade_deer`
- 被动支持：多数阵势牌可稳定触发 `衡界`

### 6.2 织夜君 starter_zhiye_v1

定位：凝梦、保留、长线运营、残世保护、触发留宵。

| card_id | 数量 | 来源 |
| --- | ---: | --- |
| `zhiye_liuxiao` | 1 | exclusive |
| `zhiye_changye` | 2 | exclusive |
| `zhiye_weixing` | 2 | exclusive |
| `zhiye_muye_breath` | 1 | exclusive |
| `zhiye_night_crane` | 1 | exclusive |
| `shared_night_lantern_thread` | 1 | shared |
| `shared_dream_mist_cut` | 1 | shared |
| `shared_night_crane` | 1 | shared |
| `universal_breaking_style` | 1 | universal |
| `universal_draw_breath` | 1 | universal |

统计：

- 总数：12
- 不同 `card_id`：10
- exclusive / shared / universal：7 / 3 / 2
- 直接伤害：`zhiye_weixing` x2、`shared_dream_mist_cut`、`universal_breaking_style`
- 防御 / 生存：`zhiye_liuxiao`、`zhiye_night_crane`、`shared_night_crane`，以及凝梦保留带来的回合间保护
- 承道兽：`zhiye_night_crane`、`shared_night_crane`
- 凝梦不同 `card_id`：`zhiye_liuxiao`、`zhiye_changye`、`zhiye_weixing`、`zhiye_muye_breath`、`shared_night_lantern_thread`、`shared_dream_mist_cut`
- 被动支持：至少 6 个不同凝梦 `card_id` 可触发 `留宵`

### 6.3 负棺僧 starter_fuguan_v1

定位：承道兽、死亡收益、消耗、归葬、触发送归。

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
- 不同 `card_id`：11
- exclusive / shared / universal：7 / 3 / 2
- 直接伤害：`fuguan_songlu` x2、`fuguan_guizang_spark`、`shared_return_bone_spark`、`universal_breaking_style`
- 防御 / 生存：`fuguan_angui`、`shared_burial_road_sign`、`universal_body_guard`，以及承道兽承压
- 承道兽不同 `card_id`：`fuguan_coffin_wisp`、`fuguan_burial_beast`、`shared_return_rift_beast`
- 消耗牌：`fuguan_guizang_spark`、`fuguan_wuzang_order`、`shared_return_bone_spark`、`shared_burial_road_sign`
- 被动支持：承道兽密度高，且消耗体系为后续归葬收益预留空间

## 7. 奖励池草案

奖励池规则：

- 包含本职业 exclusive。
- 包含兼容 shared。
- 包含 universal。
- 排除 `basic` 且 `reward_allowed=false` 的基础牌。
- 排除其他职业 exclusive。
- 排除 token、enemy_only、future_system、非 `phase_1_base`。

### 7.1 宰衡君奖励池

| 来源 | card_id |
| --- | --- |
| universal | `universal_draw_breath` |
| universal | `universal_clear_mind` |
| universal | `universal_wayfarer_stone` |
| shared | `shared_order_boundary_cut` |
| shared | `shared_guard_still_wall` |
| shared | `shared_order_jade_deer` |
| exclusive | `zaiheng_dingce` |
| exclusive | `zaiheng_lingxu` |
| exclusive | `zaiheng_caijie` |
| exclusive | `zaiheng_wushang_ce` |
| exclusive | `zaiheng_boundary_keeper` |

### 7.2 织夜君奖励池

| 来源 | card_id |
| --- | --- |
| universal | `universal_draw_breath` |
| universal | `universal_clear_mind` |
| universal | `universal_wayfarer_stone` |
| shared | `shared_night_lantern_thread` |
| shared | `shared_dream_mist_cut` |
| shared | `shared_night_crane` |
| exclusive | `zhiye_canwang` |
| exclusive | `zhiye_weixing` |
| exclusive | `zhiye_muye_breath` |
| exclusive | `zhiye_jueye_cut` |
| exclusive | `zhiye_sleepless_shadow` |

### 7.3 负棺僧奖励池

| 来源 | card_id |
| --- | --- |
| universal | `universal_draw_breath` |
| universal | `universal_clear_mind` |
| universal | `universal_wayfarer_stone` |
| shared | `shared_return_bone_spark` |
| shared | `shared_burial_road_sign` |
| shared | `shared_return_rift_beast` |
| exclusive | `fuguan_guizang_spark` |
| exclusive | `fuguan_wuzang_order` |
| exclusive | `fuguan_yugu` |
| exclusive | `fuguan_guiyuan` |
| exclusive | `fuguan_burial_beast` |

## 8. 旧卡迁移关系与处理原则

### 8.1 明确迁移

| 旧概念 / 旧 id | 新 card_id | 处理 |
| --- | --- | --- |
| `basic_strike` / 潮刃基础攻击概念 | `universal_breaking_style` | 重命名为更通用的基础攻击 |
| `basic_guard` | `universal_body_guard` | 保留为通用防御 |
| `breath_draw` | `universal_draw_breath` | 保留过牌功能 |
| `minor_focus` | `universal_clear_mind` | 调整为 0 费消耗过滤 |
| `minor_spirit_beast` | `universal_roaming_spirit_hound` | 保留低阶承道兽职责 |
| `stone_spirit` | `universal_wayfarer_stone` | 保留中型通用承道兽 |
| `mountain_seal` / 山印 | `shared_guard_still_wall` | 转为守界阵势牌 |
| `chengdao_linglu_order_beast` / 青玉灵鹿 | `shared_order_jade_deer` | 正式化为共享秩序承道兽 |
| `dream_thread` / 梦缕 | `shared_night_lantern_thread`、`zhiye_liuxiao` | 作为织夜命名材料重建 |
| `dream_cut` | `shared_dream_mist_cut` | 转为凝梦攻击过牌 |
| `chengdao_dream_crane` / 观梦灵鹤 | `shared_night_crane`、`zhiye_night_crane` | 改为宵庭 / 王庭夜鹤 |
| `chengdao_rift_bone_beast` / 裂界骨兽 | `shared_return_rift_beast`、`fuguan_burial_beast` | 收束为归葬承道兽 |

### 8.2 暂不迁入首批 active 卡池

| 旧卡 / 概念 | 处理 |
| --- | --- |
| `潮刃` | 不再作为全职业基础攻击唯一名称，可留给未来潮系角色 |
| `月落` | 可留给未来姜氏 / 月衡方向，不进入首批三职业 |
| `烬星` | 语感不贴三位开放道主，本体不迁入；仅拆出归葬火的火光概念 |
| `回潮逆涌` | 留给未来饮潮王 / 回潮体系 |
| `不醒祟影` | 倾向 enemy_only 或织夜敌对镜像；首批只借“未醒”语感 |
| `回潮孽物` | 敌人概念，不进入玩家 active 卡池 |
| `倒灌古兽` | 留作未来 rare / unique / special 承道兽 |

## 9. 命名与职业语言审查

| card_id | 审查结论 | 备选名 |
| --- | --- | --- |
| `universal_breaking_style` | 通用、古朴，适合作基础攻击 | 破障式 |
| `universal_body_guard` | 清楚实用 | 护命诀 |
| `universal_draw_breath` | 符合调息过牌 | 引梦息 |
| `universal_clear_mind` | 适合 0 费过滤 | 静神 |
| `universal_roaming_spirit_hound` | 低阶灵兽感明确 | 游梦犬 |
| `universal_wayfarer_stone` | 行旅感明确 | 古道石灵 |
| `shared_order_boundary_cut` | 守界和宰衡兼容 | 界尺裁 |
| `shared_guard_still_wall` | 防御感稳定 | 静壁诀 |
| `shared_order_jade_deer` | 青玉灵鹿迁移自然 | 青玉灵鹿 |
| `shared_night_lantern_thread` | 织夜感强 | 宵灯丝 |
| `shared_dream_mist_cut` | 梦 / 夜兼容 | 雾夜裁 |
| `shared_night_crane` | 比观梦灵鹤更贴织夜 | 宵庭鹤 |
| `shared_return_bone_spark` | 归葬感明确 | 归骨星 |
| `shared_burial_road_sign` | 肃穆，不像死灵法 | 葬路录 |
| `shared_return_rift_beast` | 从裂界转为归葬 | 归裂骨灵 |
| `zaiheng_*` | 统一围绕界、约、称量、册、令 | 可继续强化“衡”字密度 |
| `zhiye_*` | 统一长夜、王庭、未醒、留宵 | 避免“梦妖”“魅梦”等词 |
| `fuguan_*` | 统一归、葬、棺、送、安 | 避免“亡灵军团”方向 |

## 10. 实现依赖清单

### 10.1 当前已经支持或接近支持

| 能力 | 状态 | 说明 |
| --- | --- | --- |
| `deal_damage` | 已支持 / 兼容层可直接接入 | 当前道法伤害已能打敌人 |
| `gain_formation` | 已支持 / 兼容层可直接接入 | 阵势与宰衡被动已可工作 |
| `draw` | 已支持 / 兼容层可直接接入 | PVE 抽牌堆 / 弃牌堆已存在 |
| `gain_daoxi` | 需要 v1 兼容层确认 | 若已有资源修改 helper，可直接映射 |
| `gain_reflux` | 需要 v1 兼容层确认 | 当前回潮作为 Run 变量保留 |
| `reduce_reflux` | 需要 v1 兼容层确认 | 首批 39 张暂未使用，但可列为 phase 1 基础能力 |
| `summon` | 已支持 / 兼容层可直接接入 | 承道兽上场和攻击已存在 |
| `凝梦` | 已支持 | `card_has_retain()` 已可识别 |
| `消耗` | 已支持 | `card_has_exhaust()` 已可识别 |

### 10.2 v1 兼容层需要实现

| 项目 | 说明 |
| --- | --- |
| effects 数组解析 | 将 `effects` 中的基础效果顺序结算 |
| target_type 映射 | `enemy`、`self`、`self_or_enemy` 的点击和校验 |
| chengdao summon 数据 | 从 `effects.summon` 生成战场单位 |
| reward_allowed / starter_allowed | 奖励池和初始牌组加载时过滤 |
| owner_scope / owner_ids | 防止其他道主拿到专属牌 |
| pool_tags | 用于奖励池、事件、遗物协同检索 |

### 10.3 暂时不允许进入首批 active 卡池

| 系统 | 原因 |
| --- | --- |
| 伏法触发 | 需要独立时机和触发器 |
| 法阵持续规则 | 需要持续区、持续回合和替换逻辑 |
| 域界规则 | 需要全局场地、侧性和覆盖逻辑 |
| 主动献祭承道兽 | 需要选择己方单位和死亡归属 |
| 从消耗堆取回卡 | 会影响三堆一致性 |
| 复活承道兽 | 需要死亡记录和重生目标 |
| 敌人意图操控 | 会影响敌人 AI / intent 系统 |
| 复杂状态 | 需要 Buff/Debuff runtime |
| 命器装备 | 需要装备位和适格判断 |

## 11. 后续最小新增卡牌建议

本批 39 张已经覆盖三位开放道主的 phase 1 核心体验。后续若要扩展，每位道主建议先补 2-4 张，而不是一次性大扩池。

### 11.1 宰衡君

| 建议 id | 卡名 | 类型 | 费用 | 简单效果 | 关键词 | 服务道主 | 当前代码是否支持 | 是否需要新增效果处理 |
| --- | --- | --- | ---: | --- | --- | --- | --- | --- |
| `zaiheng_balance_return` | 衡返 | daofa | 1 | 若本回合获得过阵势，抽 2 | [] | 宰衡君 | 否 | 需要条件判断 |
| `zaiheng_boundary_oath` | 守界誓 | daofa | 2 | 获得阵势，下一次受伤降低 | [] | 宰衡君 | 否 | 需要临时减伤 |

### 11.2 织夜君

| 建议 id | 卡名 | 类型 | 费用 | 简单效果 | 关键词 | 服务道主 | 当前代码是否支持 | 是否需要新增效果处理 |
| --- | --- | --- | ---: | --- | --- | --- | --- | --- |
| `zhiye_unfinished_dream` | 未竟梦 | daofa | 1 | 若本牌被保留过，造成额外伤害 | [凝梦] | 织夜君 | 否 | 需要 retained_turns |
| `zhiye_night_storage` | 藏宵 | daofa | 1 | 保留一张指定手牌 | [凝梦] | 织夜君 | 否 | 需要手牌选择 |

### 11.3 负棺僧

| 建议 id | 卡名 | 类型 | 费用 | 简单效果 | 关键词 | 服务道主 | 当前代码是否支持 | 是否需要新增效果处理 |
| --- | --- | --- | ---: | --- | --- | --- | --- | --- |
| `fuguan_bury_the_small` | 葬小魂 | daofa | 1 | 牺牲一个己方承道兽，造成伤害 | [消耗] | 负棺僧 | 否 | 需要献祭选择 |
| `fuguan_return_bell` | 归铃 | daofa | 1 | 从消耗堆选择一张承道牌加入手牌 | [消耗] | 负棺僧 | 否 | 需要消耗堆检索 |

## 12. 人工决定事项

以下事项建议在写入正式 `cards_v1.json` 前由设计侧确认：

1. `basic` 牌是否完全不进入奖励池。目前建议 `reward_allowed=false`。
2. `universal_clear_mind` 是否允许 0 费抽 1 消耗。若前期过强，可改为 1 费抽 1 或 0 费获得 1 道息消耗。
3. 织夜君 starter 中凝梦密度较高，是否希望更极端地偏保留流。
4. 负棺僧 starter 暂不含主动献祭，送归主要通过承道兽自然死亡触发，是否接受这个第一版节奏。
5. `gain_reflux` 暂只在 `fuguan_guiyuan` 使用，是否把回潮风险留给后续饮潮王。
6. 旧卡 `月落` 是否确定留给未来姜氏 / 月衡体系。
