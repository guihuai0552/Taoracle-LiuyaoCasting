# 六爻存档开发指引

## 架构

- `apps/mobile`：Flutter Android 客户端，只负责 UI、设备端状态与调用 Agent API。
- `services/agent`：Node.js/TypeScript 案例 API，持有 SQLite、Pi Agent SDK、模型凭据与会话。
- `services/liuyao-engine`：无状态 Python 排盘引擎，负责 Najia 计算和稳定 JSON 合约。
- 不要把 API Key、OAuth Token 或 Pi 会话文件打包进 Flutter 应用。
- Flutter 和 Pi Tools 必须通过同一个 `CaseService` 读写案例，禁止各自维护第二份业务数据。

## 开发命令

```bash
npm run dev:engine
npm run dev:agent # 另一个终端
cd apps/mobile && flutter run
```

Android 模拟器访问宿主机使用 `http://10.0.2.2:8787`。真机调试时通过
`--dart-define=AGENT_BASE_URL=http://<电脑局域网IP>:8787` 覆盖。

## 质量要求

- TypeScript 保持 `strict`，提交前运行 `npm run check:agent`。
- Python 排盘合约变更必须增加固定时间、固定爻值的 golden test。
- Dart 提交前运行 `dart format .`、`flutter analyze`、`flutter test`。
- 新功能按 feature 划分目录；网络和存储代码不要直接写进 Widget。
- 提交信息使用 Conventional Commits，例如 `feat: add archive detail page`。

## 安全

- 仅提交 `.env.example`，不得提交 `.env`。
- App 内 Agent 默认只启用六爻领域 Tools，不开放通用文件、Shell 或写文件工具。
- `liuyao_create_case` 与 `liuyao_append_analysis` 是持久化写操作，Tool 描述和系统提示必须要求用户明确授权。
