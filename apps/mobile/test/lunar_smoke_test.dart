import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao_engine/liuyao_engine.dart';

void main() {
  group('solarToLunar', () {
    test('2024-02-10 应为正月初一（春节）', () {
      final r = solarToLunar(DateTime(2024, 2, 10));
      expect(r.month, 1);
      expect(r.day, 1, reason: '春节应是初一，实际 day=${r.day}');
      expect(r.isLeapMonth, false);
      expect(r.dayCn, '初一');
      expect(r.yearCn, '二零二四');
      expect(r.zodiac, '龙');
    });

    test('2024-03-15 应为农历二月初六', () {
      final r = solarToLunar(DateTime(2024, 3, 15));
      expect(r.month, 2, reason: '应为二月，实际 month=${r.month}');
      expect(r.day, 6, reason: '应为初六，实际 day=${r.day}');
    });

    test('2025-01-29 应为正月初一（2025春节）', () {
      final r = solarToLunar(DateTime(2025, 1, 29));
      expect(r.month, 1);
      expect(r.day, 1, reason: '2025春节应是初一，实际 day=${r.day}');
      expect(r.yearCn, '二零二五');
      expect(r.zodiac, '蛇');
    });

    test('2026-02-17 应为正月初一（2026春节）', () {
      final r = solarToLunar(DateTime(2026, 2, 17));
      expect(r.month, 1);
      expect(r.day, 1, reason: '2026春节应是初一，实际 day=${r.day}');
    });

    test('2000-02-05 应为正月初一（2000春节）', () {
      final r = solarToLunar(DateTime(2000, 2, 5));
      expect(r.month, 1);
      expect(r.day, 1, reason: '2000春节应是初一，实际 day=${r.day}');
      expect(r.zodiac, '龙');
    });

    test('中秋 2024-09-17 应为八月十五', () {
      final r = solarToLunar(DateTime(2024, 9, 17));
      expect(r.month, 8, reason: '应为八月，实际 month=${r.month}');
      expect(r.day, 15, reason: '应为十五，实际 day=${r.day}');
    });

    test('端午 2024-06-10 应为五月初五', () {
      final r = solarToLunar(DateTime(2024, 6, 10));
      expect(r.month, 5);
      expect(r.day, 5);
    });
  });
}
