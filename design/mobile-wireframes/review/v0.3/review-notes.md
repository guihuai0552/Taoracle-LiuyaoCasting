# v0.3 档案迁移与图片导出审阅

> 日期：2026-08-07  
> 状态：Flutter 实现候选，等待用户审阅

## 本轮范围

- 档案页右上“迁移”入口与当前档案总数。
- 批量导出全部档案、原生文件选择器导入。
- 导入预检：档案、新增、相同、冲突、解读、反馈六项计数。
- 安全合并与清空恢复的主次层级、风险说明和二次确认。
- 单档 Markdown、JSON、PNG 长图三个导出选项。

## 视觉规则

- 继续沿用 v0.2 宣纸、真墨和朱砂 token，不建立第二套视觉语言。
- 安全合并作为推荐主操作；不可撤销的清空恢复使用描边按钮并增加二次确认。
- 迁移包和图片均明确包含完整解读与反馈；私人内容提示保持可见。
- 弹层允许纵向滚动，兼容较小屏幕和系统字体放大。

## 实机证据

- `implementation/archive-migration-entry.png`
- `implementation/archive-migration-sheet.png`
- `implementation/archive-import-preview.png`
- `implementation/case-export-options.png`
- `implementation/case-export-image.png`

本轮只新增迁移和导出信息架构，不改变档案卡和六爻账页的 v0.2 排布基线。
