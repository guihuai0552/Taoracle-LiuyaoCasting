# 第三方许可声明

## OPN48/cnlunar

- 来源：https://github.com/OPN48/cnlunar
- 精确提交：`8a944ada2f174c350a9fa69057597ecae5eb76be`
- 许可证：MIT
- 上游版权：Copyright (c) 2025 OPN48

本包的农历月数据、二十四节气数据和相关历法算法以该提交为移植基线。该提交相对
`v0.2.0` 标签只修改了 `LICENSE`，算法与数据文件没有变化。

MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Najia

- 来源：https://github.com/kentang2017/najia
- 对照版本：tag `v2.0.1`，commit `c67a539...`
- 许可证：MIT

本包未在运行时依赖 Python Najia；其固定输出用于基础纳甲规则的对照和回归测试。正式独立
发布前，应将 Najia 上游完整 MIT 声明与精确完整 commit 一并纳入发布清单。

## 6tail/lunar-python

- 来源：https://github.com/6tail/lunar-python
- 对照版本：`1.4.8`
- 许可证：MIT

本包内 `exact_jie_terms.dart` 的 1901–2099 精确交节时间由该固定版本生成。生成器与
输出 revision 均纳入仓库，以便升级依赖时重新生成和复核；运行时不包含 Python 代码。

## 用户提供的 `liuyao-private`

- 私有来源：仓库外维护的 `liuyao-private` 本地副本（通过 `LIUYAO_PRIVATE_ROOT` 环境变量指定）
- 精确提交：`6ca3d3e`
- 仓库声明许可证：MIT

本包将其可执行六爻规则重新实现为 Dart，并以逐字段 parity 测试验证。该来源是程序行为
基线，不代表对规则史或流派的权威判断。正式向第三方分发前，项目所有者仍需确认该私有
副本中所有代码和数据的再许可权，并把完整版权声明纳入发布物。

《五行大义》和香港天文台资料只用于规则与历法交叉校验，不复制其程序代码或数据文件。
