import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:settings/settings.dart';
import '../../../core/models/server_config.dart';
import '../../../core/services/astrbot_api_service.dart';
import '../../routes/app_routes.dart';

class NativeDashboardPage extends StatefulWidget {
  final ServerConfig serverConfig;
  final VoidCallback onOpenWebConsole;
  final VoidCallback onOpenExtensionStore;
  final Function(String?)? onErrorDetected; // 🪄 向上传递报错喵✨

  const NativeDashboardPage({
    super.key, 
    required this.serverConfig, 
    required this.onOpenWebConsole,
    required this.onOpenExtensionStore,
    this.onErrorDetected,
  });

  @override
  State<NativeDashboardPage> createState() => NativeDashboardPageState();
}

class NativeDashboardPageState extends State<NativeDashboardPage> {
  late AstrBotApiService _apiService;
  bool _isOnline = false;
  bool _isLoading = true;
  int? _ping;
  List<String>? _bots;
  String? _version;
  Map<String, dynamic>? _fullStat;
  List<dynamic>? _mcpServers;

  @override
  void initState() {
    super.initState();
    _apiService = AstrBotApiService(widget.serverConfig);
    refreshWithVersion();
  }

  @override
  void didUpdateWidget(NativeDashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serverConfig.apiKey != widget.serverConfig.apiKey) {
      _apiService = AstrBotApiService(widget.serverConfig);
      refreshWithVersion();
    }
  }

  Future<void> refreshWithVersion() => _refreshData(checkVersion: true);

  Future<void> _refreshData({bool checkVersion = false}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final results = await Future.wait([
      _apiService.getPing(),
      _apiService.getActiveBots(),
      _apiService.getFullStat(),
      _apiService.getMcpServers(),
      _apiService.getDetailedPlugins(),
      if (checkVersion || _version == null) _apiService.getVersion() else Future.value(_version),
    ]);
    
    if (mounted) {
      final pluginData = results[4] as Map<String, dynamic>?;
      if (widget.onErrorDetected != null) {
        widget.onErrorDetected!(pluginData?['message']);
      }

      setState(() {
        _ping = results[0] as int?;
        _bots = results[1] as List<String>?;
        _fullStat = results[2] as Map<String, dynamic>?;
        _mcpServers = results[3] as List<dynamic>?;
        if (pluginData != null && pluginData['data'] is List) {
          _fullStat ??= {};
          _fullStat!['plugins'] = pluginData['data'];
          _fullStat!['plugin_count'] = (pluginData['data'] as List).length;
        }
        _version = results[5] as String?;
        _isOnline = _ping != null;
        _isLoading = false;
      });
    }
  }

  void _handleTerminalConnect() {
    final String userKey = 'ssh_user_${widget.serverConfig.id}';
    String? savedUser = box?.get(userKey);
    if (savedUser == null || savedUser.isEmpty) { _showUsernameDialog(userKey); } else { _goToTerminal(savedUser); }
  }

  void _showUsernameDialog(String storageKey) {
    final controller = TextEditingController(text: 'root');
    Get.dialog(AlertDialog(title: const Text('首次连接终端喵✨'), content: Column(mainAxisSize: MainAxisSize.min, children: [const Text('请输入服务器的 SSH 用户名喵awa', style: TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(height: 16), TextField(controller: controller, decoration: const InputDecoration(labelText: '用户名', border: OutlineInputBorder()))]), actions: [TextButton(onPressed: () => Get.back(), child: const Text('取消')), ElevatedButton(onPressed: () { final user = controller.text.trim(); if (user.isNotEmpty) { box?.put(storageKey, user); Get.back(); _goToTerminal(user); } }, child: const Text('连接'))]));
  }

  void _goToTerminal(String username) { Get.toNamed(AppRoutes.terminal, arguments: {'server': widget.serverConfig, 'user': username}); }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double cpu = (_fullStat?['cpu_percent'] ?? 0.0) / 100.0;
    final double mem = ((_fullStat?['memory']?['process'] ?? 0.0) as num).toDouble() / 1024.0;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: refreshWithVersion,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. 顶部卡片
            Card(
              elevation: 0,
              color: colorScheme.primaryContainer.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: colorScheme.primary.withOpacity(0.1))),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    CircleAvatar(radius: 28, backgroundColor: colorScheme.primary, child: const Icon(Icons.smart_toy, color: Colors.white, size: 30)),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.serverConfig.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_isLoading && _version == null ? '同步版本中...' : (_version ?? '版本未知喵awa'), style: TextStyle(fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.w500)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      StatusChip(isActive: _isOnline),
                      if (_ping != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text('$_ping ms', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _ping! < 100 ? Colors.green : Colors.orange))),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // 2. 硬件资源卡片 (原位置喵✨)
            Card(elevation: 0, color: colorScheme.surfaceVariant.withOpacity(0.3), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [_buildUsageRow('CPU 负载', cpu, Colors.blue), const SizedBox(height: 16), _buildUsageRow('内存占用 (MB)', mem, Colors.green)]))),
            
            const SizedBox(height: 24),

            // 3. 连接实时数据 (挪到这里啦喵！✨)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Icon(Icons.data_thresholding_outlined, color: colorScheme.primary, size: 22), const SizedBox(width: 8), const Text('连接实时数据', style: TextStyle(fontWeight: FontWeight.bold))]),
                    const SizedBox(height: 20),
                    _buildStatusRow('物理连接', _isOnline ? '畅通握手中喵✨' : '正在寻觅中喵xwx'),
                    const Divider(height: 24),
                    _buildStatusRow('活跃 Bot 数', '${_bots?.length ?? 0} 个已上线'),
                    const Divider(height: 24),
                    InkWell(
                      onTap: () => Get.toNamed(AppRoutes.plugins, arguments: {'plugins': _fullStat?['plugins'] ?? []}),
                      child: _buildStatusRow('已装插件数', '${_fullStat?['plugin_count'] ?? 0} 个插件 >', color: Colors.blue),
                    ),
                    const Divider(height: 24),
                    InkWell(
                      onTap: () => Get.toNamed(AppRoutes.mcpServers, arguments: widget.serverConfig),
                      child: _buildStatusRow('已加载MCP服务器', '${_mcpServers?.length ?? 0} 个服务 >', color: Colors.blue),
                    ),
                    const Divider(height: 24),
                    _buildStatusRow('总消息处理', '${_fullStat?['message_count'] ?? 0} 条'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            const Text('  管理与工具', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.4, children: [_buildActionCard(context, icon: Icons.open_in_browser, title: 'Web 控制台', subtitle: '全量设置入口', onTap: widget.onOpenWebConsole, color: Colors.blue), _buildActionCard(context, icon: Icons.sync, title: '同步数据', subtitle: '刷新状态与测速', onTap: () => _refreshData(checkVersion: false), color: Colors.orange), _buildActionCard(context, icon: Icons.extension_outlined, title: '插件广场', subtitle: '发现更多技能', onTap: widget.onOpenExtensionStore, color: Colors.green), _buildActionCard(context, icon: Icons.terminal, title: '原生终端', subtitle: 'SSH 直接连服务器', onTap: _handleTerminalConnect, color: Colors.purple)]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageRow(String label, double percent, Color color) { return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), Text('${(percent * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold))]), const SizedBox(height: 8), LinearProgressIndicator(value: _isLoading ? null : percent.clamp(0.0, 1.0), backgroundColor: color.withOpacity(0.1), color: color, minHeight: 6, borderRadius: BorderRadius.circular(3))]); }
  Widget _buildActionCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap, required Color color}) { return Card(elevation: 0, color: color.withOpacity(0.05), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: color.withOpacity(0.1))), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 28), const SizedBox(height: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey))])))); }
  Widget _buildStatusRow(String label, String value, {Color? color}) { return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.grey)), Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color))]); }
}

class StatusChip extends StatelessWidget {
  final bool isActive;
  const StatusChip({super.key, required this.isActive});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: isActive ? Colors.green : Colors.red)),
      child: Text(isActive ? '在线' : '离线', style: TextStyle(color: isActive ? Colors.green.shade700 : Colors.red.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
