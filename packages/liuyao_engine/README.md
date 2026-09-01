# liuyao_engine

`liuyao_engine` 是不依赖 Flutter、网络或服务端的纯 Dart 六爻排盘轮子。

当前稳定合同为 schema v16，包含：

- 手动与三枚铜钱起卦，爻序固定为初爻到上爻；
- 本卦、变卦、八宫、各自独立的世应、纳甲、六亲、六神；
- 按内外卦匹配宫卦/错卦规则排出的完整六爻伏卦与伏神；
- 本卦、完整伏卦、变卦三层四土本气五行十二长生，驿马、桃花、禄神、华盖、天乙贵人五项神煞，以及卦身、命爻两项辅助结构；
- 分别按本卦、完整伏卦、变卦自身卦宫与世应计算的京房六十四卦配二十八宿；
- 1901-02-19 至 2100-02-08 的 cnlunar 万年历，以及 1901–2099 精确到秒的立春换年、
  十二节换月、四柱、纳音、旬空、13 时辰、值日宿、节气和财神方位；
- 对 `liuyao-private@6ca3d3e` 可逐字段验证的 `private_reference_contract`，包括机械关系、
  缺失六亲伏神、五项神煞候选与身类标记；
- 可随存档保存的完整 `calculation_trace`。

```dart
import 'package:liuyao_engine/liuyao_engine.dart';

final chart = manualCast(
  DateTime.parse('2026-08-04T22:22:29+08:00'),
  [7, 7, 9, 8, 8, 7],
);
```

规则依据、冲突决策、伏卦与二十八宿说明、跨语言验证方法由主仓库 `docs/` 维护。私有
副本只作为 C 级可执行对照；它未实现的其余神煞和天文五星不会被臆造。

私有参考对照脚本 `scripts/check_private_reference_dart_parity.py` 依赖仓库外维护的本
地 `liuyao-private` 副本环境，不随开源仓库提供；外部使用者可运行其余三条公开 parity
门禁。

当前包尚未发布到 pub.dev；待项目所有者确认本项目自身的开源许可证和正式仓库地址后再解除
`publish_to: none`。其中 cnlunar 移植内容精确锚定上游提交
`8a944ada2f174c350a9fa69057597ecae5eb76be`：该提交相对 `v0.2.0` 只把上游许可证
改为 MIT，算法与数据文件没有变化。第三方许可见 `THIRD_PARTY_NOTICES.md`。
