# 道谕六爻 · Taoracle LiuyaoCasting

[![Flutter](https://img.shields.io/badge/Flutter-Android-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/engine-pure%20Dart-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Offline](https://img.shields.io/badge/%E8%BF%90%E8%A1%8C-%E5%AE%8C%E5%85%A8%E7%A6%BB%E7%BA%BF-2EA44F)](https://github.com/guihuai0552/Taoracle-LiuyaoCasting)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

完全离线的六爻排盘与案例存档工具。基于**京房八宫纳甲体系**装卦，排盘结果完整可追溯，档案本地保存、可导出、可迁移——不依赖任何网络服务、账号或模型 API。

##  功能特性

- **万年历** —— 1901–2100 年农历、精确交节四柱（立春换年、十二节换月，精确到秒）、纳音、旬空、13 时辰、值日二十八宿、二十四节气与财神方位。
- **起卦** —— 手动逐爻录入与三枚铜钱自动摇卦，爻序固定为初爻至上爻。
- **完整卦面** —— 本卦 / 变卦各自的卦宫与世应、纳甲、六亲、六神；按宫卦 / 错卦规则排出的完整伏卦与伏神；本卦、伏卦、变卦三层五行十二长生与京房二十八宿；驿马、桃花、禄神、华盖、天乙贵人五项神煞与卦身、命爻。
- **可追溯计算** —— 每个标注都能展开「起点 → 查表/步进 → 命中地支 → 命中爻位」的完整 `calculation_trace`。
- **案例档案** —— 排盘后自动保存完整 JSON 快照；支持搜索、解读版本、反馈、单档 Markdown / JSON / PNG 导出，以及跨设备批量迁移。
- **隐私与离线** —— 无 INTERNET 权限、无遥测、无云端；所有数据存于设备私有目录，卸载前可导出迁移包。

排盘遵循的规则体系、底本出处与治理原则见 **[RULES.md](RULES.md)**。

##  架构

```text
packages/liuyao_engine/   纯 Dart 排盘与万年历引擎（生产唯一算法源，无 Flutter/网络依赖）
apps/mobile/              Flutter Android 客户端（UI、设备端档案、系统分享）
services/liuyao-engine/   Python 权威对照实现（仅开发/测试，用于跨语言 parity 验证）
scripts/                  跨语言对照与断网发布门禁脚本
docs/                     产品、规则、规格与决策文档中心
```

引擎当前输出 **schema v16**：本卦/变卦各自卦宫世应、纳甲、逐爻纳音、六亲、六神、用户确认口径的完整伏卦/伏神、本伏变三层十二长生与京房二十八宿、五项神煞、卦身/命爻、私有参考合同及完整计算轨迹。

##  快速开始

### 前置要求

- Flutter SDK（含 Android 工具链）
- Dart SDK `^3.12`
- Python 3（仅运行对照与门禁脚本时需要）

### 运行 App

```bash
cd apps/mobile
flutter pub get
flutter run
```

不需要启动 Node、数据库，不需要配置任何环境变量或 API Key。

### 构建 Release APK

```bash
cd apps/mobile
flutter build apk --release
```

发布 APK 必须通过断网门禁检查（校验无网络权限、无远程调用）：

```bash
python3 scripts/check_offline_mobile_release.py \
  --apk apps/mobile/build/app/outputs/flutter-apk/app-release.apk
```

##  测试与验证

```bash
# 引擎单元测试
cd packages/liuyao_engine && dart analyze && dart test

# App 测试
cd apps/mobile && dart analyze && flutter test

# 跨语言对照门禁（先在 services/liuyao-engine 安装依赖：cd services/liuyao-engine && uv sync）
services/liuyao-engine/.venv/bin/python scripts/check_offline_almanac_parity.py
services/liuyao-engine/.venv/bin/python scripts/check_offline_liuyao_structure_parity.py
services/liuyao-engine/.venv/bin/python scripts/check_offline_liuyao_annotation_parity.py
```

验证矩阵覆盖：64 卦完整卦盘、60 纳音、144 项十二长生、固定动爻合同，以及 2,388 个精确交节「前一秒 / 当秒」边界。

##  目录结构

```text
packages/liuyao_engine/      # 排盘引擎（算法唯一源）
apps/mobile/                 # Flutter 客户端
  └─ lib/src/
      ├─ engine/             # 引擎适配层
      ├─ features/           # 万年历 / 起卦 / 卦面 / 档案 / 设置
      └─ ui/                 # 设计系统与通用组件
services/liuyao-engine/      # Python 对照实现（开发用）
scripts/                     # parity 与发布门禁
docs/
  ├─ rules/                  # 规则文档：八宫伏卦、二十八宿、来源登记…
  ├─ specs/                  # SPEC-001~008 功能规格
  ├─ product/                # PRD
  └─ decisions/              # ADR 与决策日志
```

##  文档

- **[RULES.md](RULES.md)** —— 排盘规则遵循说明（先读这个）
- [文档中心](docs/README.md) —— 单一事实源入口
- [规则来源登记表](docs/rules/source-register.md) —— 每条规则的出处、等级与采用状态
- [项目术语表](docs/rules/glossary.md) —— 排盘、本伏、值日宿等核心名词

##  贡献

- 提交信息使用 [Conventional Commits](https://www.conventionalcommits.org/zh-hans/)，例如 `feat: add archive detail page`。
- 所有排盘规则改动先进入 `packages/liuyao_engine`，通过 Python↔Dart 对照后再动 UI；Widget 不得自算业务规则。
- 规则争议先读 [docs/README.md](docs/README.md) 的治理流程，并同步 [规则来源登记表](docs/rules/source-register.md)。

##  开源依赖与致谢

本项目站在以下开源项目之上（采用的精确版本、提交与完整许可声明见 [THIRD_PARTY_NOTICES.md](packages/liuyao_engine/THIRD_PARTY_NOTICES.md)）：

| 项目 | 许可证 | 在本项目中的角色 |
|---|---|---|
| [OPN48/cnlunar](https://github.com/OPN48/cnlunar) | MIT | **万年历核心**——农历、二十四节气、四柱、纳音、财神方位等历法算法的移植基线；生产端为纯 Dart 精确移植，运行时不依赖 Python |
| [6tail/lunar-python](https://github.com/6tail/lunar-python) | MIT | 1901–2099 年精确交节时间的对照来源，用于跨实现核验 |
| [kentang2017/najia](https://github.com/kentang2017/najia) | MIT | 纳甲装卦规则的 Python 对照实现，仅用于回归测试，不随产品分发 |
| [ButCornB/KingHwa-OldSongfont](https://github.com/ButCornB/KingHwa-OldSongfont) | OFL-1.1 | 「京华老宋体」——App 卦面导出排版字体（GB2312 子集） |

感谢以上项目的作者与维护者。

##  许可证

[MIT](LICENSE)。第三方开源依赖的许可声明见 [THIRD_PARTY_NOTICES.md](packages/liuyao_engine/THIRD_PARTY_NOTICES.md)。

---

*本项目只做排盘计算与位置标注，不生成吉凶结论；解读由使用者自行完成并存档。*
