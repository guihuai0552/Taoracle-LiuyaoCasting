import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao_archive/src/ui/design_system/components/liuyao_icon.dart';

/// v1.0 图标系统：全部 SVG 资源可随包加载、组件可渲染、选中态切换信号色。
void main() {
  testWidgets('每个图标类型都有可加载的 SVG 资源', (tester) async {
    for (final type in LiuyaoIconType.values) {
      await tester.pumpWidget(TestableIcon(icon: type, selected: false));
      expect(tester.takeException(), isNull, reason: '${type.path} 渲染失败');
    }
  });

  testWidgets('选中态切换为蓝灰信号色不报错', (tester) async {
    await tester.pumpWidget(
      const TestableIcon(icon: LiuyaoIconType.divination, selected: true),
    );
    expect(tester.takeException(), isNull);
  });
}

class TestableIcon extends StatelessWidget {
  const TestableIcon({super.key, required this.icon, required this.selected});

  final LiuyaoIconType icon;
  final bool selected;

  @override
  Widget build(BuildContext context) =>
      LiuyaoIcon(icon, size: 24, selected: selected);
}
