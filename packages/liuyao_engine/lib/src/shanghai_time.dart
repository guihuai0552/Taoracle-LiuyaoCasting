/// Asia/Shanghai 在 1901—2100 支持区间内的 UTC 偏移变更。
///
/// 规则层不能依赖 Android 厂商是否打包完整 tzdata，因此把 IANA
/// Asia/Shanghai 的 28 个转换点冻结在纯 Dart 轮子中。转换点均为 UTC。

library;

const List<({int year, int month, int day, int hour, int afterHours})>
_transitions = [
  (year: 1919, month: 4, day: 12, hour: 16, afterHours: 9),
  (year: 1919, month: 9, day: 30, hour: 15, afterHours: 8),
  (year: 1940, month: 5, day: 31, hour: 16, afterHours: 9),
  (year: 1940, month: 10, day: 12, hour: 15, afterHours: 8),
  (year: 1941, month: 3, day: 14, hour: 16, afterHours: 9),
  (year: 1941, month: 11, day: 1, hour: 15, afterHours: 8),
  (year: 1942, month: 1, day: 30, hour: 16, afterHours: 9),
  (year: 1945, month: 9, day: 1, hour: 15, afterHours: 8),
  (year: 1946, month: 5, day: 14, hour: 16, afterHours: 9),
  (year: 1946, month: 9, day: 30, hour: 15, afterHours: 8),
  (year: 1947, month: 4, day: 14, hour: 16, afterHours: 9),
  (year: 1947, month: 10, day: 31, hour: 15, afterHours: 8),
  (year: 1948, month: 4, day: 30, hour: 16, afterHours: 9),
  (year: 1948, month: 9, day: 30, hour: 15, afterHours: 8),
  (year: 1949, month: 4, day: 30, hour: 16, afterHours: 9),
  (year: 1949, month: 5, day: 27, hour: 15, afterHours: 8),
  (year: 1986, month: 5, day: 3, hour: 18, afterHours: 9),
  (year: 1986, month: 9, day: 13, hour: 17, afterHours: 8),
  (year: 1987, month: 4, day: 11, hour: 18, afterHours: 9),
  (year: 1987, month: 9, day: 12, hour: 17, afterHours: 8),
  (year: 1988, month: 4, day: 16, hour: 18, afterHours: 9),
  (year: 1988, month: 9, day: 10, hour: 17, afterHours: 8),
  (year: 1989, month: 4, day: 15, hour: 18, afterHours: 9),
  (year: 1989, month: 9, day: 16, hour: 17, afterHours: 8),
  (year: 1990, month: 4, day: 14, hour: 18, afterHours: 9),
  (year: 1990, month: 9, day: 15, hour: 17, afterHours: 8),
  (year: 1991, month: 4, day: 13, hour: 18, afterHours: 9),
  (year: 1991, month: 9, day: 14, hour: 17, afterHours: 8),
];

int shanghaiOffsetHoursAt(DateTime utcInstant) {
  final instant = utcInstant.toUtc();
  var offset = 8;
  for (final transition in _transitions) {
    final at = DateTime.utc(
      transition.year,
      transition.month,
      transition.day,
      transition.hour,
    );
    if (instant.isBefore(at)) break;
    offset = transition.afterHours;
  }
  return offset;
}

/// 把带 offset 的瞬间或无 offset 的用户墙上时间转换为上海墙上时间。
/// 返回 UTC 标记的 DateTime，仅借其稳定的年月日时字段，不代表 UTC 时刻。
DateTime toShanghaiWallClock(DateTime input) {
  final instant = input.isUtc
      ? input
      : DateTime.utc(
          input.year,
          input.month,
          input.day,
          input.hour,
          input.minute,
          input.second,
          input.millisecond,
          input.microsecond,
        ).subtract(const Duration(hours: 8));
  return instant.toUtc().add(Duration(hours: shanghaiOffsetHoursAt(instant)));
}

/// Convert an Asia/Shanghai wall-clock value back to its UTC instant.
///
/// The input's UTC/local flag is ignored; only its visible fields are used.
/// This is needed for historical exact-Jie fixtures because Shanghai used
/// daylight-saving offsets during several periods from 1919 through 1991.
DateTime shanghaiWallClockToUtc(DateTime wallClock) {
  final wallAsUtc = DateTime.utc(
    wallClock.year,
    wallClock.month,
    wallClock.day,
    wallClock.hour,
    wallClock.minute,
    wallClock.second,
    wallClock.millisecond,
    wallClock.microsecond,
  );
  var candidate = wallAsUtc.subtract(const Duration(hours: 8));
  final offset = shanghaiOffsetHoursAt(candidate);
  candidate = wallAsUtc.subtract(Duration(hours: offset));
  return candidate;
}

String _formatWithOffset(DateTime wallClock, int offsetHours) {
  String two(int value) => value.toString().padLeft(2, '0');
  final sign = offsetHours < 0 ? '-' : '+';
  final absolute = offsetHours.abs();
  return '${wallClock.year.toString().padLeft(4, '0')}-'
      '${two(wallClock.month)}-${two(wallClock.day)}T'
      '${two(wallClock.hour)}:${two(wallClock.minute)}:${two(wallClock.second)}'
      '$sign${two(absolute)}:00';
}

/// Serialize an instant with the historical Asia/Shanghai UTC offset.
String formatShanghaiInstantIso(DateTime input) {
  final instant = input.isUtc ? input.toUtc() : shanghaiWallClockToUtc(input);
  final offset = shanghaiOffsetHoursAt(instant);
  final wallClock = instant.add(Duration(hours: offset));
  return _formatWithOffset(wallClock, offset);
}

/// Serialize a DateTime whose visible fields are already a Shanghai wall clock.
String formatShanghaiWallClockIso(DateTime wallClock) {
  final instant = shanghaiWallClockToUtc(wallClock);
  return _formatWithOffset(wallClock, shanghaiOffsetHoursAt(instant));
}
