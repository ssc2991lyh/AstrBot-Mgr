import 'dart:convert';
import 'dart:io'; 
import 'package:dio/dio.dart';
import '../models/server_config.dart';

class AstrBotApiService {
  final ServerConfig server;
  late final Dio _dio;

  AstrBotApiService(this.server) {
    final String token = server.apiKey.trim();
    final Map<String, String> headers = {'Accept': 'application/json'};

    if (token.startsWith('eyJ')) {
      headers['Authorization'] = 'Bearer $token';
    } else {
      headers['X-API-Key'] = token;
      headers['Authorization'] = 'Bearer $token';
    }

    _dio = Dio(BaseOptions(
      baseUrl: 'http://${server.host}:${server.astrBotPort}',
      headers: headers,
      connectTimeout: const Duration(seconds: 3),
      receiveTimeout: const Duration(seconds: 3),
      validateStatus: (status) => true,
    ));
  }

  Future<Map<String, dynamic>?> getDetailedPlugins() async {
    try {
      final response = await _dio.get('/api/plugin/get');
      return _parseData(response.data);
    } catch (e) {}
    return null;
  }

  Future<Map<String, dynamic>?> getFullStat() async {
    try {
      final response = await _dio.get('/api/stat/get?offset_sec=86400');
      final data = _parseData(response.data);
      if (data != null && data['data'] != null) return data['data'] as Map<String, dynamic>;
    } catch (e) {}
    return null;
  }

  Future<String?> getVersion() async {
    try {
      final response = await _dio.get('/api/stat/version');
      final data = _parseData(response.data);
      // 🪄 修正：根据截图结构，版本号在 data.data.version 喵✨
      if (data != null && data['data'] != null) {
        return data['data']['version']?.toString();
      }
      return response.data?.toString();
    } catch (e) {}
    return null;
  }

  Future<List<String>?> getActiveBots() async {
    try {
      final response = await _dio.get('/api/v1/im/bots');
      final data = _parseData(response.data);
      if (data != null && data['data'] != null) {
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
      if (data != null && data['data'] != null) return data['data'] as List;
    } catch (e) {}
    return null;
  }

  Future<List<dynamic>?> getConfigProfiles() async {
    try {
      final response = await _dio.get('/api/v1/configs');
      final data = _parseData(response.data);
      if (data != null && data['data'] != null) return data['data']['configs'] as List;
    } catch (e) {}
    return null;
  }

  Future<int?> getPing() async {
    final stopwatch = Stopwatch()..start();
    try {
      final socket = await Socket.connect(server.host, int.tryParse(server.astrBotPort) ?? 6185, timeout: const Duration(seconds: 2));
      stopwatch.stop();
      await socket.close();
      return stopwatch.elapsedMilliseconds;
    } catch (_) { return null; }
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
