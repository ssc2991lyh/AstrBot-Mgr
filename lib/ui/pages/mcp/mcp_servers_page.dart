import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/models/server_config.dart';
import '../../../core/services/astrbot_api_service.dart';

class McpServersPage extends StatefulWidget {
  const McpServersPage({super.key});

  @override
  State<McpServersPage> createState() => _McpServersPageState();
}

class _McpServersPageState extends State<McpServersPage> {
  late AstrBotApiService _apiService;
  late final ServerConfig server;
  List<dynamic>? _mcpServers;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    server = Get.arguments as ServerConfig;
    _apiService = AstrBotApiService(server);
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    final data = await _apiService.getMcpServers();
    if (mounted) {
      setState(() {
        _mcpServers = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('MCP 服务器状态'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData)],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _mcpServers == null || _mcpServers!.isEmpty
            ? const Center(child: Text('没有发现已加载的 MCP 服务器喵awa'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _mcpServers!.length,
                itemBuilder: (context, index) {
                  final server = _mcpServers![index];
                  return _buildMcpCard(server, colorScheme);
                },
              ),
      ),
    );
  }

  Widget _buildMcpCard(dynamic data, ColorScheme colorScheme) {
    final String name = data['name'] ?? '未知服务器';
    final bool active = data['active'] ?? false;
    final String type = data['type'] ?? 'unknown';
    final List tools = data['tools'] ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: Icon(Icons.lan, color: active ? Colors.green : Colors.grey),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (active ? Colors.green : Colors.red).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(active ? 'ACTIVE' : 'INACTIVE', style: TextStyle(fontSize: 10, color: active ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Text('Type: $type', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const Text('可用工具 (Tools):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tools.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(t.toString(), style: const TextStyle(fontSize: 11)),
                  )).toList(),
                ),
                if (tools.isEmpty) const Text('暂无可调用的工具喵awa', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
