import 'dart:collection';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart' show ChangeNotifier, kIsWeb;
import 'package:flutter_downloader/flutter_downloader.dart';

class DownloadTaskProgress {
  final String taskId;
  final DownloadTaskStatus status;
  final int progress;
  final String? fileName;
  final String? filePath;
  final DateTime updatedAt;

  const DownloadTaskProgress({
    required this.taskId,
    required this.status,
    required this.progress,
    this.fileName,
    this.filePath,
    required this.updatedAt,
  });

  bool get isInProgress =>
      status == DownloadTaskStatus.enqueued ||
      status == DownloadTaskStatus.running ||
      status == DownloadTaskStatus.paused;

  bool get isCompleted => status == DownloadTaskStatus.complete;

  bool get isError =>
      status == DownloadTaskStatus.failed ||
      status == DownloadTaskStatus.canceled;

  DownloadTaskProgress copyWith({
    String? taskId,
    DownloadTaskStatus? status,
    int? progress,
    String? fileName,
    String? filePath,
    DateTime? updatedAt,
  }) {
    return DownloadTaskProgress(
      taskId: taskId ?? this.taskId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DownloadProgressService extends ChangeNotifier {
  DownloadProgressService._();

  static final DownloadProgressService instance = DownloadProgressService._();

  static const String _portName = 'mediakeep_downloader_port';
  static const Duration _staleWindow = Duration(minutes: 20);

  final ReceivePort _receivePort = ReceivePort();
  final Map<String, DownloadTaskProgress> _tasks = {};

  bool _initialized = false;

  UnmodifiableMapView<String, DownloadTaskProgress> get tasks =>
      UnmodifiableMapView(_tasks);

  List<DownloadTaskProgress> get orderedTasks {
    final list = _tasks.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  DownloadTaskProgress? get latestTask {
    if (_tasks.isEmpty) return null;
    final list = orderedTasks;
    return list.isEmpty ? null : list.first;
  }

  Future<void> ensureInitialized() async {
    if (_initialized || kIsWeb) return;

    _initialized = true;

    IsolateNameServer.removePortNameMapping(_portName);
    final registered = IsolateNameServer.registerPortWithName(
      _receivePort.sendPort,
      _portName,
    );

    if (!registered) {
      IsolateNameServer.removePortNameMapping(_portName);
      IsolateNameServer.registerPortWithName(_receivePort.sendPort, _portName);
    }

    _receivePort.listen(_handleProgressMessage);
    FlutterDownloader.registerCallback(downloadCallback, step: 1);

    await hydrateFromDownloader();
  }

  Future<void> hydrateFromDownloader() async {
    if (kIsWeb) return;

    final loaded = await FlutterDownloader.loadTasks();
    if (loaded == null) return;

    final now = DateTime.now();

    for (final task in loaded) {
      final existing = _tasks[task.taskId];
      _tasks[task.taskId] = DownloadTaskProgress(
        taskId: task.taskId,
        status: task.status,
        progress: task.progress.clamp(0, 100),
        fileName: task.filename ?? existing?.fileName,
        filePath: task.filename != null
            ? '${task.savedDir}/${task.filename}'
            : existing?.filePath,
        updatedAt: now,
      );
    }

    _dropStaleTasks(now);
    notifyListeners();
  }

  void registerTaskMetadata({
    required String taskId,
    String? fileName,
    String? filePath,
  }) {
    final current = _tasks[taskId];

    _tasks[taskId] = DownloadTaskProgress(
      taskId: taskId,
      status: current?.status ?? DownloadTaskStatus.enqueued,
      progress: current?.progress ?? 0,
      fileName: fileName ?? current?.fileName,
      filePath: filePath ?? current?.filePath,
      updatedAt: DateTime.now(),
    );

    notifyListeners();
  }

  Future<String?> retryTask(String taskId) async {
    if (kIsWeb) return null;

    final existing = _tasks[taskId];
    final newTaskId = await FlutterDownloader.retry(taskId: taskId);

    if (newTaskId == null) {
      return null;
    }

    if (existing != null) {
      _tasks.remove(taskId);
      _tasks[newTaskId] = existing.copyWith(
        taskId: newTaskId,
        status: DownloadTaskStatus.enqueued,
        progress: 0,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }

    await hydrateFromDownloader();
    return newTaskId;
  }

  void _handleProgressMessage(dynamic data) {
    if (data is! List || data.length < 3) return;

    final dynamic idValue = data[0];
    final dynamic statusValue = data[1];
    final dynamic progressValue = data[2];

    if (idValue is! String || statusValue is! int || progressValue is! int) {
      return;
    }

    final status = _statusFromInt(statusValue);
    final progress = progressValue.clamp(0, 100);
    final current = _tasks[idValue];

    _tasks[idValue] = DownloadTaskProgress(
      taskId: idValue,
      status: status,
      progress: progress,
      fileName: current?.fileName,
      filePath: current?.filePath,
      updatedAt: DateTime.now(),
    );

    _dropStaleTasks(DateTime.now());
    notifyListeners();
  }

  void _dropStaleTasks(DateTime now) {
    final staleIds = <String>[];
    for (final entry in _tasks.entries) {
      final age = now.difference(entry.value.updatedAt);
      if (age > _staleWindow) {
        staleIds.add(entry.key);
      }
    }

    for (final staleId in staleIds) {
      _tasks.remove(staleId);
    }
  }

  static DownloadTaskStatus _statusFromInt(int rawStatus) {
    switch (rawStatus) {
      case 1:
        return DownloadTaskStatus.enqueued;
      case 2:
        return DownloadTaskStatus.running;
      case 3:
        return DownloadTaskStatus.complete;
      case 4:
        return DownloadTaskStatus.failed;
      case 5:
        return DownloadTaskStatus.canceled;
      case 6:
        return DownloadTaskStatus.paused;
      default:
        return DownloadTaskStatus.undefined;
    }
  }

  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName(_portName);
    send?.send([id, status, progress]);
  }
}
