import 'dart:io';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:global_repository/global_repository.dart';

/// 前台服务管理类
class ForegroundServiceManager {
  static bool _userClickedStopButton = false;

  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'astrbot_keep_alive_channel',
        channelName: 'AstrBot后台服务',
        channelDescription: '保持AstrBot在后台运行',
        channelImportance: NotificationChannelImportance.MIN,
        priority: NotificationPriority.MIN,
        visibility: NotificationVisibility.VISIBILITY_PUBLIC,
      ),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: false),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  static Future<ServiceRequestResult> startService() async {
    _userClickedStopButton = false;
    Log.i('检查前台服务状态...', tag: 'ForegroundService');

    // 核心修正：如果已经在跑了，就别再重启它啦喵✨！
    if (await FlutterForegroundTask.isRunningService) {
      Log.i('服务已经在乖乖工作啦喵awa', tag: 'ForegroundService');
      return const ServiceRequestSuccess(); 
    }

    Log.i('启动新服务中...', tag: 'ForegroundService');
    return FlutterForegroundTask.startService(
      serviceId: 1001,
      notificationTitle: 'AstrBot 正在后台运行',
      notificationText: '确保你的连接稳定喵awa',
      notificationButtons: [
        const NotificationButton(id: 'btn_stop', text: '停止运行'),
      ],
      callback: startCallback,
    );
  }

  static Future<ServiceRequestResult> stopService() async {
    _userClickedStopButton = true;
    return FlutterForegroundTask.stopService();
  }

  static bool get userClickedStopButton => _userClickedStopButton;
  static Future<bool> isRunningService() => FlutterForegroundTask.isRunningService;
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(KeepAliveTaskHandler());
}

class KeepAliveTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    Log.i('前台服务正式就位喵awa', tag: 'KeepAliveTaskHandler');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTaskRemoved) async {
    Log.i('前台服务被销毁，isTaskRemoved: $isTaskRemoved', tag: 'KeepAliveTaskHandler');

    // 只有在非用户主动停止的情况下，才尝试重建喵✨
    if (!ForegroundServiceManager.userClickedStopButton) {
      Log.w('检测到服务意外离岗，准备唤醒喵...', tag: 'KeepAliveTaskHandler');
      // 稍微等一下下，防止跟系统的清理动作撞车喵
      await Future.delayed(const Duration(seconds: 2));
      await ForegroundServiceManager.startService();
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'btn_stop') {
      ForegroundServiceManager.stopService().then((_) => exit(0));
    }
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }
}
