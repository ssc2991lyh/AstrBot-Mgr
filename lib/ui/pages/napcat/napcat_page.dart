import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/napcat_controller.dart';

class NapCatPage extends StatelessWidget {
  const NapCatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NapCatController>();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAccountHeader(controller), 
          const SizedBox(height: 20),
          _buildDiscoveryCard(controller),
          const SizedBox(height: 20),
          _buildQuickActions(controller),
          const SizedBox(height: 20),
          _buildSystemInfo(controller),
        ],
      ),
    );
  }

  Widget _buildAccountHeader(NapCatController controller) {
    return Obx(() => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              image: controller.avatarUrl.isNotEmpty 
                ? DecorationImage(image: NetworkImage(controller.avatarUrl), fit: BoxFit.cover)
                : null,
            ),
            child: controller.avatarUrl.isEmpty 
                ? const Icon(Icons.person, size: 40, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      controller.nick.value,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    _buildOnlineBadge(controller.isOnline.value),
                  ],
                ),
                const SizedBox(height: 4),
                Text('UIN: ${controller.uin.value.isEmpty ? "未登录" : controller.uin.value}', 
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                if (controller.uid.value.isNotEmpty)
                  Text(
                    'UID: ${controller.uid.value}',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: controller.isLoading.value 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.refresh, color: Colors.white),
            onPressed: controller.refreshStatus,
          ),
        ],
      ),
    ));
  }

  Widget _buildOnlineBadge(bool online) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: online ? Colors.greenAccent.shade400 : Colors.redAccent.shade100.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        online ? '在线' : '离线',
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDiscoveryCard(NapCatController controller) {
    return Obx(() => Card(
      elevation: 0,
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🪄 修正：移除 wsConnected 引用，改为 HTTP 探测状态喵✨
            _buildInfoRow('API 探测状态', controller.isOnline.value ? '200 OK (已同步)' : '无法连接/未登录', controller.isOnline.value ? Colors.green : Colors.red),
            const Divider(height: 24),
            _buildInfoRow('网络延迟 (TCP)', controller.pingDelay.value >= 0 ? '${controller.pingDelay.value} ms' : '超时', Colors.blue),
          ],
        ),
      ),
    ));
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildQuickActions(NapCatController controller) {
    return Row(
      children: [
        Expanded(
          child: _buildSimpleButton(Icons.restart_alt, '重启服务', Colors.orange, controller.restartService),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSimpleButton(Icons.cleaning_services, '清理缓存', Colors.blue, controller.cleanCache),
        ),
      ],
    );
  }

  Widget _buildSimpleButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSystemInfo(NapCatController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('系统信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Obx(() => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.info_outline),
          title: const Text('NapCat 版本'),
          trailing: Text(controller.version.value, style: const TextStyle(color: Colors.grey)),
        )),
      ],
    );
  }
}
