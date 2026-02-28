import 'dart:convert';
import 'dart:io'; 
import 'package:dio/dio.dart';
import '../models/server_config.dart';

class AstrBotApiService {
  final ServerConfig server;
  late final Dio _dio;

  AstrBotApiService(this.server) {
    final String token = server.apiKey.trim();
    final Map<String, String> headers = {
      'Accept': 'application/json',
    };

    if (token.startsWith('eyJ')) {
      headers['Authorization'] = 'Bearer $token';
    } else {
      headers['X-API-Key'] = token;
      headers['Authorization'] = 'Bearer $token';
    }

    _dio = Dio(BaseOptions(
      baseUrl: 'http://${server.host}:${server.astrBotPort}',
      headers: headers,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      validateStatus: (status) => true,
    ));
  }

  /// 🪄 获取终极详细插件列表喵✨ (来自最新的 F12 情报！)
  Future<Map<String, dynamic>?> getDetailedPlugins() async {
    try {
      // 哥哥，这次咱们用这个绝对正确的路径喵！
      final response = await _dio.get('/api/plugin/get');
      if (response.statusCode == 200) {
        return _parseData(response.data);
      }
    } catch (e) { print('Plugins Get Error: $e'); }
    return null;
  }

  Future<Map<String, dynamic>?> getFullStat() async {
    try {
      final response = await _dio.get('/api/stat/get?offset_sec=86400');
      if (response.statusCode == 200) {
        final data = _parseData(response.data);
        if (data != null && data['status'] == 'ok') return data['data'] as Map<String, dynamic>;
      }
    } catch (e) {}
    return null;
  }

  Future<String?> getVersion() async {
    try {
      final response = await _dio.get('/api/stat/version');
      if (response.statusCode == 200) {
        final rawStr = response.data.toString().trim();
        final data = _parseData(response.data);
        if (data != null && data.containsKey('version')) return data['version'].toString();
        if (rawStr.contains('version:')) {
          final parts = rawStr.split('version:');
          return parts.length > 1 ? parts[1].split('\n')[0].trim() : rawStr;
        }
        return rawStr;
      }
    } catch (e) {}
    return null;
  }

  Future<List<String>?> getActiveBots() async {
    try {
      final response = await _dio.get('/api/v1/im/bots');
      final data = _parseData(response.data);
      if (data != null && data['status'] == 'ok') {
        final botIds = data['data']['bot_ids'] as List;
        return botIds.map((e) => e.toString()).toList();
      }
    } catch (e) {}
    return null;
  }

  Future<List<dynamic>?> getMcpServers() async {
    try {
      final response = await _dio.get('/api/tools/mcp/servers');
      final data = _parseData(response.data);
      if (data != null && data['status'] == 'ok') return data['data'] as List;
    } catch (e) {}
    return null;
  }

  Future<List<dynamic>?> getConfigProfiles() async {
    try {
      final response = await _dio.get('/api/v1/configs');
      final data = _parseData(response.data);
      if (data != null && data['status'] == 'ok') return data['data']['configs'] as List;
    } catch (e) {}
    return null;
  }

  Future<int?> getPing() async {
    final stopwatch = Stopwatch()..start();
    try {
      final intPort = int.tryParse(server.astrBotPort.toString()) ?? 6185;
      final socket = await Socket.connect(server.host, intPort, timeout: const Duration(seconds: 2));
      stopwatch.stop();
      await socket.close();
      return stopwatch.elapsedMilliseconds;
    } catch (e) {
      try {
        await _dio.get('/', options: Options(responseType: ResponseType.plain));
        stopwatch.stop();
        return stopwatch.elapsedMilliseconds;
      } catch (_) { return null; }
    }
  }

  Map<String, dynamic>? _parseData(dynamic data) {
    if (data == null) return null;
    if (data is Map) return data as Map<String, dynamic>;
    if (data is String) {
      try { return jsonDecode(data); } catch (_) { return null; }
    }
    return null;
  }
}
