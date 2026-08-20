import 'dart:convert';
import 'dart:io';

import 'package:liuyao_engine/liuyao_engine.dart';

Future<void> main() async {
  final raw = await stdin.transform(utf8.decoder).join();
  final inputs = (jsonDecode(raw) as List).cast<String>();
  final output = <Map<String, dynamic>>[];
  for (final input in inputs) {
    final date = DateTime.parse(input);
    final value = calculateAlmanac(date);
    output.add({
      'input': input,
      'lunar': value['lunar'],
      'four_pillars': value['four_pillars'],
      'two_hour_pillars': value['two_hour_pillars'],
      'current_two_hour_index': value['current_two_hour_index'],
      'solar_terms': value['solar_terms'],
      'wealth_god': value['wealth_god'],
    });
  }
  stdout.write(jsonEncode(output));
}
