import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:global_repository/global_repository.dart';
import 'package:tar/tar.dart';
import 'package:xterm/xterm.dart';

/// 收集 .tar.gz 中的硬链接映射
Future<Map<String, String>> getHardLinkMap(String tarGzPath) async {
  final result = <String, String>{};
  final stream = File(tarGzPath).openRead().transform(gzip.decoder);
  final reader = TarReader(stream);

  while (await reader.moveNext()) {
    final entry = reader.current;
    if (entry.type == TypeFlag.link) {
      final name = entry.header.name;
      final target = entry.header.linkName ?? '';
      if (name.isNotEmpty && target.isNotEmpty) {
        result[name] = target;
      }
    }
  }
  return result;
}

/// 使用 archive_io + TarFile 收集 .tar.gz 中的硬链接映射
Future<Map<String, String>> getHardLinkMapByArchive(String tarGzPath) async {
  final result = <String, String>{};
  final input = InputFileStream(tarGzPath);
  try {
    final memOut = OutputMemoryStream();
    GZipDecoder().decodeStream(input, memOut);
    final tarBytes = memOut.getBytes();

    final mem = InputMemoryStream(tarBytes);
    while (!mem.isEOS) {
      final tf = TarFile.read(mem);
      if (tf.filename.isEmpty) break;
      if (tf.typeFlag == '1') {
        final name = tf.filename;
        final target = tf.nameOfLinkedFile;
        if (name.isNotEmpty && target != null && target.isNotEmpty) {
          result[name] = target;
        }
      }
    }
  } finally {
    input.close();
  }
  return result;
}

// MethodChannel 适配
MethodChannel _channel = const MethodChannel('astrbot_channel');

/// 获取 Apk So 库路径 (Android 专用，iOS 返回空或沙盒路径)
Future<String> getLibPath() async {
  if (Platform.isIOS) {
    return ''; // iOS 不支持动态加载外部 so 库，返回空字符串避开逻辑
  }
  try {
    return await _channel.invokeMethod('lib_path');
  } catch (e) {
    Log.e('获取 LibPath 失败: $e');
    return '';
  }
}

Pty createPTY({
  String? shell,
  int rows = 25,
  int columns = 80,
}) {
  Map<String, String> envir = Map.from(Platform.environment);
  envir['HOME'] = RuntimeEnvir.homePath;
  envir['TERMUX_PREFIX'] = RuntimeEnvir.usrPath;
  envir['TERM'] = 'xterm-256color';
  envir['PATH'] = RuntimeEnvir.path;
  envir['PROOT_LOADER'] = '${RuntimeEnvir.binPath}/loader';
  envir['LD_LIBRARY_PATH'] = RuntimeEnvir.binPath;
  envir['PROOT_TMP_DIR'] = RuntimeEnvir.tmpPath;

  // iOS 限制较多，pty 可能需要特殊处理或仅在 Android 开启
  return Pty.start(
    '${RuntimeEnvir.binPath}/${shell ?? 'bash'}',
    arguments: [],
    environment: envir,
    workingDirectory: RuntimeEnvir.homePath,
    rows: rows,
    columns: columns,
  );
}

extension TerminalExt on Terminal {
  void writeProgress(String data) {
    write('\x1b[31m- $data\x1b[0m\n\r');
  }
}

extension PTYExt on Pty {
  void writeString(String data) {
    write(Uint8List.fromList(utf8.encode(data)));
  }

  Future<void> defineFunction(String function) async {
    Log.i('define function start');
    Completer defineFunctionLock = Completer();
    Directory tmpDir = Directory(RuntimeEnvir.tmpPath);
    await tmpDir.create(recursive: true);
    String shortHash = hashCode.toRadixString(16).substring(0, 4);
    File shellFile = File('${tmpDir.path}/shell$shortHash');
    String patchFunction = '$function\n'
        r'''
    #printf "\033[A"
    #printf "\033[2K"''';
    await shellFile.writeAsString(patchFunction);
    shellFile.watch(events: FileSystemEvent.delete).listen((event) {
      defineFunctionLock.complete();
    });
    File('${tmpDir.path}/shell${shortHash}backup').writeAsStringSync(function);
    writeString('source ${shellFile.path} &&');
    writeString('rm -rf ${shellFile.path} \n');
    await defineFunctionLock.future;
    Log.i('define function -> done');
  }
}
