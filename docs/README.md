# 六爻排盘与存档产品文档中心

> 文档状态：`Active`  
> 最近更新：2026-08-07  
> 当前阶段：完全离线审阅 APK 已构建、验权、安装并启动；等待用户体验审阅

这里是项目的单一上下文入口（Single Source of Truth）。后续需求变更、规则争议、设计结论、实现偏差和验收结果，都必须回写到这里所列文档，不能只停留在聊天记录或代码注释里。

## 1. 产品定位

产品由三个核心模块组成：

1. **万年历**：提供排卦所需的时间历法上下文，也作为独立可浏览功能。
2. **六爻工具**：支持多种起卦方式，生成完整、可追溯的六爻卦面。
3. **案例档案**：保存占问、卦面、规则标注、解读、反馈和导出快照。

当前明确不做：Agent、其他术数工具、未完成来源核验的其余神煞与五星入卦。用户确认的京房六十四卦配二十八宿规则已经作为注解实现；私有副本的值日宿作为万年历独立字段，二者不混用。“五星入卦”仍是后续独立范围。

## 2. 文档地图

### 产品层

- [产品需求文档 PRD](./product/PRD.md)：用户、目标、信息架构、主流程和版本边界。
- [参考产品 UI 对标记录](./product/ui-benchmark-lingguang-xiangji.md)：只记录可核实的界面证据和可借鉴的交互原则；名称不作为开发前置条件。
- [UI 参考图证据清单](./assets/ui-reference/README.md)：保存截图编号、原始文件名、校验值、替代文本和证据限制。

### 规则知识层

- [六爻规则与实施路线](./liuyao-rule-roadmap.md)：五行十二长生、神煞目录、规则分层和待确认项。
- [现有六爻工具技术计划](./liuyao-chart-tool-plan.md)：现有代码审计、数据契约和初步里程碑，作为技术研究输入。
- [规则来源登记表](./rules/source-register.md)：所有历法和六爻规则的版本、出处、流派、可信度与冲突处理。
- [项目术语表](./rules/glossary.md)：统一排盘、起卦、本伏、值日宿和入卦等核心名词。
- [cnlunar 技术基线评估](./rules/cnlunar-adoption.md)：万年历开源基础、能力映射、适配边界、许可和测试要求。
- [六爻基础卦面规则审计](./rules/base-chart-rule-audit.md)：Najia 2.0.1 精确实现基线、三方差异、schema v3 规则与已知边界。
- [`liuyao-private` 纯 Dart 移植与规则审计](./rules/liuyao-private-dart-port-audit.md)：固定提交、模块覆盖、冲突决策与完整 parity 证据。
- [六爻八宫与伏卦排法](./rules/fu-gua-rule.md)：可独立公开分享的八宫分类、错卦映射、伏卦生成、伏神纳甲规则与固定案例。
- [京房六十四卦配二十八宿规则](./rules/jingfang-28-mansions-rule.md)：二十八宿循环、64 卦世爻宿、六爻装配算法、固定样例及待确认冲突。
- [SPEC-004 规则来源与实现状态审计](./rules/spec-004-source-audit.md)：五行十二长生依据、20 项名称/异法/输入域矩阵及逐项开发门禁。

### 功能规格层

- [Spec 模板](./specs/_template.md)
- [Spec 范围与数据归属矩阵](./specs/scope-matrix.md)
- [SPEC-001 万年历](./specs/SPEC-001-almanac.md)
- [SPEC-002 起卦模式](./specs/SPEC-002-casting-modes.md)
- [SPEC-003 六爻卦面](./specs/SPEC-003-chart.md)
- [SPEC-004 十二长生与神煞](./specs/SPEC-004-rule-annotations.md)
- [SPEC-005 案例、解读与反馈](./specs/SPEC-005-case-archive.md)
- [SPEC-006 档案导出](./specs/SPEC-006-export.md)
- [SPEC-007 UI 与导航](./specs/SPEC-007-ui-system.md)
- [SPEC-008 二十八宿](./specs/SPEC-008-twenty-eight-mansions.md)

### 项目治理层

- [总工作计划](./plans/master-plan.md)：从知识准备、规格冻结到后续开发验收的完整路线。
- [ADR-0001 文档优先与单一事实源](./decisions/ADR-0001-document-first.md)
- [决策日志](./decisions/decision-log.md)
- [开放问题台账](./project/open-questions.md)
- [文档变更日志](./project/change-log.md)
- [完全离线 Dart 架构](./architecture/offline-dart-architecture.md)：生产运行边界、独立轮子、档案格式、交叉校验与断网发布门禁。
- [档案迁移格式 v1](./architecture/archive-transfer-format.md)：批量包字段、完整性保证、预检与冲突策略。
- [离线 APK 对齐状态](./OFFLINE_APK_ALIGNMENT_STATUS.md)：当前实现证据与发布前剩余动作。
- [移动端线框总画板](../design/mobile-wireframes/00-master-board.svg)：v0.2 全项目页面、流程与宣纸水墨视觉候选；04A 已按第二轮意见重画。
- [移动端 Design System](../design/mobile-wireframes/DESIGN.md)：颜色、字体、栅格、羊皮纸卷和核心组件规范。

## 3. 文档状态

| 状态 | 含义 | 是否允许据此开发 |
|---|---|---|
| `Draft` | 已有结构，仍缺规则、原型或关键决定 | 否 |
| `In Progress` | 用户已授权一个明确切片进入实现，未完成部分继续保持开放 | 仅限已登记切片 |
| `In Review` | 内容齐全，正在交叉检查 | 否 |
| `Ready` | 范围、规则、界面和验收均已确认 | 是 |
| `Implemented` | 已按冻结版本实现并通过验收 | 是 |
| `Superseded` | 已被新文档取代，仅保留历史 | 否 |

用户已授权按依赖顺序逐项开发。SPEC-001/002/003 的首版计算与 UI 已实现，并由独立 Dart 包承担生产运算；schema v16 已加入私有参考合同、精确交节、逐爻纳音、本伏变三层四土本气十二长生与京房二十八宿，以及本变卦各自世应。SPEC-004 当前固定为五项产品神煞和卦身/命爻两项辅助结构，其余保持开放；五星入卦仍未实施。SPEC-005/006 已实现自动快照存档、搜索/详情、解读版本、反馈、Markdown/JSON/PNG 单档导出及完整批量迁移。标签/归档、PDF、草稿恢复、其余神煞与五星入卦仍按开放问题管理。

## 4. 每次变更的同步规则

每次讨论或开发产生结论时，按以下顺序更新：

1. 更新受影响的 PRD、规则文档或功能 Spec 正文。
2. 在 [决策日志](./decisions/decision-log.md) 记录“决定了什么、为什么、影响哪些 Spec”。
3. 尚未解决的问题写入 [开放问题台账](./project/open-questions.md)，不得藏在正文 TODO 中。
4. 在 [文档变更日志](./project/change-log.md) 写一条摘要并链接受影响文档。
5. 若已进入开发，再同步数据契约、测试样例和实现状态。

实施过程中一旦发现既有爻位、交互或传统规则需要调整，应在同一个工作节点同步更新相关 Spec、开放问题或决策日志和本变更日志，不能等功能全部完成后再补文档。

## 5. Spec 进入开发前的门槛

一个 Spec 只有同时满足以下条件才能从 `Draft` 变为 `Ready`：

- 范围内与范围外清晰，且与其他 Spec 不重叠。
- 输入、输出、数据字段、空状态、错误状态和边界条件齐全。
- 每条传统规则都有出处、采用口径和至少一个固定样例。
- UI 有页面结构、核心状态和交互说明；涉及对标时有截图编号或来源链接。
- 验收标准可测试，算法功能有 golden case。
- 相关开放问题已经关闭，或明确标记为不阻塞当前版本。
- 用户确认 Spec 版本。

## 6. 当前最高优先级

1. 审阅万年历、手动/自动起卦、基础卦面、自动存档、解读、反馈和导出完整路径。
2. 把审阅问题实时写回 Spec、决策/问题台账与变更日志。
3. 正式分发前确定产品名、应用 ID、release keystore 和本项目自身开源许可证。
4. 其余神煞与五星入卦保持暂停，只有用户重新授权后才进入实现。
