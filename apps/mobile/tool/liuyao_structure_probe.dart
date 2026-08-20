import 'dart:convert';
import 'dart:io';

import 'package:liuyao_engine/liuyao_engine.dart';

Future<void> main() async {
  final raw = await stdin.transform(utf8.decoder).join();
  final inputs = (jsonDecode(raw) as List)
      .map((item) => (item as List).cast<int>())
      .toList(growable: false);
  const pillars = <String, Map<String, String>>{
    'year': {'gan_zhi': '丙午', 'stem': '丙', 'branch': '午'},
    'month': {'gan_zhi': '乙未', 'stem': '乙', 'branch': '未'},
    'day': {'gan_zhi': '甲子', 'stem': '甲', 'branch': '子'},
    'hour': {'gan_zhi': '乙丑', 'stem': '乙', 'branch': '丑'},
  };
  final output = <Map<String, dynamic>>[];
  for (final values in inputs) {
    final chart = buildBaseChart(values, pillars);
    final mansion = buildTwentyEightMansions(
      chart['base'] as Map<String, dynamic>,
    );
    output.add({
      'line_values': values,
      'hexagram': chart,
      'twenty_eight_mansions': mansion.result,
    });
  }
  stdout.write(jsonEncode(output));
}
