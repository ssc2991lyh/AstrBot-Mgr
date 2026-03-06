import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart'; // 🪄 引入分帧调度喵✨
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:global_repository/global_repository.dart'; 
import 'package:settings/settings.dart'; 
import 'package:url_launcher/url_launcher.dart'; 
import '../../../core/models/server_config.dart';
import '../napcat/napcat_page.dart'; 
import 'native_dashboard_page.dart';
import '../quick_settings/quick_settings_page.dart';
import '../../controllers/napcat_controller.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  int _currentIndex = 0;
  bool _showWebConsole = false;
  bool _showExtensionStore = false;
  
  String? _astrBotToken;
  String? _napCatToken;
  
  // 🪄 核心优化：改回非空初始化，但延迟加载 URL，防止断言错误喵✨
  late final WebViewController _chatController;
  late final WebViewController _napCatWebController; 
  WebViewController? _extensionController; 
  
  late final ServerConfig serverConfig;
  bool _initialized = false;

  final GlobalKey<NativeDashboardPageState> _dashboardKey = GlobalKey();
  final GlobalKey<QuickSettingsPageState> _settingsKey = GlobalKey();
  late final NapCatController _napCatControl;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    serverConfig = args is ServerConfig ? args : ServerConfig(id: 'local', name: '本地', host: '127.0.0.1');
    
    _astrBotToken = box?.get('session_astrbot_${serverConfig.id}');
    _napCatToken = box?.get('session_napcat_${serverConfig.id}');
    
    _napCatControl = Get.put(NapCatController());
    if (_napCatToken != null) {
      _napCatControl.init(serverConfig, token: _napCatToken);
    }
    
    // 🪄 1. 同步创建控制器实例 (防止 postMessage was null)
    _chatController = _buildBaseController('chat');
    _napCatWebController = _buildBaseController('napcat');

    // 🪄 2. 分帧启动加载，确保 UI 线程不卡死喵✨
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _startLoading();
    });
    
    _initSystemUI();
  }

  WebViewController _buildBaseController(String tag) {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel('SpyChannel_$tag', onMessageReceived: (msg) {
        if (tag == 'chat') _onChatToken(msg.message);
        else _onNapCatToken(msg.message);
      });
  }

  void _startLoading() {
    // 延迟加载，防止启动瞬间 GPU 爆炸喵 awa
    _chatController.setNavigationDelegate(_buildDelegate('chat'));
    _chatController.loadRequest(Uri.parse('http://${serverConfig.host}:${serverConfig.astrBotPort}/chat'));

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _napCatWebController.setNavigationDelegate(_buildDelegate('napcat'));
      _napCatWebController.loadRequest(Uri.parse('http://${serverConfig.host}:${serverConfig.napCatPort}/webui'));
      setState(() => _initialized = true);
    });
  }

  NavigationDelegate _buildDelegate(String tag) {
    return NavigationDelegate(
      onNavigationRequest: (req) {
        if (req.url.contains(serverConfig.host) || req.url.contains('localhost')) return NavigationDecision.navigate;
        launchUrl(Uri.parse(req.url), mode: LaunchMode.externalApplication);
        return NavigationDecision.prevent;
      },
      onPageFinished: (_) {
        if (tag == 'napcat') _injectLoginScript();
        _injectSpyScript(tag);
      },
    );
  }

  void _injectLoginScript() {
    final masterToken = serverConfig.napCatToken;
    if (masterToken.isEmpty) return;
    _napCatWebController.runJavaScript("""
      (function() {
        const t = setInterval(() => {
          const inp = document.querySelector('input[type="password"]') || document.querySelector('input[placeholder*="Token"]');
          const btn = document.querySelector('button');
          if (inp && btn) {
            inp.value = '$masterToken';
            inp.dispatchEvent(new Event('input', { bubbles: true }));
            inp.dispatchEvent(new Event('change', { bubbles: true }));
            setTimeout(() => btn.click(), 100);
            clearInterval(t);
          }
        }, 1000);
        setTimeout(() => clearInterval(t), 15000);
      })();
    """);
  }

  void _injectSpyScript(String tag) {
    final controller = tag == 'chat' ? _chatController : _napCatWebController;
    controller.runJavaScript("setInterval(() => { const t = localStorage.getItem('token') || localStorage.getItem('auth_token'); if (t) window.SpyChannel_$tag.postMessage(t); }, 2000);");
  }

  void _onChatToken(String t) {
    if (_astrBotToken == t) return;
    setState(() => _astrBotToken = t);
    box?.put('session_astrbot_${serverConfig.id}', t);
  }

  void _onNapCatToken(String t) {
    if (t.length < 50 || _napCatToken == t) return;
    setState(() => _napCatToken = t);
    box?.put('session_napcat_${serverConfig.id}', t);
    _napCatControl.init(serverConfig, token: t);
  }

  Future<void> _handleBack() async {
    if (_showExtensionStore) { setState(() => _showExtensionStore = false); return; }
    if (_showWebConsole) { setState(() => _showWebConsole = false); return; }
    
    WebViewController? active = _currentIndex == 0 ? _chatController : (_currentIndex == 2 && _napCatToken == null ? _napCatWebController : null);
    if (active != null && await active.canGoBack()) { await active.goBack(); return; }
    
    // 🪄 终极方案：手动 Pop 路由，不给系统触发 Activity 退出的机会喵✨
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const Scaffold(body: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    final dynamicConfig = serverConfig.copyWith(apiKey: _astrBotToken ?? serverConfig.apiKey);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async { if (!didPop) await _handleBack(); },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(_showExtensionStore ? '插件列表' : ['AI 聊天', '仪表盘', 'NapCat 管理', '无用的设置'][_currentIndex]),
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _handleBack),
          actions: [
            if (_currentIndex == 1 && !_showExtensionStore)
              IconButton(icon: Icon(_showWebConsole ? Icons.phonelink : Icons.web), onPressed: () => setState(() => _showWebConsole = !_showWebConsole)),
            IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _handleGlobalRefresh)
          ],
        ),
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: [
                WebViewWidget(controller: _chatController),
                _showWebConsole 
                  ? WebDashboard(url: 'http://${serverConfig.host}:${serverConfig.astrBotPort}')
                  : NativeDashboardPage(key: _dashboardKey, serverConfig: dynamicConfig, onOpenWebConsole: () => setState(() => _showWebConsole = true), onOpenExtensionStore: () => setState(() => _showExtensionStore = true)),
                _napCatToken == null ? WebViewWidget(controller: _napCatWebController) : const NapCatPage(),
                QuickSettingsPage(key: _settingsKey, serverConfig: dynamicConfig),
              ],
            ),
            if (_showExtensionStore) Positioned.fill(child: Container(color: Colors.white, child: WebViewWidget(controller: _getExtensionController()))),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (index) => setState(() { _currentIndex = index; _showWebConsole = false; _showExtensionStore = false; }),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.forum_outlined), label: '聊天'),
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: '仪表盘'),
            BottomNavigationBarItem(icon: Icon(Icons.pets_outlined), label: 'NapCat'),
            BottomNavigationBarItem(icon: Icon(Icons.tune_outlined), label: '无用的设置'),
          ],
        ),
      ),
    );
  }

  void _handleGlobalRefresh() {
    if (_showExtensionStore) _extensionController?.reload();
    else if (_currentIndex == 0) _chatController.reload();
    else if (_currentIndex == 1) _dashboardKey.currentState?.refreshWithVersion();
    else if (_currentIndex == 2) _napCatToken == null ? _napCatWebController.reload() : _napCatControl.refreshStatus();
  }

  WebViewController _getExtensionController() => _extensionController ??= WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted)..loadRequest(Uri.parse('http://${serverConfig.host}:${serverConfig.astrBotPort}/extension#installed'));
  @override void dispose() { _restoreSystemUI(); super.dispose(); }
  void _initSystemUI() { SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.white, statusBarIconBrightness: Brightness.dark)); }
  void _restoreSystemUI() { SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light)); }
}

class WebDashboard extends StatelessWidget {
  final String url;
  const WebDashboard({super.key, required this.url});
  @override Widget build(BuildContext context) { return WebViewWidget(controller: WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted)..loadRequest(Uri.parse(url))); }
}
