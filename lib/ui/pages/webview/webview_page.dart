import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    
    _initChatCapture();
    _initNapCatCapture();
    
    _initSystemUI();
    _initialized = true;
  }

  WebViewController _createController(String url, Function(String) onToken, {Function(WebViewController)? onPageLoad}) {
    late final WebViewController ctrl;
    ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel('SpyChannel', onMessageReceived: (msg) => onToken(msg.message))
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          if (request.url.contains(serverConfig.host) || request.url.contains('localhost')) {
            return NavigationDecision.navigate;
          }
          launchUrl(Uri.parse(request.url), mode: LaunchMode.externalApplication);
          return NavigationDecision.prevent;
        },
        onPageFinished: (_) {
          if (onPageLoad != null) onPageLoad(ctrl);
          ctrl.runJavaScript("""
            setInterval(() => {
              const t = localStorage.getItem('token') || localStorage.getItem('auth_token');
              if (t) SpyChannel.postMessage(t);
            }, 1500);
          """);
        },
      ))
      ..loadRequest(Uri.parse(url));
    return ctrl;
  }

  void _initChatCapture() {
    _chatController = _createController('http://${serverConfig.host}:${serverConfig.astrBotPort}/chat', (token) {
      if (_astrBotToken == token) return;
      setState(() { _astrBotToken = token; });
      box?.put('session_astrbot_${serverConfig.id}', token);
    });
  }

  void _initNapCatCapture() {
    final String napCatUrl = 'http://${serverConfig.host}:${serverConfig.napCatPort}/webui';
    _napCatWebController = _createController(
      napCatUrl, 
      (token) {
        if (token.length < 50 || _napCatToken == token) return;
        setState(() { _napCatToken = token; });
        box?.put('session_napcat_${serverConfig.id}', token);
        _napCatControl.init(serverConfig, token: token);
      },
      onPageLoad: (ctrl) {
        final masterToken = serverConfig.napCatToken;
        if (masterToken.isNotEmpty) {
          ctrl.runJavaScript("""
            (function() {
              const tryLogin = setInterval(() => {
                const pwdInput = document.querySelector('input[type="password"]') || document.querySelector('input[placeholder*="Token"]');
                const btn = document.querySelector('button');
                if (pwdInput && btn) {
                  pwdInput.value = '$masterToken';
                  pwdInput.dispatchEvent(new Event('input', { bubbles: true }));
                  btn.click();
                  clearInterval(tryLogin);
                }
              }, 1000);
              setTimeout(() => clearInterval(tryLogin), 10000);
            })();
          """);
        }
      }
    );
  }

  Future<void> _handleBack() async {
    if (_showExtensionStore) { setState(() => _showExtensionStore = false); return; }
    if (_showWebConsole) { setState(() => _showWebConsole = false); return; }
    
    WebViewController? activeCtrl;
    if (_currentIndex == 0) activeCtrl = _chatController;
    if (_currentIndex == 2 && _napCatToken == null) activeCtrl = _napCatWebController;
    
    if (activeCtrl != null && await activeCtrl.canGoBack()) {
      await activeCtrl.goBack();
      return; 
    }
    
    // 🪄 优化：明确执行 Get.back()，绝不触发外部 Activity 退出喵✨
    if (Get.currentRoute == '/webview' || Navigator.canPop(context)) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final dynamicConfig = serverConfig.copyWith(apiKey: _astrBotToken ?? serverConfig.apiKey);

    return PopScope(
      canPop: false, 
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(_showExtensionStore ? '插件列表' : ['AI 聊天', '仪表盘', 'NapCat 管理', '无用的设置'][_currentIndex]),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _handleBack(),
          ),
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
                  : NativeDashboardPage(
                      key: _dashboardKey, 
                      serverConfig: dynamicConfig, 
                      onOpenWebConsole: () => setState(() => _showWebConsole = true),
                      onOpenExtensionStore: () => setState(() => _showExtensionStore = true),
                    ),
                _napCatToken == null ? WebViewWidget(controller: _napCatWebController) : const NapCatPage(),
                QuickSettingsPage(key: _settingsKey, serverConfig: dynamicConfig),
              ],
            ),
            if (_showExtensionStore)
              Positioned.fill(child: Container(color: Colors.white, child: WebViewWidget(controller: _getExtensionController()))),
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
    else if (_currentIndex == 2) {
      if (_napCatToken == null) _napCatWebController.reload();
      else _napCatControl.refreshStatus();
    }
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
