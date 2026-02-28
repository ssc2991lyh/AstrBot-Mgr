import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 20),
        const Text(
          '关于 AstrBot Manager',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
        ),
        
        const SizedBox(height: 40),
        
        Center(
          child: Column(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Image.asset('assets/icon.png', errorBuilder: (c, e, s) => Icon(Icons.stars, size: 40, color: colorScheme.primary)),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'AstrBot Manager',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              const SizedBox(height: 4),
              const Text(
                '重构·轻量·极致连接喵✨',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 48),
        
        _buildSectionHeader('应用信息'),
        _buildInfoCard([
          _buildInfoRow(Icons.info_outline, '当前版本', 'v1.5.3 (Android)'),
          const Divider(height: 1, indent: 48),
          _buildInfoRow(Icons.person_outline, '开发者', 'TeaQing', isDeveloper: true),
        ]),
        
        const SizedBox(height: 32),
        
        _buildSectionHeader('相关传送门'),
        _buildInfoCard([
          _buildLinkRow('官方网站', 'https://astrbot.app', () => _launchUrl('https://astrbot.app')),
          const Divider(height: 1, indent: 16),
          _buildLinkRow('官方文档', 'https://docs.astrbot.app', () => _launchUrl('https://docs.astrbot.app')),
          const Divider(height: 1, indent: 16),
          _buildLinkRow('官方仓库', 'https://github.com/AstrbotDevs/AstrBot', () => _launchUrl('https://github.com/AstrbotDevs/AstrBot')),
        ]),
        
        const SizedBox(height: 60),
        const Center(
          child: Opacity(
            opacity: 0.3,
            child: Text('Refactored & Purified with ❤️', style: TextStyle(fontSize: 10)),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 0,
      color: Colors.grey.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value, {bool isDeveloper = false}) {
    return ListTile(
      leading: Icon(icon, size: 20, color: Colors.blueGrey),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: Text(
        value,
        style: TextStyle(
          fontSize: 14, 
          fontWeight: isDeveloper ? FontWeight.bold : FontWeight.normal,
          color: isDeveloper ? Colors.blue : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildLinkRow(String title, String url, VoidCallback? onTap) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(url, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.open_in_new, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}
