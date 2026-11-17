import 'dart:convert';

import '../../sleep_tracking/domain/sleep_session.dart';

/// Identifier written to every Sleepy3 history file.
const sleepHistoryFileFormat = 'sleepy3.sleep-history';

/// The newest history file layout this build can read.
const sleepHistoryFileVersion = 1;

/// Why a history file could not be read.
enum SleepHistoryFileError {
  /// The file is not valid JSON or does not have the expected shape.
  unreadable,

  /// The JSON is valid but it is not a Sleepy3 history file.
  notSleepy3,

  /// The file was written by a newer version of Sleepy3.
  newerVersion,
}

/// A history file that cannot be imported, with the reason.
class SleepHistoryFileException implements Exception {
  const SleepHistoryFileException(this.error);

  final SleepHistoryFileError error;

  @override
  String toString() => 'SleepHistoryFileException($error)';
}

/// One closed session inside a history file.
///
/// Times are Unix milliseconds so the exact instants survive a round-trip
/// without depending on the device time zone. Health Connect ids are optional
/// metadata: they let a later import recognise a record that already exists.
class SleepHistoryEntry {
  const SleepHistoryEntry({
    required this.startedAt,
    required this.endedAt,
    this.isDownloaded = false,
    this.healthRecordId,
    this.healthClientRecordId,
    this.sourceId,
  });

  final DateTime startedAt;
  final DateTime endedAt;

  /// Whether the exported row was a read-only copy downloaded from Health
  /// Connect. Imported copies keep that provenance.
  final bool isDownloaded;

  /// Health Connect UUID, when the exported row had one.
  final String? healthRecordId;

  /// Stable Health Connect client id, when the exported row had one.
  final String? healthClientRecordId;

  /// Package of the app that wrote a downloaded record, when known.
  final String? sourceId;

  SleepSession toSession() => SleepSession(
    startedAt: startedAt,
    endedAt: endedAt,
    isDownloaded: isDownloaded,
    sourceId: sourceId,
  );
}

/// A decoded Sleepy3 history file.
class SleepHistoryFile {
  const SleepHistoryFile({
    required this.exportedAt,
    required this.sessions,
    this.invalidEntries = 0,
  });

  /// Builds a file from the closed sessions on screen.
  ///
  /// [markAsDownloaded] marks every entry as a read-only Health Connect copy.
  /// The Google Health view reads Health Connect directly, so its rows are
  /// snapshots of platform records and must keep that provenance when the file
  /// is imported.
  factory SleepHistoryFile.fromSessions(
    Iterable<SleepSession> sessions, {
    required DateTime exportedAt,
    bool markAsDownloaded = false,
  }) {
    final entries = <SleepHistoryEntry>[];
    for (final session in sessions) {
      final endedAt = session.endedAt;
      if (endedAt == null) continue;
      entries.add(
        SleepHistoryEntry(
          startedAt: session.startedAt,
          endedAt: endedAt,
          isDownloaded: markAsDownloaded || session.isDownloaded,
          healthRecordId: session.healthRecordId,
          healthClientRecordId: session.healthClientRecordId,
          sourceId: session.sourceId,
        ),
      );
    }
    entries.sort((a, b) => a.startedAt.compareTo(b.startedAt));
    return SleepHistoryFile(
      exportedAt: exportedAt,
      sessions: List.unmodifiable(entries),
    );
  }

  /// Decodes [source] as a Sleepy3 history file.
  ///
  /// A structurally invalid file throws [SleepHistoryFileException]. Entries
  /// that are open, zero-length or outside the recordable range are counted in
  /// [invalidEntries] and left out of [sessions], so the preview can explain
  /// them before anything is written.
  factory SleepHistoryFile.decode(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const SleepHistoryFileException(SleepHistoryFileError.unreadable);
    }

    if (decoded is! Map<String, dynamic>) {
      throw const SleepHistoryFileException(SleepHistoryFileError.notSleepy3);
    }
    if (decoded['format'] != sleepHistoryFileFormat) {
      throw const SleepHistoryFileException(SleepHistoryFileError.notSleepy3);
    }

    final version = decoded['version'];
    if (version is! int || version < 1) {
      throw const SleepHistoryFileException(SleepHistoryFileError.notSleepy3);
    }
    if (version > sleepHistoryFileVersion) {
      throw const SleepHistoryFileException(SleepHistoryFileError.newerVersion);
    }

    final rawSessions = decoded['sessions'];
    if (rawSessions is! List) {
      throw const SleepHistoryFileException(SleepHistoryFileError.notSleepy3);
    }

    final entries = <SleepHistoryEntry>[];
    var invalid = 0;
    for (final raw in rawSessions) {
      final entry = _entryFrom(raw);
      if (entry == null) {
        invalid++;
      } else {
        entries.add(entry);
      }
    }
    entries.sort((a, b) => a.startedAt.compareTo(b.startedAt));

    return SleepHistoryFile(
      exportedAt: _readExportedAt(decoded['exportedAt']),
      sessions: List.unmodifiable(entries),
      invalidEntries: invalid,
    );
  }

  /// When the file was written; used for diagnostics and previews.
  final DateTime exportedAt;

  /// The valid, closed sessions in the file, oldest first.
  final List<SleepHistoryEntry> sessions;

  /// Entries that were present but cannot be imported.
  final int invalidEntries;

  /// Whether the file has no importable session.
  bool get isEmpty => sessions.isEmpty;

  /// Encodes this file as indented JSON with a stable field order.
  String encode() {
    final ordered = [...sessions]
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    final payload = <String, Object?>{
      'format': sleepHistoryFileFormat,
      'version': sleepHistoryFileVersion,
      'exportedAt': exportedAt.toUtc().toIso8601String(),
      'sessions': [for (final entry in ordered) _entryToJson(entry)],
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  static Map<String, Object?> _entryToJson(SleepHistoryEntry entry) {
    return <String, Object?>{
      'startedAtMillis': entry.startedAt.millisecondsSinceEpoch,
      'endedAtMillis': entry.endedAt.millisecondsSinceEpoch,
      'origin': entry.isDownloaded ? 'healthConnect' : 'local',
      if (entry.healthRecordId != null) 'healthRecordId': entry.healthRecordId,
      if (entry.healthClientRecordId != null)
        'healthClientRecordId': entry.healthClientRecordId,
      if (entry.sourceId != null) 'sourceId': entry.sourceId,
    };
  }

  static SleepHistoryEntry? _entryFrom(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;

    final startMillis = raw['startedAtMillis'];
    final endMillis = raw['endedAtMillis'];
    if (startMillis is! int || endMillis is! int) return null;
    if (endMillis <= startMillis) return null;

    final startedAt = DateTime.fromMillisecondsSinceEpoch(startMillis);
    final endedAt = DateTime.fromMillisecondsSinceEpoch(endMillis);
    final isDownloaded = raw['origin'] == 'healthConnect';
    // A downloaded copy can come from another app with a duration Sleepy3
    // would never record itself. Keep it so a backup restores every row; only
    // local entries must fit the range the app promotes to Health Connect.
    if (!isDownloaded) {
      final duration = endedAt.difference(startedAt);
      if (duration < minimumRecordableSleep ||
          duration >= maximumRecordableSleep) {
        return null;
      }
    }

    return SleepHistoryEntry(
      startedAt: startedAt,
      endedAt: endedAt,
      isDownloaded: isDownloaded,
      healthRecordId: _stringOrNull(raw['healthRecordId']),
      healthClientRecordId: _stringOrNull(raw['healthClientRecordId']),
      sourceId: _stringOrNull(raw['sourceId']),
    );
  }

  static DateTime _readExportedAt(Object? raw) {
    if (raw is String) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String? _stringOrNull(Object? raw) {
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
