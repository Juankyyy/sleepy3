import 'package:sleepy3/features/backup/data/file_picker_history_file_gateway.dart';

/// In-memory [SleepHistoryFileGateway] for Settings tests.
class FakeSleepHistoryFileGateway implements SleepHistoryFileGateway {
  FakeSleepHistoryFileGateway({
    this.pickContents,
    this.pickError,
    this.saveResult = true,
    this.saveError,
  });

  /// Text returned by [pick]; null simulates the user cancelling.
  String? pickContents;

  /// When set, [pick] throws it.
  Object? pickError;

  /// What [save] returns; false simulates the user cancelling.
  bool saveResult;

  /// When set, [save] throws it.
  Object? saveError;

  int pickCalls = 0;
  int saveCalls = 0;
  String? savedFileName;
  String? savedContents;
  String? savedDialogTitle;

  @override
  Future<String?> pick({required String dialogTitle}) async {
    pickCalls++;
    final error = pickError;
    if (error != null) throw error;
    return pickContents;
  }

  @override
  Future<bool> save({
    required String fileName,
    required String contents,
    required String dialogTitle,
  }) async {
    saveCalls++;
    final error = saveError;
    if (error != null) throw error;
    savedFileName = fileName;
    savedContents = contents;
    savedDialogTitle = dialogTitle;
    return saveResult;
  }
}
