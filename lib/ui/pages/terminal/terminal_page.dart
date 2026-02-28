import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xterm/xterm.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:settings/settings.dart'; // 引入盒子喵✨
import '../../../core/models/server_config.dart';

class TerminalPage extends StatefulWidget {
  const TerminalPage({super.key});

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  final terminal = Terminal(maxLines: 10000);
  SSHClient? _client;
  late final ServerConfig server;
  late final String username;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    server = args['server'];
    username = args['user'];
    Future.delayed(const Duration(milliseconds: 500), _connect);
  }

  // 🪄 密码弹窗带“记住密码”喵awa
  Future<String?> _showPasswordDialog() async {
    final controller = TextEditingController();
    bool remember = true; // 默认记住喵✨

    return await Get.dialog<String>(
      StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text('请输入 SSH 密码喵✨'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: remember,
                    onChanged: (v) => setState(() => remember = v ?? false),
                  ),
                  const Text('记住密码喵awa', style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('取消')),
            ElevatedButton(
              onPressed: () {
                final pwd = controller.text;
                if (remember && pwd.isNotEmpty) {
                  // 把密码存在盒子里喵✨
                  box?.put('ssh_pwd_${server.id}', pwd);
                }
                Get.back(result: pwd);
              },
              child: const Text('确定'),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _connect() async {
    terminal.write('正在建立连接喵awa: $username@${server.host}...\r\n');
    try {
      final socket = await SSHSocket.connect(server.host, 22, timeout: const Duration(seconds: 15));
      
      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () async {
          // 1. 先去盒子里找找看喵awa
          final String? savedPwd = box?.get('ssh_pwd_${server.id}');
          if (savedPwd != null && savedPwd.isNotEmpty) {
            terminal.write('正在使用记住的密码认证喵✨...\r\n');
            return savedPwd;
          }
          // 2. 没有的话再弹窗喵✨
          return await _showPasswordDialog();
        },
      );

      terminal.write('正在认证中喵✨...\r\n');
      final session = await _client!.shell();
      
      if (mounted) setState(() => _isConnected = true);
      terminal.write('连接成功喵！(●\'◡\'●)\r\n\r\n');

      session.stdout.listen((data) => terminal.write(utf8.decode(data)));
      session.stderr.listen((data) => terminal.write(utf8.decode(data)));
      terminal.onOutput = (data) => session.write(utf8.encode(data));

      await session.done;
    } catch (e) {
      terminal.write('\r\n连接失败了喵xwx: $e\r\n');
      // 如果连接失败，清空存错的密码喵！
      box?.delete('ssh_pwd_${server.id}');
    } finally {
      if (mounted) setState(() => _isConnected = false);
    }
  }

  @override
  void dispose() {
    _client?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('$username@${server.host}', style: const TextStyle(fontSize: 14)),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isConnected ? Icons.link : Icons.link_off, color: _isConnected ? Colors.green : Colors.red),
            onPressed: _isConnected ? null : _connect,
          ),
        ],
      ),
      body: SafeArea(
        child: TerminalView(
          terminal,
          padding: const EdgeInsets.all(8),
          backgroundOpacity: 1,
        ),
      ),
    );
  }
}
