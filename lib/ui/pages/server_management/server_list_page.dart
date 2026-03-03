import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/server_controller.dart';
import '../../../core/models/server_config.dart';
import '../../routes/app_routes.dart';
import 'server_edit_page.dart';
import '../settings/about_page.dart'; 

class ServerListPage extends StatefulWidget {
  const ServerListPage({super.key});

  @override
  State<ServerListPage> createState() => _ServerListPageState();
}

class _ServerListPageState extends State<ServerListPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ServerController());

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'AstrBot 远程管理' : '关于 AstrBot'),
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildServerList(controller),
          const AboutPage(), 
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dns_outlined), activeIcon: Icon(Icons.dns), label: '服务器'),
          BottomNavigationBarItem(icon: Icon(Icons.info_outline), activeIcon: Icon(Icons.info), label: '关于'),
        ],
      ),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
        onPressed: () => Get.to(() => const ServerEditPage()),
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  Widget _buildServerList(ServerController controller) {
    return Obx(() {
      if (controller.servers.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.dns_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('还没有添加服务器', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Get.to(() => const ServerEditPage()),
                icon: const Icon(Icons.add),
                label: const Text('添加服务器'),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: controller.servers.length,
        itemBuilder: (context, index) {
          final server = controller.servers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(Icons.dns, color: Theme.of(context).colorScheme.primary),
              ),
              title: Text(server.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${server.host}:${server.astrBotPort}'),
              trailing: const Icon(Icons.chevron_right),
              // 🪄 还原：点击依然进入综合控制台页面喵✨
              onTap: () => Get.toNamed(AppRoutes.webview, arguments: server),
              onLongPress: () => _showServerOptions(Get.context!, controller, server),
            ),
          );
        },
      );
    });
  }

  void _showServerOptions(BuildContext context, ServerController controller, ServerConfig server) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.edit), title: const Text('编辑服务器'), onTap: () { Get.back(); Get.to(() => ServerEditPage(server: server)); }),
            ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('删除服务器', style: TextStyle(color: Colors.red)), onTap: () { Get.back(); _confirmDelete(context, controller, server); }),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ServerController controller, ServerConfig server) {
    Get.dialog(
      AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除服务器 "${server.name}" 吗？'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('取消')),
          TextButton(onPressed: () { controller.deleteServer(server.id); Get.back(); }, child: const Text('删除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
