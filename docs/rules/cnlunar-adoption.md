# cnlunar 万年历技术基线评估

> 状态：`Pure Dart Port Implemented / Cross-language Verified`  
> 最近更新：2026-08-06  
> 上游项目：[OPN48/cnlunar](https://github.com/OPN48/cnlunar)  
> 关联 Spec：[SPEC-001 万年历](../specs/SPEC-001-almanac.md)

## 1. 决定

万年历以 `OPN48/cnlunar` 作为规则与数据基础。Python `services/liuyao-engine` 保留为权威对照；生产 APK 使用 `packages/liuyao_engine` 中的纯 Dart 精确移植，不运行 Python，也不通过 Node/HTTP 转发。Flutter 只消费项目稳定合同，不依赖 cnlunar 的类、字段名和拼接文本。

这项决定代表“采用它作为基础”，不代表未经验证直接接受所有字段。时间边界、四柱口径、财神取法、纳音用字和二十八宿含义仍按本项目规则文档与 golden tests 冻结。

## 2. 采用理由

- 上游 Python 实现规则集中、数据可冻结，适合作为移植和回归基线。
- 纯 Dart 版本无数据库、网络和 Flutter 依赖，可直接随 APK 分发并独立开源。
- 官方说明覆盖公历/农历、二十四节气、四柱、时辰干支、纳音、吉神方位、值日二十八宿等本项目所需字段。
- 其农历与节气数据范围以 1901–2100 年为核心，适合作为首版明确支持范围。
- 本项目精确采用上游 MIT 提交 `8a944ada2f174c350a9fa69057597ecae5eb76be`；可使用、修改和分发，但发布时必须保留版权及许可声明。

## 3. 能力映射

| 本项目字段 | cnlunar 能力 | 适配策略 | 状态 |
|---|---|---|---|
| 农历年月日、闰月 | `Lunar` 实例字段 | 转为独立数字字段和中文显示字段 | 可复用 |
| 年/月/日/时四柱 | `year8Char`、`month8Char`、`day8Char`、`twohour8Char` | 拆分天干与地支，不直接传字符串 | 可复用，边界待测 |
| 当日时辰干支 | `twohour8CharList` | 转为 13 个有索引的时辰槽，保留首尾两个子时位置并标记当前槽 | 已适配，显示语义待 UI 验证 |
| 纳音 | `get_nayin()` 只直接返回日柱纳音 | 适配层对四柱逐柱查六十甲子纳音表 | 部分复用 |
| 财神方位 | `get_luckyGodsDirection()` 返回多个吉神方位 | 结构化解析并只输出首版确认的财神；保留规则版本 | 可复用，需样例验证 |
| 节气 | 当日、下一节气、全年节气字段 | 统一时区与边界后结构化输出 | 可复用，需边界测试 |
| 值日二十八宿 | `get_the28Stars()` | 仅作为 SPEC-008 的候选日历来源 | 暂不启用 |
| 六爻二十八宿入卦 | 无对应的已确认能力 | 不复用、不推断 | 不在当前范围 |

## 4. 已识别的边界与风险

### 4.1 支持年份

上游农历和二十四节气核心数据围绕 1901–2100 年。实测发现完整安全本地日期范围是 1901-02-19 至 2100-02-08；更早日期会借用 Python 负索引产生不可采信结果，更晚日期触发上游 `IndexError`。适配器已经在调用上游前拒绝越界输入。

### 4.2 时间与时区

cnlunar 接受 Python `datetime`，自身不承担完整 IANA 时区语义。Dart 轮子已冻结 Asia/Shanghai 在支持区间内的 28 个 UTC offset 转换点，统一先得到上海墙上时间，再执行历法规则；农历直接 API 只读取年月日字段，避免设备时区导致早一天。

### 4.3 四柱切换口径

上游提供 `year8Char` 等配置选项，年柱是否以立春切换、月柱如何依节气切换仍需本项目通过 Q-003 冻结。不得把库默认值当作未记录的隐含规则。

### 4.4 纳音用字

2026-08-05 样例中，上游返回“砂中金”，参考截图显示“沙中金”。这是文字规范差异，不是数值计算差异。适配层需要术语字典并保留原始值，正式显示用字由 Q-033 决定。

### 4.5 吉神方位

上游 `get_luckyGodsDirection()` 同时返回喜神、财神、福神、阳贵、阴贵。首版只确认财神；适配层不得因为上游已有数据就自动扩大产品范围。

### 4.6 上游对象稳定性

上游字段以 Python 属性和中文拼接字符串为主。本项目必须建立适配层和契约测试，防止升级时字段含义或文字变化直接影响档案。

## 5. 版本与许可策略

- Python 对照环境固定为 PyPI `cnlunar==0.2.0`；该 wheel 和 `v0.2.0` 标签携带 GPLv3，不能写成 MIT。
- 生产 Dart 移植精确锚定提交 `8a944ada2f174c350a9fa69057597ecae5eb76be`（`v0.2.0-1-g8a944ad`）。经 Git 树对比，该提交相对 `v0.2.0` **只修改 `LICENSE`**，算法和数据文件零差异；作者在该提交将仓库许可改为 MIT。
- 不使用无上限浮动依赖。
- 升级必须跑完整历法 golden tests，并记录行为差异。
- 应用发布物和源码仓库需保留 MIT 提交的版权与许可文本，并登记到第三方依赖清单；不得用标签名替代许可证对应的精确 commit。

## 6. 适配层输出原则

```text
AlmanacAdapter
  input:
    local_datetime
    iana_timezone
    rule_options
  output:
    source = "cnlunar"
    source_version
    supported_range
    lunar_date
    four_pillars[]
    four_pillars[].nayin
    two_hour_pillars[13]
    solar_terms
    wealth_god_direction
    calculation_trace
```

每个中文展示值旁边应尽量保留结构化枚举或拆分字段。API 不直接暴露 cnlunar 的 `Lunar` 对象。

## 7. 首个固定样例

输入：`2026-08-05 15:25`，时区 `Asia/Shanghai`，当前研究副本 `8a944ad`，`godType='8char'`。

| 字段 | 当前观察值 |
|---|---|
| 农历 | 丙午年 六月廿三 |
| 四柱 | 丙午 / 乙未 / 辛亥 / 丙申 |
| 四柱纳音 | 天河水 / 砂中金 / 钗钏金 / 山下火 |
| 当前时柱 | 丙申 |
| 财神 | 正东 |
| 值日宿候选 | 壁水貐 |

此样例与用户参考图大体一致；“砂中金/沙中金”差异必须在术语决策后才能成为最终 golden case。

## 8. 实施检查

- [x] Python 对照固定 `cnlunar==0.2.0`；生产移植固定 MIT commit `8a944ad...`。
- [x] 实测真实可计算边界并在适配器前置拦截。
- [x] 建立独立 Python `AlmanacAdapter` 作为对照合同。
- [x] 将原始农历月表、二十四节气表、四柱、纳音、财神与 13 时辰精确移植到纯 Dart。
- [x] 冻结节气换月、23:00 换日与 Asia/Shanghai 时区策略。
- [x] 为闰月、春节、全部节气前后和 23:00 子时建立完整矩阵。
- [x] 验证财神方向的日干查表口径。
- [x] 建立四柱纳音适配；“砂/沙”显示字典仍待决定。
- [x] `packages/liuyao_engine/THIRD_PARTY_NOTICES.md` 加入 cnlunar MIT 第三方声明原文。

## 9. 实现位置与测试

- 生产实现：`packages/liuyao_engine/lib/src/almanac.dart`、`lunar_core.dart`、`solar_terms.dart`、`shanghai_time.dart`
- Python 对照：`services/liuyao-engine/app/almanac.py`
- 算法测试：`services/liuyao-engine/tests/test_almanac.py`
- 月历算法测试：`services/liuyao-engine/tests/test_almanac_month.py`
- API 测试：`services/liuyao-engine/tests/test_almanac_api.py`
- 跨语言门禁：`scripts/check_offline_almanac_parity.py`
- 当前结果：1902–2099 共 16,115 个 cnlunar/Dart 快照全部一致。
