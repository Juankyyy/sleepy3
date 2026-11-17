import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Opens the platform document picker for a Sleepy3 history file.
///
/// Kept behind an interface so tests and previews never touch the plugin.
abstract interface class SleepHistoryFileGateway {
  /// Lets the user choose where to save [contents].
  ///
  /// Returns false when the user cancels the system dialog.
  Future<bool> save({
    required String fileName,
    required String contents,
    required String dialogTitle,
  });

  /// Lets the user pick a history file and returns its text.
  ///
  /// Returns null when the user cancels the system dialog.
  Future<String?> pick({required String dialogTitle});
}

/// [SleepHistoryFileGateway] over the Android Storage Access Framework.
class FilePickerHistoryFileGateway implements SleepHistoryFileGateway {
  const FilePickerHistoryFileGateway();

  @override
  Future<bool> save({
    required String fileName,
    required String contents,
    required String dialogTitle,
  }) async {
    final uri = await FilePicker.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      mimeType: 'application/json',
      bytes: Uint8List.fromList(utf8.encode(contents)),
    );
    return uri != null;
  }

  @override
  Future<String?> pick({required String dialogTitle}) async {
    final file = await FilePicker.pickFile(
      dialogTitle: dialogTitle,
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (file == null) return null;
    return utf8.decode(await file.readAsBytes());
  }
}
