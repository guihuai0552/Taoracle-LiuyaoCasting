import 'dart:convert';
import 'dart:io';

import 'archive_models.dart';

class ArchiveClient {
  ArchiveClient({String? baseUrl, HttpClient? httpClient})
    : baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'AGENT_BASE_URL',
            defaultValue: 'http://10.0.2.2:8787',
          ),
      _httpClient = httpClient ?? HttpClient();

  final String baseUrl;
  final HttpClient _httpClient;

  Future<List<CaseSummary>> listCases() async {
    final json = await _request('GET', '/api/cases') as List<dynamic>;
    return json
        .map((item) => CaseSummary.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<CaseDetail> createCase({
    required String title,
    required String question,
    required DateTime timestamp,
    required bool manual,
    List<int>? lineValues,
  }) async {
    final json = await _request(
      'POST',
      '/api/cases',
      body: {
        'title': title,
        'question': question,
        'timestamp': _rfc3339WithOffset(timestamp),
        'castingMethod': manual ? 'manual' : 'three_coins',
        'lineValues': ?lineValues,
      },
    );
    return CaseDetail.fromJson(json as Map<String, dynamic>);
  }

  Future<CaseDetail> getCase(String id) async {
    final json = await _request('GET', '/api/cases/${Uri.encodeComponent(id)}');
    return CaseDetail.fromJson(json as Map<String, dynamic>);
  }

  Future<void> appendUserAnalysis({
    required String caseId,
    required String body,
    required int expectedRevision,
  }) async {
    await _request(
      'POST',
      '/api/cases/${Uri.encodeComponent(caseId)}/analyses',
      body: {
        'author': 'user',
        'body': body,
        'expectedRevision': expectedRevision,
      },
    );
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = method == 'GET'
        ? await _httpClient.getUrl(uri)
        : await _httpClient.postUrl(uri);
    request.headers.contentType = ContentType.json;
    if (body != null) request.write(jsonEncode(body));
    final response = await request.close();
    final responseBody = await utf8.decoder.bind(response).join();
    final decoded = responseBody.isEmpty ? null : jsonDecode(responseBody);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error'] as String? ?? '请求失败'
          : '请求失败：${response.statusCode}';
      throw HttpException(message, uri: uri);
    }
    return decoded;
  }

  String _rfc3339WithOffset(DateTime value) {
    if (value.isUtc) return value.toIso8601String();
    final offset = value.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '${value.toIso8601String()}$sign$hours:$minutes';
  }

  void close() => _httpClient.close(force: true);
}
