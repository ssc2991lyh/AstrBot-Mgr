import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart'; // 🪄 引入，用于一键飞起喵✨
import '../../controllers/napcat_controller.dart';
import 'napcat_plugin_detail_page.dart'; 

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
          _buildRealtimeMonitor(controller),
          const SizedBox(height: 20),
          _buildConnectionSection(controller),
          const SizedBox(height: 20),
          _buildPluginSection(controller),
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
          colors: [Colors.indigo.shade400, Colors.purple.shade600],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              image: controller.avatarUrl.isNotEmpty 
                ? DecorationImage(image: NetworkImage(controller.avatarUrl), fit: BoxFit.cover)
                : null,
            ),
            child: controller.avatarUrl.isEmpty ? const Icon(Icons.person, size: 36, color: Colors.white) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(controller.nick.value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    _buildOnlineBadge(controller.isOnline.value),
                  ],
                ),
                const SizedBox(height: 4),
                Text('UIN: ${controller.uin.value.isEmpty ? "-" : controller.uin.value}', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                if (controller.uid.value.isNotEmpty)
                  Text('UID: ${controller.uid.value}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          IconButton(
            icon: controller.isLoading.value 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.refresh, color: Colors.white, size: 22),
            onPressed: controller.refreshStatus,
          ),
        ],
      ),
    ));
  }

  Widget _buildOnlineBadge(bool online) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: online ? Colors.greenAccent.shade400 : Colors.black26, borderRadius: BorderRadius.circular(8)),
      child: Text(online ? '在线' : '离线', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildRealtimeMonitor(NapCatController controller) {
    return Obx(() => Card(
      elevation: 0, color: Colors.blueGrey.shade50.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [Icon(Icons.monitor_heart_outlined, size: 18, color: Colors.blueGrey), SizedBox(width: 8), Text('系统负载 (实时)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]),
            const Divider(height: 24),
            _buildMonitorItem('CPU 使用率', controller.cpuUsage.value, controller.cpuDetail.value, Colors.blue),
            const SizedBox(height: 16),
            _buildMonitorItem('内存使用率', controller.memUsage.value, controller.memDetail.value, Colors.orange),
            const SizedBox(height: 12),
            Text('系统架构: ${controller.archInfo.value}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    ));
  }

  Widget _buildMonitorItem(String label, double value, String detail, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)), Text(detail, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500))]),
      const SizedBox(height: 8),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: value.clamp(0, 1.0), backgroundColor: color.withOpacity(0.1), color: color, minHeight: 6)),
    ]);
  }

  Widget _buildDiscoveryCard(NapCatController controller) {
    return Obx(() => Card(
      elevation: 0, color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow('API 探测状态', controller.isOnline.value ? '200 OK (已同步)' : '无法连接/未登录', controller.isOnline.value ? Colors.green : Colors.red),
            const Divider(height: 24),
            _buildInfoRow('网络延迟 (TCP)', controller.pingDelay.value >= 0 ? '${controller.pingDelay.value} ms' : '超时', Colors.blue),
          ],
        ),
      ),
    ));
  }

  Widget _buildConnectionSection(NapCatController controller) {
    return Obx(() {
      if (controller.httpClients.isEmpty && controller.wsClients.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.only(left: 4, bottom: 12), child: Text('适配器连接', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
          ...controller.httpClients.map((c) => _buildConnItem(Icons.http, c['name'], c['url'], c['enable'])),
          ...controller.wsClients.map((c) => _buildConnItem(Icons.sync_alt, c['name'], c['url'], c['enable'])),
        ],
      );
    });
  }

  Widget _buildPluginSection(NapCatController controller) {
    return Obx(() {
      if (controller.napCatPlugins.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.only(left: 4, bottom: 12), child: Text('NapCat 插件', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
          ...controller.napCatPlugins.map((p) => _buildPluginItem(controller, p)),
        ],
      );
    });
  }

  Widget _buildPluginItem(NapCatController controller, Map<String, dynamic> plugin) {
    final bool isActive = plugin['status'] == 'active';
    final String pId = plugin['id'] ?? '';
    final String pName = plugin['name'] ?? '未知插件';

    return Card(
      elevation: 0, margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        onTap: () {
          // 🪄 暴力特权逻辑：针对 Stapxs 直接飞起喵✨！
          if (pId == 'napcat-plugin-ssqq') {
            final String targetUrl = '${controller.discoveryTarget.startsWith('http') ? controller.discoveryTarget : "http://" + controller.discoveryTarget}/plugin/napcat-plugin-ssqq/page/dashboard';
            launchUrl(Uri.parse(targetUrl), mode: LaunchMode.externalApplication);
          } else {
            Get.to(() => NapCatPluginDetailPage(pluginId: pId, pluginName: pName));
          }
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          child: Icon(pId == 'napcat-plugin-ssqq' ? Icons.bolt_rounded : Icons.extension_rounded, size: 20, color: isActive ? Colors.blue : Colors.grey),
        ),
        title: Text(pName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('v${plugin['version']} · ${plugin['author']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: Icon(pId == 'napcat-plugin-ssqq' ? Icons.open_in_new_rounded : Icons.chevron_right, size: 18, color: Colors.grey),
      ),
    );
  }

  Widget _buildConnItem(IconData icon, String name, String url, bool enable) {
    return Card(elevation: 0, margin: const EdgeInsets.only(bottom: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)), child: ListTile(dense: true, leading: Icon(icon, size: 20, color: enable ? Colors.indigo : Colors.grey), title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), subtitle: Text(url, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis), trailing: Container(width: 8, height: 8, decoration: BoxDecoration(color: enable ? Colors.green : Colors.grey.shade300, shape: BoxShape.circle))));
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)), Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold))]);
  }

  Widget _buildQuickActions(NapCatController controller) {
    return Row(children: [Expanded(child: _buildSimpleButton(Icons.restart_alt, '重启服务', Colors.orange, controller.restartService)), const SizedBox(width: 12), Expanded(child: _buildSimpleButton(Icons.cleaning_services, '清理缓存', Colors.blue, controller.cleanCache))]);
  }

  Widget _buildSimpleButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(onPressed: onTap, icon: Icon(icon, size: 18), label: Text(label), style: ElevatedButton.styleFrom(backgroundColor: color.withOpacity(0.1), foregroundColor: color, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  Widget _buildSystemInfo(NapCatController controller) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('系统信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Obx(() => Column(children: [
        ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.info_outline), title: Row(children: [const Text('NapCat 版本'), const SizedBox(width: 8), if (controller.hasUpdate.value) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)), child: Text('NEW: ${controller.latestVersion.value}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))]), trailing: Text(controller.version.value, style: const TextStyle(color: Colors.grey))),
        ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.account_circle_outlined), title: const Text('QQ 版本'), trailing: Text(controller.qqVersion.value, style: const TextStyle(color: Colors.grey))),
      ])),
    ]);
  }
}
