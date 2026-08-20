# v0.2 审阅说明

直接预览：[04A-preview-v0.2.png](./04A-preview-v0.2.png)  
本轮固定快照：[master-board-v0.2.svg](./master-board-v0.2.svg)

Flutter 实机实现：[万年历](./implementation/calendar.png) / [手动起卦](./implementation/manual-casting.png) / [档案](./implementation/archive.png) / [04A 卦面](./implementation/04A-hexagram-detail.png) / [设置](./implementation/settings.png)

## 本轮反馈

| 反馈编号 | 原问题 | v0.2 处理 | 状态 |
|---|---|---|---|
| R-04A-01 | 04A 整体排版没有学习新卦面截图 | 改为占问、十二摘要、神煞摘要、四柱及六爻大卡的垂直层级 | 已修复，待评审 |
| R-04A-02 | 卦内信息排布需要按逐爻主副字号图 | 伏神/本卦/变卦均为大主行+小副行；本变爻象同行，世应/动爻独立居中 | 已修复，待评审 |
| R-G-01 | 中式网格颜色不好看，偏脏偏黄 | 改为 `#F5F0E6` 宣纸底、`#1C1C1C` 真墨、`#3A3A3A` 中墨、`#D0D0D0` 淡墨、`#B22222` 朱砂；网格降至 8%–12% | 已修复，待评审 |

## 审阅重点

1. 04A 中“十二 / 神煞 / 卦面大卡”的垂直顺序是否正确。
2. 六行中的伏神、本卦、变卦是否已经能一眼横向对照。
3. 宣纸底、墨色与朱砂的强度是否达到“克制新中式”，网格是否已退到边界装饰。

本轮已完成 Flutter 审阅实现；仍暂不审阅最终品牌名、纸张位图和动效。视觉确认后再进入 `formal/`。
