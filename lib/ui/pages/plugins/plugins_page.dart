import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class PluginsPage extends StatelessWidget {
  const PluginsPage({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>;
    final List plugins = args['plugins'] ?? [];
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('已安装插件详情')),
      body: plugins.isEmpty
          ? const Center(child: Text('没有发现已安装的插件喵xwx'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: plugins.length,
              itemBuilder: (context, index) {
                final p = plugins[index];
                final String name = p['display_name'] ?? p['name'] ?? '未知插件';
                final String version = p['version'] ?? '0.0.0';
                final String onlineVer = p['online_version'] ?? '';
                final bool activated = p['activated'] ?? false;
                final String desc = p['desc'] ?? '暂无介绍喵awa';
                final String repo = p['repo'] ?? '';
                final List handlers = p['handlers'] ?? [];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: activated ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      child: Icon(Icons.extension, color: activated ? Colors.blue : Colors.grey, size: 20),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Row(
                      children: [
                        Text('v$version', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        if (onlineVer.isNotEmpty && onlineVer != version)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text('有新版: $onlineVer ✨', style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    trailing: Icon(Icons.check_circle, color: activated ? Colors.green : Colors.grey, size: 18),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            Text(desc, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                            const SizedBox(height: 12),
                            if (repo.isNotEmpty)
                              TextButton.icon(
                                icon: const Icon(Icons.code, size: 16),
                                label: const Text('查看插件仓库', style: TextStyle(fontSize: 12)),
                                onPressed: () => _launchUrl(repo),
                              ),
                            const SizedBox(height: 12),
                            const Text('插件行为 (Handlers):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ...handlers.map((h) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: colorScheme.surfaceVariant.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                children: [
                                  const Icon(Icons.bolt, size: 14, color: Colors.amber),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(h['handler_name'] ?? '未命名行为', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        Text('${h['event_type_h'] ?? ''} | ${h['desc'] ?? ''}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                  if (h['has_admin'] == true)
                                    const Icon(Icons.admin_panel_settings, size: 14, color: Colors.red),
                                ],
                              ),
                            )).toList(),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }
}
