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
  // 1. 引擎初始化必须在最前
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. 🪄 核心修复：数据库初始化必须同步等待！不能 unawaited 喵✨
  const String packageName = 'com.astrbot.astrbot_android';
  RuntimeEnvir.initEnvirWithPackageName(packageName);
  
  // 必须先开门，ServerController 才能拿到数据喵awa
  await initSettingStore(RuntimeEnvir.configPath);

  // 3. 只有权限和前台服务这种“身外之物”才适合异步喵
  unawaited(_backgroundTasks());

  runApp(const AstrBot());
}

Future<void> _backgroundTasks() async {
  if (Platform.isAndroid) {
    await [
      Permission.notification,
      Permission.manageExternalStorage,
    ].request();
  }
  
  ForegroundServiceManager.init();
  await ForegroundServiceManager.startService();
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
    Future.delayed(const Duration(seconds: 10), _startMonitor);
  }

  void _startMonitor() {
    _serviceMonitorTimer?.cancel();
    _serviceMonitorTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (!await ForegroundServiceManager.isRunningService() && 
          !ForegroundServiceManager.userClickedStopButton) {
        await ForegroundServiceManager.startService();
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
      title: 'AstrBot Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        splashFactory: InkRipple.splashFactory,
      ),
      initialRoute: AppRoutes.serverList,
      getPages: AppRoutes.routes,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
    );
  }
}
