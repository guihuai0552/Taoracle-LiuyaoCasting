# 六爻排盘与存档

完全离线的 Flutter Android 六爻工具。当前产品不包含 Agent、模型 API、账号或云端服务；安装 APK 后，万年历、排盘、自动存档、解读、反馈、图片导出与跨设备文件迁移均在设备内完成。

## 架构

```text
packages/liuyao_engine/  纯 Dart 六爻 + cnlunar 精确移植（生产唯一算法源）
apps/mobile/             Flutter UI、设备端档案、系统分享
services/liuyao-engine/  Python 权威对照与研究实现（仅开发/测试）
services/agent/          历史服务端参考，不进入当前运行路径
scripts/                 跨语言与断网发布门禁
```

`liuyao_engine` 当前输出 schema v16，包含本卦/变卦各自卦宫与世应、纳甲、逐爻纳音、六亲、六神、用户确认的完整伏卦/伏神、本伏变三层十二长生与京房二十八宿、五项神煞、卦身/命爻、私有参考合同及完整计算轨迹。万年历支持 1901-02-19 至 2100-02-08，提供农历、精确交节四柱、纳音、四柱旬空、13 时辰、值日宿、二十四节气和财神方位。

## 启动

```bash
cd apps/mobile
flutter pub get
flutter run
```

不需要启动 Node、Python、数据库或配置环境变量。

本轮可安装审阅包：[六爻分析存档-三层长生星宿-v1.5.0.apk](六爻分析存档-三层长生星宿-v1.5.0.apk)。它是 `1.5.0+7` 完全离线 release 构建，包含 schema v16 本卦/伏卦/变卦三层十二长生与京房逐爻宿、七项选定标注和本变卦各自世应，并保留完整档案、批量迁移及 PNG 长图导出；当前使用 Android Debug 证书签名，仅用于安装审阅，不能直接上架。SHA-256：`db75e6a2ec2b517831700dc64dabb5b678bfe17db5de728c1ad775be1c753609`。

## 验证

```bash
cd packages/liuyao_engine
dart analyze
dart test

cd ../../apps/mobile
dart analyze
flutter test

cd ../..
services/liuyao-engine/.venv/bin/python scripts/check_offline_almanac_parity.py
services/liuyao-engine/.venv/bin/python scripts/check_offline_liuyao_structure_parity.py
services/liuyao-engine/.venv/bin/python scripts/check_offline_liuyao_annotation_parity.py
/Users/feiwu4/Documents/vibecoding/liuyao/.venv/bin/python \
  scripts/check_private_reference_dart_parity.py
python3 scripts/check_offline_mobile_release.py \
  --apk apps/mobile/build/app/outputs/flutter-apk/app-release.apk
```

除既有跨语言矩阵外，新增私有参考的 64 卦完整 plate、60 纳音、144 项十二长生、固定动爻合同和 2,388 个精确交节“前一秒/当秒”边界验证。

## 档案

排盘完成后自动保存当前完整 JSON 快照并进入独立卦面页。设备端存储使用 App 私有持久目录中的带 schema 原子 JSON 容器；退出后台、划掉任务或系统结束进程都不会清除。它支持旧版根对象迁移、写入中断恢复、损坏副本保留、解读乐观锁、反馈编辑，单档 Markdown/JSON/PNG 导出，以及完整批量迁移包的安全合并或清空恢复。卸载应用或在系统设置主动清除应用数据才会删除档案，因此卸载前应先导出迁移包。

文档入口见 [docs/README.md](docs/README.md)。
