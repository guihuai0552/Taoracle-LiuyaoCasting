import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 解读编辑草稿（2026-09-05 需求）：详情页解读输入框的未保存文本
/// 实时落盘，意外退出（误触返回、切页、应用被杀）后再次进入时自动恢复。
///
/// 设计要点：
/// - 草稿是尽力而为的保护层：所有 IO 失败均静默，绝不阻塞编辑；
/// - 保存解读成功或清空文本时删除草稿，避免陈旧草稿覆盖已保存内容；
/// - [draftDirectoryOverride] 供测试注入临时目录，与 ArchiveClient 同模式。
Future<Directory> Function()? draftDirectoryOverride;

Directory? _cachedDir;

Future<File> _draftFile(String caseId) async {
  final dir = _cachedDir ??= await (draftDirectoryOverride != null
      ? draftDirectoryOverride!()
      : getApplicationDocumentsDirectory());
  // caseId 只作文件名：过滤到安全字符集，杜绝路径拼接意外。
  final safe = caseId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  return File('${dir.path}/draft-analysis-$safe.txt');
}

/// 写入草稿；空文本等价于清除草稿。
Future<void> saveAnalysisDraft(String caseId, String text) async {
  try {
    final file = await _draftFile(caseId);
    if (text.trim().isEmpty) {
      if (await file.exists()) await file.delete();
      return;
    }
    await file.parent.create(recursive: true);
    await file.writeAsString(text, flush: true);
  } catch (_) {
    // 写盘失败不影响编辑；下次保存仍有 PopScope 确认兜底。
  }
}

/// 读取草稿；无草稿或读取失败返回空串。
Future<String> loadAnalysisDraft(String caseId) async {
  try {
    final file = await _draftFile(caseId);
    if (!await file.exists()) return '';
    return await file.readAsString();
  } catch (_) {
    return '';
  }
}

/// 测试辅助：重置目录缓存。
@visibleForTesting
void resetDraftCacheForTest() {
  _cachedDir = null;
}
