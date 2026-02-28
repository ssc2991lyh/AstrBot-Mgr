import 'dart:convert';
import 'package:get/get.dart';
import '../pages/server_management/server_list_page.dart';
import '../pages/webview/webview_page.dart';
import '../pages/terminal/terminal_page.dart';
import '../pages/mcp/mcp_servers_page.dart';
import '../pages/plugins/plugins_page.dart'; // 引入新成员喵✨

class AppRoutes {
  static const String serverList = '/server_list';
  static const String webview = '/webview';
  static const String terminal = '/terminal';
  static const String mcpServers = '/mcp_servers';
  static const String plugins = '/plugins'; // 注册新路由喵awa

  static final routes = [
    GetPage(
      name: serverList,
      page: () => const ServerListPage(),
    ),
    GetPage(
      name: webview,
      page: () => const WebViewPage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: terminal,
      page: () => const TerminalPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: mcpServers,
      page: () => const McpServersPage(),
      transition: Transition.downToUp,
    ),
    GetPage(
      name: plugins,
      page: () => const PluginsPage(),
      transition: Transition.downToUp, // 同样从下面钻出来喵✨
    ),
  ];
}
