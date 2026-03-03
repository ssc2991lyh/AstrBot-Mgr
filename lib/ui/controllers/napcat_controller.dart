import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:global_repository/global_repository.dart';
import '../../core/models/server_config.dart';

class NapCatController extends GetxController {
  final _dio = Dio(BaseOptions(
    validateStatus: (status) => true,
    responseType: ResponseType.json,
  ));
  
  final isOnline = false.obs; 
  final isLoading = false.obs;

  final nick = '加载中...'.obs;
  final uin = ''.obs;
  final uid = ''.obs;
  final version = 'WebUI 版'.obs;

  final pingDelay = (-1).obs;
  final isDetecting = false.obs;

  late ServerConfig _config;
  String? _token;

  void init(ServerConfig config, {String? token}) {
    _config = config;
    // 🪄 核心：强制使用配置里的端口，绝不写死喵✨
    _token = token ?? config.napCatToken;
    refreshStatus();
  }

  // 🪄 动态获取 BaseUrl，确保与 serverconfig 实时同步喵awa
  String get _baseUrl => 'http://${_config.host}:${_config.napCatPort}';
  String get discoveryTarget => '${_config.host}:${_config.napCatPort}';
  String get avatarUrl => uin.value.isNotEmpty 
      ? 'http://q.qlogo.cn/headimg_dl?dst_uin=${uin.value}&spec=640'
      : '';

  Future<Map<String, dynamic>?> _webApiPost(String path, [Map<String, dynamic>? data]) async {
    try {
      final response = await _dio.post(
        '$_baseUrl$path',
        data: data ?? {},
        options: Options(headers: {
          if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        }),
      ).timeout(const Duration(seconds: 5));

      final respData = response.data;
      if (respData is Map && respData['code'] == 0) {
        return Map<String, dynamic>.from(respData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> refreshStatus() async {
    if (isLoading.value) return;
    isLoading.value = true;
    
    try {
      final accountRes = await _webApiPost('/api/QQLogin/GetQQLoginInfo');
      
      if (accountRes != null && accountRes['data'] != null) {
        final info = accountRes['data'];
        nick.value = info['nick'] ?? '已登录用户';
        uin.value = info['uin']?.toString() ?? '';
        uid.value = info['uid'] ?? '';
        isOnline.value = true;
        Log.i('NapCat WebUI 连接成功喵 ✨ (端口: ${_config.napCatPort})');
      } else {
        isOnline.value = false;
        nick.value = '鉴权失败/离线';
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> runDiscovery() async {
    isDetecting.value = true;
    try {
      final stopwatch = Stopwatch()..start();
      // 🪄 这里的探测端口也必须动态喵✨
      final socket = await Socket.connect(_config.host, int.parse(_config.napCatPort), timeout: const Duration(seconds: 2));
      stopwatch.stop();
      pingDelay.value = stopwatch.elapsedMilliseconds;
      await socket.close();
    } catch (e) { pingDelay.value = -1; }
    isDetecting.value = false;
  }

  Future<void> restartService() async => _webApiPost('/api/Service/Restart');
  Future<void> cleanCache() async => _webApiPost('/api/System/CleanCache');
}
