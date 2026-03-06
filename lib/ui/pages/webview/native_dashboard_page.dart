import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/models/server_config.dart';
import '../../../core/services/astrbot_api_service.dart';
import '../../routes/app_routes.dart';

class NativeDashboardPage extends StatefulWidget {
  final ServerConfig serverConfig;
  final VoidCallback onOpenWebConsole;
  final VoidCallback onOpenExtensionStore;

  const NativeDashboardPage({
    super.key, 
    required this.serverConfig, 
    required this.onOpenWebConsole,
    required this.onOpenExtensionStore,
  });

  @override
  State<NativeDashboardPage> createState() => NativeDashboardPageState();
}

class NativeDashboardPageState extends State<NativeDashboardPage> {
  late AstrBotApiService _apiService;
  bool _isOnline = false;
  bool _isLoading = true;
  int? _ping;
  String? _version;
  Map<String, dynamic>? _fullStat;
  
  // 🪄 自动刷新定时器
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _apiService = AstrBotApiService(widget.serverConfig);
    refreshWithVersion();
    _startAutoPing(); // 🪄 启动 5s 自动 Ping 喵✨
  }

  void _startAutoPing() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _updatePingOnly();
    });
  }

  Future<void> _updatePingOnly() async {
    final res = await _apiService.getPing();
    if (mounted) setState(() { _ping = res; _isOnline = res != null; });
  }

  @override
  void didUpdateWidget(NativeDashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serverConfig.apiKey != widget.serverConfig.apiKey) {
      _apiService = AstrBotApiService(widget.serverConfig);
      refreshWithVersion();
    }
  }

  Future<void> refreshWithVersion() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.getPing(),
        _apiService.getVersion(),
        _apiService.getFullStat(),
      ]);
      if (mounted) {
        setState(() {
          _ping = results[0] as int?;
          _version = results[1] as String?;
          _fullStat = results[2] as Map<String, dynamic>?;
          _isOnline = _ping != null;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double cpu = (_fullStat?['cpu_percent'] ?? 0.0) / 100.0;
    final double memProcess = (_fullStat?['memory']?['process'] ?? 0.0).toDouble();

    return RefreshIndicator(
      onRefresh: refreshWithVersion,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: colorScheme.primaryContainer.withOpacity(0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(radius: 24, backgroundColor: colorScheme.primary, child: const Icon(Icons.hub, color: Colors.white, size: 24)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.serverConfig.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          _version ?? '正在获取状态...',
                          style: TextStyle(fontSize: 12, color: colorScheme.primary.withOpacity(0.8)),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildMonitorCard('CPU 负载', cpu, Colors.blue),
          const SizedBox(height: 12),
          _buildMonitorCard('内存占用', memProcess / 1024.0, Colors.green, subtitle: '${memProcess.toStringAsFixed(1)} MB'),
          const SizedBox(height: 24),
          const Text(' 常用操作', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.6,
            children: [
              _buildActionItem(Icons.web, 'Web 控制台', Colors.blue, widget.onOpenWebConsole),
              _buildActionItem(Icons.extension, '插件列表', Colors.orange, widget.onOpenExtensionStore),
              _buildActionItem(Icons.terminal, '原生终端', Colors.purple, () => Get.toNamed(AppRoutes.terminal, arguments: {'server': widget.serverConfig, 'user': 'root'})),
              _buildActionItem(Icons.refresh, '手动同步', Colors.teal, refreshWithVersion),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() { return Column( crossAxisAlignment: CrossAxisAlignment.end, children: [ Container( padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration( color: _isOnline ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: _isOnline ? Colors.green : Colors.red, width: 0.5), ), child: Text(_isOnline ? '在线' : '离线', style: TextStyle(color: _isOnline ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)), ), if (_ping != null) Text('$_ping ms', style: const TextStyle(fontSize: 10, color: Colors.grey)), ], ); }
  Widget _buildMonitorCard(String label, double value, Color color, {String? subtitle}) { return Card( elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade100)), child: Padding( padding: const EdgeInsets.all(16), child: Column( children: [ Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)), Text(subtitle ?? '${(value * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)), ], ), const SizedBox(height: 10), ClipRRect( borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: value.clamp(0, 1.0), backgroundColor: color.withOpacity(0.1), color: color, minHeight: 6), ), ], ), ), ); }
  Widget _buildActionItem(IconData icon, String label, Color color, VoidCallback onTap) { return InkWell( onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container( decoration: BoxDecoration( color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.1)), ), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 24), const SizedBox(height: 8), Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))]), ), ); }
}
