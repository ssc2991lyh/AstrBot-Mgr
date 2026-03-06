import 'dart:io';
import 'dart:async';
import 'dart:convert'; 
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
  final version = '未知'.obs;
  final qqVersion = '未知'.obs;

  // 🪄 插件相关存储喵✨
  final napCatPlugins = <Map<String, dynamic>>[].obs;
  final extensionPages = <Map<String, dynamic>>[].obs;
  final pluginDetailData = <String, dynamic>{}.obs;
  final isDetailLoading = false.obs;

  final cpuUsage = 0.0.obs;
  final memUsage = 0.0.obs;
  final cpuDetail = '系统: - / QQ: -'.obs;
  final memDetail = '系统: - / QQ: -'.obs;
  final archInfo = '未知架构'.obs;

  final latestVersion = '未知'.obs;
  final hasUpdate = false.obs;

  final httpClients = <Map<String, dynamic>>[].obs;
  final wsClients = <Map<String, dynamic>>[].obs;

  final pingDelay = (-1).obs;
  final isDetecting = false.obs;

  late ServerConfig _config;
  String? _token;
  
  Timer? _discoveryTimer;
  StreamSubscription? _sysStatusSub;

  void init(ServerConfig config, {String? token}) {
    _config = config;
    _token = token ?? config.napCatToken;
    refreshStatus();
    _startAutoDiscovery(); 
    _listenSysStatus(); 
  }

  void _listenSysStatus() async {
    _sysStatusSub?.cancel();
    try {
      final String url = '$_baseUrl/api/base/GetSysStatusRealTime';
      final response = await Dio().get<ResponseBody>(
        url,
        options: Options(
          headers: {
            if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
            'Accept': 'text/event-stream',
          },
          responseType: ResponseType.stream,
        ),
      );

      _sysStatusSub = response.data!.stream
          .cast<List<int>>() 
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (line.startsWith('data: ')) {
          try {
            final jsonStr = line.substring(6);
            final data = jsonDecode(jsonStr);
            final cpu = data['cpu'];
            final cpuSys = double.tryParse(cpu['usage']['system'].toString()) ?? 0.0;
            final cpuQq = double.tryParse(cpu['usage']['qq'].toString()) ?? 0.0;
            cpuUsage.value = (cpuSys + cpuQq) / 100.0;
            cpuDetail.value = '系统: $cpuSys% / QQ: $cpuQq%';
            final mem = data['memory'];
            final memTotal = double.tryParse(mem['total'].toString()) ?? 1.0;
            final memSys = double.tryParse(mem['usage']['system'].toString()) ?? 0.0;
            final memQq = double.tryParse(mem['usage']['qq'].toString()) ?? 0.0;
            memUsage.value = (memSys + memQq) / memTotal;
            memDetail.value = '系统: ${memSys.toStringAsFixed(0)}MB / QQ: ${memQq.toStringAsFixed(0)}MB';
            archInfo.value = data['arch'] ?? '未知';
          } catch (e) {}
        }
      });
    } catch (e) {}
  }

  void _startAutoDiscovery() {
    _discoveryTimer?.cancel();
    _discoveryTimer = Timer.periodic(const Duration(seconds: 5), (_) => _updatePing());
  }

  String get _baseUrl => 'http://${_config.host}:${_config.napCatPort}';
  String get discoveryTarget => '${_config.host}:${_config.napCatPort}';
  String get avatarUrl => uin.value.isNotEmpty ? 'http://q.qlogo.cn/headimg_dl?dst_uin=${uin.value}&spec=640' : '';

  Future<Map<String, dynamic>?> _webApiPost(String path, [Map<String, dynamic>? data]) async {
    try {
      final response = await _dio.post('$_baseUrl$path', data: data ?? {}, options: Options(headers: {if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'})).timeout(const Duration(seconds: 4));
      if (response.data is Map && response.data['code'] == 0) return Map<String, dynamic>.from(response.data);
      return null;
    } catch (e) { return null; }
  }

  Future<Map<String, dynamic>?> _webApiGet(String path) async {
    try {
      final response = await _dio.get('$_baseUrl$path', options: Options(headers: {if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token'})).timeout(const Duration(seconds: 4));
      if ((response.statusCode == 200 || response.statusCode == 304) && response.data is Map && response.data['code'] == 0) return Map<String, dynamic>.from(response.data);
      return null;
    } catch (e) { return null; }
  }

  Future<void> refreshStatus() async {
    if (isLoading.value) return;
    isLoading.value = true;
    final tasks = [_updateAccountInfo(), _updateNetworkConfig(), _updatePing(), _updateVersion(), _updateQQVersion(), _updatePlugins()];
    await Future.wait(tasks.map((task) => task.catchError((_) {})));
    isLoading.value = false;
  }

  Future<void> _updateAccountInfo() async {
    final res = await _webApiPost('/api/QQLogin/GetQQLoginInfo');
    if (res != null && res['data'] != null) {
      final info = res['data'];
      nick.value = info['nick'] ?? '已登录';
      uin.value = info['uin']?.toString() ?? '';
      uid.value = info['uid'] ?? '';
      isOnline.value = true;
    } else {
      isOnline.value = false;
      nick.value = '鉴权失败/离线';
    }
  }

  Future<void> _updateNetworkConfig() async {
    final res = await _webApiPost('/api/OB11Config/GetConfig');
    if (res != null && res['data'] != null) {
      final network = res['data']['network'];
      if (network != null) {
        httpClients.value = List<Map<String, dynamic>>.from(network['httpClients'] ?? []);
        wsClients.value = List<Map<String, dynamic>>.from(network['websocketClients'] ?? []);
      }
    }
  }

  Future<void> _updateVersion() async {
    final res = await _webApiGet('/api/base/GetNapCatVersion');
    if (res != null && res['data'] != null) {
      version.value = res['data']['version']?.toString() ?? '未知';
      await checkUpdate();
    }
  }

  Future<void> _updateQQVersion() async {
    final res = await _webApiGet('/api/base/QQVersion');
    if (res != null && res['data'] != null) qqVersion.value = res['data'].toString();
  }

  Future<void> _updatePlugins() async {
    final res = await _webApiGet('/api/Plugin/List');
    if (res != null && res['data'] != null) {
      napCatPlugins.value = List<Map<String, dynamic>>.from(res['data']['plugins'] ?? []);
      extensionPages.value = List<Map<String, dynamic>>.from(res['data']['extensionPages'] ?? []);
    }
  }

  // 🪄 核心：获取指定插件详情喵✨
  Future<void> fetchPluginStatus(String pluginId) async {
    isDetailLoading.value = true;
    final res = await _webApiGet('/api/Plugin/ext/$pluginId/status');
    if (res != null && res['data'] != null) {
      pluginDetailData.value = Map<String, dynamic>.from(res['data']);
    }
    isDetailLoading.value = false;
  }

  Future<void> checkUpdate() async {
    final res = await _webApiGet('/api/base/getLatestTag');
    if (res != null && res['data'] != null) {
      latestVersion.value = res['data'].toString();
      hasUpdate.value = (version.value != '未知' && version.value != latestVersion.value);
    }
  }

  Future<void> _updatePing() async {
    if (isDetecting.value) return;
    isDetecting.value = true;
    try {
      final stopwatch = Stopwatch()..start();
      final socket = await Socket.connect(_config.host, int.parse(_config.napCatPort), timeout: const Duration(seconds: 2));
      stopwatch.stop();
      pingDelay.value = stopwatch.elapsedMilliseconds;
      await socket.close();
    } catch (_) { pingDelay.value = -1; }
    isDetecting.value = false;
  }

  Future<void> runDiscovery() => _updatePing();
  Future<void> restartService() async => _webApiPost('/api/Service/Restart');
  Future<void> cleanCache() async => _webApiPost('/api/System/CleanCache');

  @override void onClose() { _discoveryTimer?.cancel(); _sysStatusSub?.cancel(); super.onClose(); }
}
