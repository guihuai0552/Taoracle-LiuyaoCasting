import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao_engine/liuyao_engine.dart';

void main() {
  group('六神算法对齐测试', () {
    test('十日干起六神均与固定表一致', () {
      expect(calculateSixGods('甲'), ['青龙', '朱雀', '勾陈', '螣蛇', '白虎', '玄武']);
      expect(calculateSixGods('戊').first, '勾陈');
      expect(calculateSixGods('己').first, '螣蛇');
      expect(calculateSixGods('癸').first, '玄武');
    });
  });

  group('六亲算法对齐测试', () {
    test('乾金宫与五行生克', () {
      expect(calculateRelation('金', '金'), '兄弟');
      expect(calculateRelation('金', '水'), '子孙');
      expect(calculateRelation('金', '土'), '父母');
      expect(calculateRelation('金', '木'), '妻财');
      expect(calculateRelation('金', '火'), '官鬼');
    });
  });

  group('世应定位对齐测试', () {
    test('八纯与一世卦', () {
      final pure = calculateShiYing('111111');
      expect((pure.shi, pure.ying, pure.palaceSequence), (6, 3, 1));

      final first = calculateShiYing('011111');
      expect((first.shi, first.ying, first.palaceSequence), (1, 4, 2));
    });
  });
}
