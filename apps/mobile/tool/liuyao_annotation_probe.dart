import 'dart:convert';
import 'dart:io';

import 'package:liuyao_engine/liuyao_engine.dart';

Future<void> main() async {
  final raw = await stdin.transform(utf8.decoder).join();
  final inputs = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  final output = <Map<String, dynamic>>[];
  for (final input in inputs) {
    final values = (input['line_values'] as List).cast<int>();
    final pillars = (input['pillars'] as Map).map(
      (key, value) =>
          MapEntry(key as String, (value as Map).cast<String, String>()),
    );
    final chart = buildBaseChart(values, pillars);
    final lines = (chart['base']['lines'] as List).cast<Map<String, dynamic>>();
    final stages = buildFiveElementTwelveStages(lines, pillars);
    final day = pillars['day']!;
    final luShen = buildLuShen(lines, day);
    final tianYi = buildTianYi(lines, day);
    final yiMa = buildYiMa(lines, day);
    final taoHua = buildTaoHua(lines, day);
    final jiangXing = buildJiangXing(lines, day);
    final huaGai = buildHuaGai(lines, day);
    output.add({
      'rule_packages': [
        annotationRulePackage(),
        luShenRulePackage(),
        tianYiRulePackage(),
        yiMaRulePackage(),
        taoHuaRulePackage(),
        jiangXingRulePackage(),
        huaGaiRulePackage(),
      ],
      'five_element_twelve_stages': stages['object'],
      'shensha': {
        'catalog_version': '1.0.0',
        'results': [
          luShen.result,
          tianYi.result,
          yiMa.result,
          taoHua.result,
          jiangXing.result,
          huaGai.result,
        ],
      },
    });
  }
  stdout.write(jsonEncode(output));
}
