# 六爻存档 Flutter 客户端

客户端完全离线运行，通过本地路径依赖 `../../packages/liuyao_engine` 计算万年历与六爻，不读取服务地址，不发起网络请求。

```bash
flutter pub get
dart analyze
flutter test
flutter run
```

生产 Manifest 不申请网络权限。`src/debug` 与 `src/profile` 中的 INTERNET 仅供 Flutter 热重载/调试，不会进入 release APK。

档案保存在应用私有 Documents 目录的 `liuyao_archive.json`。文件采用带版本号的容器、临时文件原子替换和显式错误上报；应用卸载前一直保留。详情页可导出 Markdown、JSON 或完整 PNG 长图；档案页可批量导出/导入含全部卦面、解读和反馈的迁移包。

UI 使用项目自有的新中式 Design System：宣纸 `#F5F0E6`、内容纸 `#F8F4E8`、墨色 `#1C1C1C` 与朱砂 `#B22222`。窗棂纹样只出现在页面边角和留白区，高密度卦面保持纯纸面；档案和卦面实机参考见 `design/mobile-wireframes/review/v0.2/implementation/`。
