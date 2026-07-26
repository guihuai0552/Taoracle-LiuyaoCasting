# 六爻存档

一个以 Flutter 为客户端、Pi Agent SDK 为智能服务层的六爻记录与分析 App。

## 项目结构

```text
apps/mobile/       Flutter Android App
services/agent/    SQLite 案例 API + Pi Agent SDK + 六爻 Tools
services/liuyao-engine/  Python + Najia 无状态排盘服务
```

## 本地启动

### 1. 配置排盘引擎

```bash
cd services/liuyao-engine
python3 -m venv .venv
.venv/bin/pip install -e .
cd ../..
npm run dev:engine
```

排盘服务监听 `127.0.0.1:8790`。输入、输出均为 JSON，六个爻值固定按“初爻到上爻”排列。

### 2. 配置 Agent 与案例 API

```bash
cp services/agent/.env.example services/agent/.env
# 按选用的模型提供商填写 API Key
npm install
npm run dev:agent
```

Pi 也支持使用其全局认证存储；可先安装 Pi CLI 后运行 `pi`，再用 `/login` 登录。

案例 API 监听 `127.0.0.1:8787`，SQLite 默认保存到
`services/agent/.data/liuyao.sqlite`。Flutter 和 Pi Tools 共用这一个数据源。

### 3. 启动 Android App

```bash
flutter emulators
flutter emulators --launch liuyao_api36
cd apps/mobile
flutter run
```

Android 模拟器通过 `10.0.2.2` 访问电脑上的 Agent 服务。真机或其他平台可覆盖地址：

```bash
HOST=0.0.0.0 npm run dev:agent
flutter run --dart-define=AGENT_BASE_URL=http://192.168.1.10:8787
```

## 检查

```bash
npm run test:engine
npm run check:agent
npm run test:agent
cd apps/mobile
dart format --output=none --set-exit-if-changed .
dart analyze
flutter test
```

## 已实现的 MVP

- 自动铜钱或手工 `6/7/8/9` 排盘，保存原始爻值和版本化盘面快照
- 本卦、变卦、六神、六亲、纳支、五行、伏神、世应与动爻页面
- SQLite 卦例列表、详情和“我的分析”追加式版本记录
- `liuyao_cast`、`liuyao_create_case`、`liuyao_get_case`、
  `liuyao_search_cases`、`liuyao_append_analysis` 五个 Pi Tools
- 从卦例详情携带可信 `caseId` 进入 Agent
- Android 模拟器本地 HTTP 调试配置

结构化旺衰分析、事后验证、标签搜索、图片附件和云同步属于后续业务迭代。

## 已验证的本地工具链

- Flutter 3.44.0 / Dart 3.12.0
- Node.js 26.5.0
- Pi Agent SDK 0.82.1
- JDK 17.0.19
- Android Studio Quail 2 Patch 1（2026.1.2.11）
- Android SDK 36、Platform-Tools 37.0.0
- Android Emulator 36.6.11、Pixel 9 / Android 16（API 36）
