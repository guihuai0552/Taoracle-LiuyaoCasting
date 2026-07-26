import 'dart:convert';
import 'dart:io';

class AgentClient {
  AgentClient({String? baseUrl, HttpClient? httpClient})
    : baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'AGENT_BASE_URL',
            defaultValue: 'http://10.0.2.2:8787',
          ),
      _httpClient = httpClient ?? HttpClient();

  final String baseUrl;
  final HttpClient _httpClient;

  Future<bool> isHealthy() async {
    try {
      final request = await _httpClient.getUrl(Uri.parse('$baseUrl/health'));
      final response = await request.close();
      await response.drain<void>();
      return response.statusCode == HttpStatus.ok;
    } on Object {
      return false;
    }
  }

  Future<String> chat(String prompt, {String? caseId}) async {
    final request = await _httpClient.postUrl(Uri.parse('$baseUrl/api/chat'));
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({'prompt': prompt, 'caseId': ?caseId}));
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    final json = jsonDecode(body) as Map<String, dynamic>;
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(json['error'] as String? ?? 'Agent 请求失败');
    }
    return json['text'] as String? ?? '';
  }

  void close() => _httpClient.close(force: true);
}
