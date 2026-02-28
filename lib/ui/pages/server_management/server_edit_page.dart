import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../controllers/server_controller.dart';
import '../../../core/models/server_config.dart'; // 修正了路径

class ServerEditPage extends StatefulWidget {
  final ServerConfig? server;
  const ServerEditPage({super.key, this.server});

  @override
  State<ServerEditPage> createState() => _ServerEditPageState();
}

class _ServerEditPageState extends State<ServerEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _hostController;
  late TextEditingController _astrBotPortController;
  late TextEditingController _napCatPortController;
  late TextEditingController _napCatTokenController;
  late TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.server?.name ?? '');
    _hostController = TextEditingController(text: widget.server?.host ?? '');
    _astrBotPortController = TextEditingController(text: widget.server?.astrBotPort ?? '6185');
    _napCatPortController = TextEditingController(text: widget.server?.napCatPort ?? '6099');
    _napCatTokenController = TextEditingController(text: widget.server?.napCatToken ?? '');
    _apiKeyController = TextEditingController(text: widget.server?.apiKey ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _astrBotPortController.dispose();
    _napCatPortController.dispose();
    _napCatTokenController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final controller = Get.find<ServerController>();
      final server = ServerConfig(
        id: widget.server?.id ?? const Uuid().v4(),
        name: _nameController.text,
        host: _hostController.text,
        astrBotPort: _astrBotPortController.text,
        napCatPort: _napCatPortController.text,
        napCatToken: _napCatTokenController.text,
        apiKey: _apiKeyController.text,
      );

      if (widget.server == null) {
        controller.addServer(server);
      } else {
        controller.updateServer(server);
      }
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.server == null ? '添加服务器' : '编辑服务器'),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.check)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '服务器名称', hintText: '例如：我的远程机器人'),
              validator: (value) => value?.isEmpty ?? true ? '请输入名称' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hostController,
              decoration: const InputDecoration(labelText: '主机地址 (IP/域名)', hintText: '例如：192.168.1.100'),
              validator: (value) => value?.isEmpty ?? true ? '请输入主机地址' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _astrBotPortController,
                    decoration: const InputDecoration(labelText: 'AstrBot 端口'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _napCatPortController,
                    decoration: const InputDecoration(labelText: 'NapCat 端口'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _napCatTokenController,
              decoration: const InputDecoration(
                labelText: 'NapCat WebUI Token',
                hintText: '可选，用于自动登录 NapCat',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'AstrBot OpenAPI Key',
                hintText: '用于原生 UI 交互 (待实现)',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
