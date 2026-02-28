import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/server_config.dart';
import '../../../core/services/password_manager.dart';
import 'native_dashboard_page.dart';
import '../quick_settings/quick_settings_page.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  int _currentIndex = 0;
  bool _showWebConsole = false;
  bool _showExtensionStore = false;
  
  Map<String, dynamic> _webData = {};
  String? _capturedToken;
  String? _pluginErrorMessage;
  
  late final WebViewController _astrBotController;
  late final WebViewController _napCatController;
  late final WebViewController _extensionController;
  late final WebViewController _chatController;
  late final ServerConfig serverConfig;
  bool _initialized = false;

  final GlobalKey<NativeDashboardPageState> _dashboardKey = GlobalKey();
  final GlobalKey<QuickSettingsPageState> _settingsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is ServerConfig) {
      serverConfig = args;
    } else {
      serverConfig = ServerConfig(id: 'local', name: '本地', host: '127.0.0.1');
    }
    _initSystemUI();
    _initControllers();
    _initialized = true;
  }

  void _initControllers() {
    final baseUrl = 'http://${serverConfig.host}:${serverConfig.astrBotPort}';
    _napCatController = _createController('http://${serverConfig.host}:${serverConfig.napCatPort}/webui${serverConfig.napCatToken.isNotEmpty ? "?token=${serverConfig.napCatToken}" : ""}');
    _chatController = _createController(baseUrl, targetHash: '/chat');
    _astrBotController = _createController(baseUrl);
    _extensionController = _createController(baseUrl, targetHash: '/extension#installed');
  }

  WebViewController _createController(String url, {String? targetHash}) {
    final controller = WebViewController();
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'FlutterDataChannel',
        onMessageReceived: (message) {
          try {
            final data = jsonDecode(message.message);
            if (data['type'] == 'token') {
              if (_capturedToken != data['value']) {
                setState(() { _capturedToken = data['value']; });
              }
            } else {
              setState(() { _webData = data; });
            }
          } catch (e) {}
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) => NavigationDecision.navigate,
          onPageFinished: (finishedUrl) {
            _disableZoom(controller);
            if (targetHash != null) {
              controller.runJavaScript("window.location.hash = '$targetHash';");
            }
            if (_capturedToken == null) _injectTokenSpy(controller);
          },
        ),
      )
      ..loadRequest(Uri.parse(url));

    if (controller.platform is AndroidWebViewController) {
      final androidController = controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
      androidController.setMixedContentMode(MixedContentMode.compatibilityMode);
    }
    return controller;
  }

  void _injectTokenSpy(WebViewController controller) {
    const js = """
      (function() {
        const spy = setInterval(() => {
          try {
            const token = localStorage.getItem('token') || localStorage.getItem('auth_token') || localStorage.getItem('access_token');
            if (token) {
              FlutterDataChannel.postMessage(JSON.stringify({'type': 'token', 'value': token}));
              clearInterval(spy);
            }
          } catch(e) { clearInterval(spy); }
        }, 2000);
      })();
    """;
    controller.runJavaScript(js);
  }

  @override
  void dispose() { _restoreSystemUI(); super.dispose(); }
  void _initSystemUI() { SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.white, statusBarIconBrightness: Brightness.dark)); }
  void _restoreSystemUI() { SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light)); }

  void _disableZoom(WebViewController controller) {
    controller.runJavaScript("var meta = document.querySelector('meta[name=\"viewport\"]'); if (meta) meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';");
  }

  void _handleGlobalRefresh() {
    if (_showExtensionStore) {
      _extensionController.reload();
    } else if (_currentIndex == 0) {
      _napCatController.reload();
    } else if (_currentIndex == 1) {
      _chatController.reload();
    } else if (_currentIndex == 2) {
      if (_showWebConsole) {
        _astrBotController.reload();
      } else {
        _dashboardKey.currentState?.refreshWithVersion();
      }
    } else if (_currentIndex == 3) {
      _settingsKey.currentState?.forceRefresh();
    }
  }

  // 🪄 核心：处理从原生页发来的“瞬移”请求喵✨
  void _jumpToWebHash(String hash) {
    setState(() {
      _currentIndex = 2; // 切换到仪表盘对应的 Tab
      _showWebConsole = true; // 开启网页版覆盖
    });
    // 让 Web 控制台跳到指定哈希喵awa
    _astrBotController.runJavaScript("window.location.hash = '$hash';");
  }

  void _setPluginError(String? msg) {
    if (_pluginErrorMessage != msg) {
      setState(() { _pluginErrorMessage = msg; });
    }
  }

  Future<bool> _onWillPop() async {
    if (_showExtensionStore) {
      setState(() => _showExtensionStore = false);
      return false;
    }
    if (_currentIndex == 2 && _showWebConsole) {
      setState(() => _showWebConsole = false);
      return false;
    }
    final controller = _getCurrentController();
    if (controller is WebViewController && await controller.canGoBack()) {
      await controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    final dynamicConfig = serverConfig.copyWith(
      apiKey: _capturedToken ?? serverConfig.apiKey
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _onWillPop()) Get.back();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(_getTitle()),
          elevation: 0.5,
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () async { if (await _onWillPop()) Get.back(); }),
          actions: [
            if (_pluginErrorMessage != null && _pluginErrorMessage!.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.notifications_active, color: Colors.red),
                onPressed: () => Get.defaultDialog(
                  title: '插件运行报警喵🔔',
                  content: Text(_pluginErrorMessage!, style: const TextStyle(fontSize: 12)),
                  confirm: TextButton(onPressed: () => Get.back(), child: const Text('了解了喵')),
                ),
              ),
            if (_showWebConsole || _showExtensionStore)
              IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() { _showWebConsole = false; _showExtensionStore = false; })),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _handleGlobalRefresh)
          ],
        ),
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex, 
              children: [
                WebViewWidget(controller: _napCatController),
                WebViewWidget(controller: _chatController),
                _showWebConsole 
                  ? WebViewWidget(controller: _astrBotController)
                  : NativeDashboardPage(
                      key: _dashboardKey,
                      serverConfig: dynamicConfig,
                      onOpenWebConsole: () => setState(() => _showWebConsole = true),
                      onOpenExtensionStore: () => setState(() => _showExtensionStore = true),
                      onErrorDetected: _setPluginError,
                    ),
                QuickSettingsPage(
                  key: _settingsKey, 
                  serverConfig: dynamicConfig,
                  onJumpToWeb: _jumpToWebHash, // 🪄 挂上瞬移回调喵✨！
                ),
              ],
            ),
            if (_showExtensionStore)
              Positioned.fill(
                child: Container(
                  color: Colors.white,
                  child: WebViewWidget(controller: _extensionController),
                ),
              ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
              _showWebConsole = false;
              _showExtensionStore = false;
            });
            if (index == 1) _chatController.runJavaScript("window.location.hash = '/chat';");
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'NapCat'),
            BottomNavigationBarItem(icon: Icon(Icons.forum_outlined), label: '聊天'),
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: '仪表盘'),
            BottomNavigationBarItem(icon: Icon(Icons.tune_outlined), label: '快捷控制'),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    if (_showExtensionStore) return '插件广场 (Web)';
    if (_currentIndex == 2 && _showWebConsole) return 'Web 控制台';
    return ['NapCat 协议端', 'AI 聊天', 'AstrBot 仪表盘', '快捷控制'][_currentIndex];
  }

  dynamic _getCurrentController() {
    if (_showExtensionStore) return _extensionController;
    return [_napCatController, _chatController, _astrBotController, _extensionController][_currentIndex];
  }
}
