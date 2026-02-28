import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/models/server_config.dart';
import '../../../core/services/astrbot_api_service.dart';
import 'package:url_launcher/url_launcher.dart'; // 备用跳转喵

class QuickSettingsPage extends StatefulWidget {
  final ServerConfig serverConfig;
  final Function(String)? onJumpToWeb; // 🪄 新增：跳转到网页回调喵✨

  const QuickSettingsPage({
    super.key, 
    required this.serverConfig,
    this.onJumpToWeb, // 传进来喵awa
  });

  @override
  State<QuickSettingsPage> createState() => QuickSettingsPageState();
}

class QuickSettingsPageState extends State<QuickSettingsPage> {
  late AstrBotApiService _apiService;
  List<dynamic>? _profiles;
  int? _ping;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiService = AstrBotApiService(widget.serverConfig);
    forceRefresh();
  }

  Future<void> forceRefresh() => _refreshData();

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _apiService.getPing(),
      _apiService.getConfigProfiles(),
    ]);
    if (mounted) {
      setState(() {
        _ping = results[0] as int?;
        _profiles = results[1] as List<dynamic>?;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: forceRefresh,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('官方 API 控制台', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('基于 OpenAPI v1 实时同步喵awa✨', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 24),
            _buildConnectionCard(colorScheme),
            const SizedBox(height: 24),
            
            // 🪄 核心：更名 + 新增切换按钮喵✨！
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('可用的聊天配置'),
                TextButton.icon(
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('切换配置', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    // 飞向网页版平台设置页喵✨！
                    if (widget.onJumpToWeb != null) {
                      widget.onJumpToWeb!('/platforms');
                    }
                  },
                ),
              ],
            ),
            
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (_profiles == null || _profiles!.isEmpty)
              _buildEmptyState('未发现任何配置文件喵xwx\n请检查 API Key 权限喵~')
            else
              ..._profiles!.map((p) => _buildProfileTile(p, colorScheme)),
            const SizedBox(height: 32),
            Center(child: Column(children: [const Icon(Icons.info_outline, size: 16, color: Colors.grey), const SizedBox(height: 8), Text('活跃终端状态请在“仪表盘”查看喵✨', style: TextStyle(color: Colors.grey.withOpacity(0.6), fontSize: 10))])),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard(ColorScheme colorScheme) { return Card(elevation: 0, color: colorScheme.secondaryContainer.withOpacity(0.2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: colorScheme.primary.withOpacity(0.1))), child: ListTile(leading: Icon(_ping != null ? Icons.wifi_tethering : Icons.wifi_tethering_off, color: _ping != null ? Colors.green : Colors.red), title: const Text('API 同步状态', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), subtitle: Text(_ping != null ? '连接极佳 (Ping: ${_ping}ms)' : '等待握手喵awa'), trailing: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : IconButton(icon: const Icon(Icons.sync, size: 20), onPressed: forceRefresh))); }
  Widget _buildProfileTile(dynamic profile, ColorScheme colorScheme) { final name = profile['name'] ?? '未命名配置'; final isDefault = profile['is_default'] ?? false; return Card(margin: const EdgeInsets.only(bottom: 12), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isDefault ? Colors.blue.withOpacity(0.5) : Colors.transparent)), child: ListTile(leading: CircleAvatar(backgroundColor: isDefault ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1), child: Icon(Icons.description_outlined, color: isDefault ? Colors.blue : Colors.grey, size: 20)), title: Text(name, style: TextStyle(fontWeight: isDefault ? FontWeight.bold : FontWeight.normal)), subtitle: Text(isDefault ? '当前正在使用的默认配置喵✨' : '备选聊天预设喵awa', style: const TextStyle(fontSize: 11)), trailing: isDefault ? const Icon(Icons.check_circle, color: Colors.blue, size: 18) : const Icon(Icons.chevron_right, size: 18), onTap: () { if (widget.onJumpToWeb != null) widget.onJumpToWeb!('/platforms'); })); }
  Widget _buildEmptyState(String msg) { return Center(child: Padding(padding: const EdgeInsets.all(40), child: Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)))); }
  Widget _buildSectionHeader(String title) { return Padding(padding: const EdgeInsets.only(bottom: 0, left: 4), child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue))); }
}
