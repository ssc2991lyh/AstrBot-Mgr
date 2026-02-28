import 'dart:convert';
import 'package:get/get.dart';
import 'package:settings/settings.dart';
import '../../core/models/server_config.dart';

class ServerController extends GetxController {
  final RxList<ServerConfig> servers = <ServerConfig>[].obs;
  final String _storageKey = 'remote_servers';

  @override
  void onInit() {
    super.onInit();
    loadServers();
  }

  void loadServers() {
    // 空安全处理：只有当 box 存在时才操作
    if (box != null) {
      final dynamic data = box!.get(_storageKey);
      if (data != null) {
        try {
          final List<dynamic> decoded = json.decode(data.toString());
          servers.value = decoded.map((e) => ServerConfig.fromMap(e)).toList();
        } catch (e) {
          print('Error loading servers: $e');
        }
      }
    }
  }

  void saveServers() {
    if (box != null) {
      final String data = json.encode(servers.map((e) => e.toMap()).toList());
      box!.put(_storageKey, data);
    }
  }

  void addServer(ServerConfig server) {
    servers.add(server);
    saveServers();
  }

  void updateServer(ServerConfig server) {
    final index = servers.indexWhere((e) => e.id == server.id);
    if (index != -1) {
      servers[index] = server;
      saveServers();
    }
  }

  void deleteServer(String id) {
    servers.removeWhere((e) => e.id == id);
    saveServers();
  }
}
