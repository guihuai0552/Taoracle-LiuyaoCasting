# 第三方许可声明

## OPN48/cnlunar

- 来源：https://github.com/OPN48/cnlunar
- 精确提交：`8a944ada2f174c350a9fa69057597ecae5eb76be`
- 许可证：MIT
- 上游版权：Copyright (c) 2025 OPN48
- 上游跟踪：本项目通过 fork [guihuai0552/cnlunar-](https://github.com/guihuai0552/cnlunar-) 跟踪上游变更（Python 对照服务锁定 PyPI `cnlunar==0.2.0`）

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

## 6tail/lunar-python

- 来源：https://github.com/6tail/lunar-python
- 对照版本：`1.4.8`
- 许可证：MIT

本包内 `exact_jie_terms.dart` 的 1901–2099 精确交节时间由该固定版本生成。生成器与
输出 revision 均纳入仓库，以便升级依赖时重新生成和复核；运行时不包含 Python 代码。
