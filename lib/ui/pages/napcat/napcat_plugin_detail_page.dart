import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/napcat_controller.dart';

class NapCatPluginDetailPage extends StatefulWidget {
  final String pluginId;
  final String pluginName;

  const NapCatPluginDetailPage({
    super.key, 
    required this.pluginId, 
    required this.pluginName
  });

  @override
  State<NapCatPluginDetailPage> createState() => _NapCatPluginDetailPageState();
}

class _NapCatPluginDetailPageState extends State<NapCatPluginDetailPage> {
  final controller = Get.find<NapCatController>();

  @override
  void initState() {
    super.initState();
    controller.fetchPluginStatus(widget.pluginId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pluginName),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchPluginStatus(widget.pluginId),
          )
        ],
      ),
      body: Obx(() {
        if (controller.isDetailLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = controller.pluginDetailData;
        if (data.isEmpty) {
          return const Center(child: Text('无法获取插件详情喵xwx'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatusHeader(data),
            const SizedBox(height: 20),
            _buildConfigSection(data['config'] ?? {}),
            const SizedBox(height: 20),
            _buildEnvironmentCard(data),
          ],
        );
      }),
    );
  }

  Widget _buildStatusHeader(Map<String, dynamic> data) {
    return Card(
      elevation: 0,
      color: Colors.green.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.green, width: 0.5)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.timer_outlined, color: Colors.green, size: 32),
            const SizedBox(height: 12),
            const Text('运行时间', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              data['uptimeFormatted'] ?? '未知',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigSection(Map<String, dynamic> config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text('插件配置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
          child: Column(
            children: config.entries.map((e) => ListTile(
              title: Text(e.key, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              trailing: Text(e.value.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
              dense: true,
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEnvironmentCard(Map<String, dynamic> data) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildEnvItem(Icons.laptop, '平台', data['platform'] ?? '-'),
            _buildEnvItem(Icons.memory, '架构', data['arch'] ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
