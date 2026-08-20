import 'casting_models.dart';
import 'package:liuyao_engine/liuyao_engine.dart' as engine;

/// 离线排盘数据源（100% 纯 Dart 实现，无需后端服务）。
abstract class CastingDataSource {
  Future<CastPreview> previewManual({
    required String question,
    required DateTime dateTime,
    required List<int> lineValues,
    String dayBoundary = engine.dayBoundaryCivil23NextDay,
    String monthBoundary = engine.monthBoundarySolarTermZiHour,
  });

  Future<CastPreview> previewAutomatic({
    required String question,
    required DateTime dateTime,
    Object? seed,
    String dayBoundary = engine.dayBoundaryCivil23NextDay,
    String monthBoundary = engine.monthBoundarySolarTermZiHour,
  });

  Future<CastPreview> previewTimePillar({
    required String question,
    required DateTime dateTime,
    String dayBoundary = engine.dayBoundaryCivil23NextDay,
    String monthBoundary = engine.monthBoundarySolarTermZiHour,
  });

  void close();
}

class CastingClient implements CastingDataSource {
  CastingClient();

  @override
  Future<CastPreview> previewManual({
    required String question,
    required DateTime dateTime,
    required List<int> lineValues,
    String dayBoundary = engine.dayBoundaryCivil23NextDay,
    String monthBoundary = engine.monthBoundarySolarTermZiHour,
  }) async {
    if (lineValues.length != 6 ||
        lineValues.any((value) => !const {6, 7, 8, 9}.contains(value))) {
      throw ArgumentError.value(lineValues, 'lineValues', '必须包含六个 6/7/8/9');
    }
    return CastPreview.fromEngineResult(
      engine.manualCast(
        dateTime,
        lineValues,
        dayBoundary: dayBoundary,
        monthBoundary: monthBoundary,
      ),
      question: question,
    );
  }

  @override
  Future<CastPreview> previewAutomatic({
    required String question,
    required DateTime dateTime,
    Object? seed,
    String dayBoundary = engine.dayBoundaryCivil23NextDay,
    String monthBoundary = engine.monthBoundarySolarTermZiHour,
  }) async {
    return CastPreview.fromEngineResult(
      engine.autoCast(
        dateTime,
        seed: seed is int ? seed : null,
        dayBoundary: dayBoundary,
        monthBoundary: monthBoundary,
      ),
      question: question,
    );
  }

  @override
  Future<CastPreview> previewTimePillar({
    required String question,
    required DateTime dateTime,
    String dayBoundary = engine.dayBoundaryCivil23NextDay,
    String monthBoundary = engine.monthBoundarySolarTermZiHour,
  }) async {
    return CastPreview.fromEngineResult(
      engine.timePillarCast(
        dateTime,
        dayBoundary: dayBoundary,
        monthBoundary: monthBoundary,
      ),
      question: question,
    );
  }

  @override
  void close() {}
}
