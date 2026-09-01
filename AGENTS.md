# 六爻存档开发指引

## 当前架构

- `packages/liuyao_engine`：唯一生产排盘与万年历实现。纯 Dart、无 Flutter/网络依赖。
- `apps/mobile`：Flutter Android 客户端，负责 UI、设备端状态、原子 JSON 档案与系统分享。
- `services/liuyao-engine`：Python + cnlunar + Najia 权威对照实现，只用于规则研究、golden/parity 测试，不进入 APK，也不是 App 运行依赖。
- 不要把 API Key、OAuth Token、服务地址或会话文件打包进 Flutter 应用。
- 所有新排盘规则先进入独立 Dart 包，并通过 Python↔Dart 对照；Widget 不得自算业务规则。

## 开发命令

```bash
cd packages/liuyao_engine
dart pub get
dart analyze
dart test

cd ../../apps/mobile
flutter pub get
dart analyze
flutter test
flutter run
```

跨语言质量门禁从仓库根目录运行：

```bash
services/liuyao-engine/.venv/bin/python scripts/check_offline_almanac_parity.py
services/liuyao-engine/.venv/bin/python scripts/check_offline_liuyao_structure_parity.py
services/liuyao-engine/.venv/bin/python scripts/check_offline_liuyao_annotation_parity.py
python3 scripts/check_offline_mobile_release.py --apk <release-apk-path>
```

## 质量要求

- Dart 提交前运行 `dart format .`、`dart analyze`、`flutter test`。
- Python 对照合同变更必须增加固定时间、固定爻值 golden，并同步三条 parity 脚本。
- 排盘输出继续保存原始输入、schema/rule version 与完整 `calculation_trace`。
- 档案格式变更必须增加版本迁移、损坏保护与重启恢复测试。
- 新功能按 feature 划分目录；存储代码不要直接写进 Widget。
- 提交信息使用 Conventional Commits，例如 `feat: add archive detail page`。

## 安全与离线约束

- `src/main/AndroidManifest.xml` 禁止 INTERNET/网络状态权限；debug/profile 可为 Flutter 调试保留 INTERNET。
- 生产 Dart 源码禁止 HTTP、Dio、Socket、WebSocket 和远程服务兜底。
- 发布 APK 必须通过 `scripts/check_offline_mobile_release.py --apk <path>`。
- 损坏档案不得静默当作空库覆盖；持久化失败必须反馈给调用方。
