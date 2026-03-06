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
import 'ui/controllers/server_controller.dart'; // 🪄 引入控制器
import 'ui/routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  const String packageName = 'com.astrbot.astrbot_android';
  RuntimeEnvir.initEnvirWithPackageName(packageName);
  
  await initSettingStore(RuntimeEnvir.configPath);

  // 🪄 核心：在 App 启动时就创建全局单例，永不销毁喵✨
  Get.put(ServerController());

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
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
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
