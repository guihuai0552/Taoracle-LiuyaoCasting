# 六爻离线 APK 对齐状态

> 状态：`Implemented / APK Ready for User Review`  
> 更新：2026-08-07  
> 目标：生产 APK 完全离线，Dart 结果逐字段对齐 Python cnlunar/Najia 权威实现

## 当前结论

生产运行时已收敛为 Flutter + 独立纯 Dart `liuyao_engine` + 设备端档案，不需要 Node、Python、HTTP 或环境变量。本轮 release APK 已重新构建、检查、安装并在 `liuyao_api36` 模拟器冷启动成功；当前进入用户体验审阅。

| 模块 | 状态 | 自动化证据 |
|---|---|---:|
| cnlunar 农历、四柱、纳音、13 时辰、节气、财神 | 已精确移植并升级精确交节 | 16,115 个兼容快照 + 2,388 个交节边界 |
| 64 卦、本变卦、卦宫、世应、纳甲、六亲、六神 | 已精确移植 | 4,096 个本卦/变卦组合 |
| 用户确认的全伏卦、六爻伏神 | 已精确移植 | 同上 4,096 组合 |
| 本卦/伏卦/变卦十二长生、驿马、桃花、禄神、华盖、天乙贵人、卦身、命爻 | 已移植；三层独立计算，新盘按 DEC-049 收口七项标注 | 3,840 个兼容快照 + 私有参考 parity + schema v16 golden |
| 本卦/伏卦/变卦京房六十四卦配二十八宿 | 已实现；三层分别按自身卦宫、序位与世应装宿 | 64×64 结构矩阵 + 三层固定盘样例 |
| 手动/自动起卦与原始过程 | 已实现 | Dart/Flutter tests |
| 自动存档、重启恢复、解读、反馈、Markdown/JSON/PNG 导出 | 已实现 | 档案单测 + Android 强停/升级/系统分享验证 |
| 完整批量迁移、导入预检、安全合并与替换恢复 | 已实现 | 往返/冲突/UTF-8/损坏包测试 + Android 原生文件选择器 |
| release 生产源码断网 | 已实现 | `check_offline_mobile_release.py` |
| release APK 权限复核 | 已通过 | 仅 `com.liuyao.archive.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`，无网络权限 |

## 本轮 APK 证据

| 项目 | 结果 |
|---|---|
| 文件 | `六爻分析存档-三层长生星宿-v1.5.0.apk`（与构建目录 `app-release.apk` 相同） |
| 应用 ID | `com.liuyao.archive` |
| 版本 | `1.5.0` (`versionCode=7`) |
| 大小 | 53,845,297 bytes（约 53.8 MB） |
| SHA-256 | `db75e6a2ec2b517831700dc64dabb5b678bfe17db5de728c1ad775be1c753609` |
| APK 权限 | 仅应用内动态广播权限；无 `INTERNET`、`ACCESS_NETWORK_STATE`、`CHANGE_NETWORK_STATE` |
| APK 签名 | v2 验证通过；Android Debug 证书，仅供审阅安装 |
| 启动验证 | `liuyao_api36` 通过 `adb install -r` 保留数据覆盖安装，主 Activity 启动成功并截图核对万年历首屏 |

## 已修复的历史偏差

- schema 从旧 v12 对齐到 v13，并加入二十八宿合同。
- 伏卦不再使用“缺六亲才挂伏神”的旧逻辑；内外卦分别按宫卦/错卦规则生成，六爻全部展示。
- 变卦六亲固定以本卦宫五行为基准。
- 年柱、日柱基准、纳音、月柱、节气、财神、闰月状态与支持边界全部改为 cnlunar 精确数据。
- 桃花、天乙、华盖 Dart 旧表已由全量注解矩阵发现并修正。
- 直接农历 API 的设备时区早一天问题已修正。
- 删除重复且不完整的 `najia_core.dart`，生产只保留一个算法源。
- 档案加载/写入不再静默吞错；新增 schema、旧版迁移、原子写和乐观锁。
- 写入中断时比较主文件和 `.tmp` 的完整性与更新时间，恢复更新的一份；前台恢复时自动刷新档案列表。
- Android 文件选择器按严格 UTF-8 字节解码迁移包，修复中文被平台字符串接口错误解释的问题；支持 UTF-8 BOM，非法字节在写入前拒绝。
- main Android Manifest 已移除 INTERNET；debug/profile 只用于 Flutter 开发。

## 已完成质量门禁

- 独立包 `dart analyze`、`dart test` 通过；移动端 `flutter analyze` 零问题、59 项 `flutter test` 通过。
- Python 对照实现 62 项测试通过。
- 三组 parity 共 24,051/24,051 通过。
- 生产源码与 APK 权限断网门禁通过。
- APK 已安装并冷启动；覆盖安装后档案仍存在。自动化测试覆盖手动/自动排盘、自动存档、解读、反馈、三种单档导出和批量迁移的完整往返及错误保护。

## 审阅后发布动作

1. 用户按真实使用习惯审阅万年历、排盘、卦面信息密度、档案与导出。
2. 将审阅问题实时回写相关 Spec 和变更日志。
3. 正式分发前配置专用 release keystore、确定应用 ID/产品名和本项目自身开源许可证；当前审阅包不得直接上架。

详细架构与门禁见 [完全离线 Dart 架构](./architecture/offline-dart-architecture.md)。
