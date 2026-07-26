import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao_archive/src/app.dart';

void main() {
  testWidgets('shows the archive empty state', (tester) async {
    await tester.pumpWidget(const LiuyaoArchiveApp());
    await tester.pump();

    expect(find.text('六爻存档'), findsWidgets);
    expect(find.text('把每一次占问留下来'), findsOneWidget);
    expect(find.text('新建第一条记录'), findsOneWidget);
  });

  testWidgets('switches to the agent page', (tester) async {
    await tester.pumpWidget(const LiuyaoArchiveApp());
    await tester.tap(find.text('助手'));
    await tester.pump();

    expect(find.text('存档助手'), findsOneWidget);
    expect(find.text('Pi 驱动的存档助手'), findsOneWidget);
  });
}
