import 'package:get/get.dart';
import '../pages/server_management/server_list_page.dart';
import '../pages/webview/webview_page.dart';
import '../pages/terminal/terminal_page.dart';
import '../pages/mcp/mcp_servers_page.dart';
import '../pages/plugins/plugins_page.dart'; 
import '../pages/napcat/napcat_page.dart'; 

class AppRoutes {
  static const String serverList = '/server_list';
  static const String webview = '/webview';
  static const String terminal = '/terminal';
  static const String mcpServers = '/mcp_servers';
  static const String plugins = '/plugins';
  static const String napcat = '/napcat'; 

  static final routes = [
    GetPage(
      name: serverList,
      page: () => const ServerListPage(),
      transition: Transition.fadeIn, // 首页淡入，干净利落喵✨
    ),
    GetPage(
      name: webview,
      page: () => const WebViewPage(),
      // 🪄 核心优化：从服务器列表进入控制台，使用 iOS 感十足的侧滑
      transition: Transition.cupertino, 
      transitionDuration: const Duration(milliseconds: 400),
    ),
    GetPage(
      name: terminal,
      page: () => const TerminalPage(),
      transition: Transition.cupertino, // 终端也用侧滑喵awa
    ),
    GetPage(
      name: mcpServers,
      page: () => const McpServersPage(),
      transition: Transition.downToUp, // 向上钻出，有“工具箱”的感觉
    ),
    GetPage(
      name: plugins,
      page: () => const PluginsPage(),
      transition: Transition.downToUp, 
    ),
    GetPage(
      name: napcat,
      page: () => const NapCatPage(),
      transition: Transition.rightToLeft,
    ),
  ];
}
