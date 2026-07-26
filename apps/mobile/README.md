# 六爻存档 Flutter 客户端

## 启动

```bash
flutter emulators --launch liuyao_api36
flutter run
```

默认 Agent 地址为 Android 模拟器可访问的 `http://10.0.2.2:8787`。覆盖地址：

```bash
flutter run --dart-define=AGENT_BASE_URL=http://<host>:8787
```

## 检查

```bash
dart format lib test
dart analyze
flutter test
flutter build apk --debug
```
