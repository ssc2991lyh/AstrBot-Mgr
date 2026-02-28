import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:global_repository/global_repository.dart';
import 'package:settings/settings.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

import 'generated/l10n.dart';
import 'core/services/foreground_service.dart';
import 'ui/routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. 请求通知权限 (双端通用)
  await Permission.notification.request();
  
  // 2. 权限适配：仅 Android 需要管理外部存储权限
  if (Platform.isAndroid) {
    if (await Permission.manageExternalStorage.isDenied) {
      await Permission.manageExternalStorage.request();
    }
  }
  
  // 3. 初始化前台服务 (iOS 需要在 Info.plist 配置后台运行模式)
  ForegroundServiceManager.init();
  await ForegroundServiceManager.startService();
  
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [
    SystemUiOverlay.top,
  ]);

  // 4. 环境初始化适配：根据平台动态获取包名/Bundle ID
  // 确保在 iOS 下 RuntimeEnvir 也能正确初始化路径
  String packageName = 'com.astrbot.astrbot_android';
  if (Platform.isIOS) {
    packageName = 'com.astrbot.astrbot_ios'; 
  }
  RuntimeEnvir.initEnvirWithPackageName(packageName);
  await initSettingStore(RuntimeEnvir.configPath);

  runApp(const AstrBot());
}

class AstrBot extends StatefulWidget {
  const AstrBot({super.key});

  @override
  State<AstrBot> createState() => _AstrBotState();
}

class _AstrBotState extends State<AstrBot> with WidgetsBindingObserver {
  Timer? _serviceMonitorTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 仅在 Android 上启动服务保活监控，iOS 机制不同由系统管理
    if (Platform.isAndroid) {
      _startServiceMonitor();
    }
  }

  void _startServiceMonitor() {
    _serviceMonitorTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      final isRunning = await ForegroundServiceManager.isRunningService();
      final userClickedStop = ForegroundServiceManager.userClickedStopButton;

      if (!isRunning && !userClickedStop) {
        try {
          await ForegroundServiceManager.startService();
        } catch (e) {
          Log.e('服务重启失败: $e', tag: 'AstrBot');
        }
      }
    });
  }

  @override
  void dispose() {
    _serviceMonitorTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'AstrBot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.primaries[3],
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.primaries[3],
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system, 
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      initialRoute: AppRoutes.serverList,
      getPages: AppRoutes.routes,
    );
  }
}
