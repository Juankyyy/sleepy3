// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sleepy3_database.dart';

// ignore_for_file: type=lint
class $SleepSessionsTable extends SleepSessions
    with TableInfo<$SleepSessionsTable, SleepSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SleepSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _startedAtMillisMeta = const VerificationMeta(
    'startedAtMillis',
  );
  @override
  late final GeneratedColumn<int> startedAtMillis = GeneratedColumn<int>(
    'started_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMillisMeta = const VerificationMeta(
    'endedAtMillis',
  );
  @override
  late final GeneratedColumn<int> endedAtMillis = GeneratedColumn<int>(
    'ended_at_millis',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _healthRecordIdMeta = const VerificationMeta(
    'healthRecordId',
  );
  @override
  late final GeneratedColumn<String> healthRecordId = GeneratedColumn<String>(
    'health_record_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _healthClientRecordIdMeta =
      const VerificationMeta('healthClientRecordId');
  @override
  late final GeneratedColumn<String> healthClientRecordId =
      GeneratedColumn<String>(
        'health_client_record_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _healthRecordVersionMeta =
      const VerificationMeta('healthRecordVersion');
  @override
  late final GeneratedColumn<int> healthRecordVersion = GeneratedColumn<int>(
    'health_record_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _healthSyncedAtMillisMeta =
      const VerificationMeta('healthSyncedAtMillis');
  @override
  late final GeneratedColumn<int> healthSyncedAtMillis = GeneratedColumn<int>(
    'health_synced_at_millis',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _healthSyncSkippedMeta = const VerificationMeta(
    'healthSyncSkipped',
  );
  @override
  late final GeneratedColumn<bool> healthSyncSkipped = GeneratedColumn<bool>(
    'health_sync_skipped',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("health_sync_skipped" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startedAtMillis,
    endedAtMillis,
    healthRecordId,
    healthClientRecordId,
    healthRecordVersion,
    healthSyncedAtMillis,
    healthSyncSkipped,
    origin,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sleep_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SleepSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('started_at_millis')) {
      context.handle(
        _startedAtMillisMeta,
        startedAtMillis.isAcceptableOrUnknown(
          data['started_at_millis']!,
          _startedAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startedAtMillisMeta);
    }
    if (data.containsKey('ended_at_millis')) {
      context.handle(
        _endedAtMillisMeta,
        endedAtMillis.isAcceptableOrUnknown(
          data['ended_at_millis']!,
          _endedAtMillisMeta,
        ),
      );
    }
    if (data.containsKey('health_record_id')) {
      context.handle(
        _healthRecordIdMeta,
        healthRecordId.isAcceptableOrUnknown(
          data['health_record_id']!,
          _healthRecordIdMeta,
        ),
      );
    }
    if (data.containsKey('health_client_record_id')) {
      context.handle(
        _healthClientRecordIdMeta,
        healthClientRecordId.isAcceptableOrUnknown(
          data['health_client_record_id']!,
          _healthClientRecordIdMeta,
        ),
      );
    }
    if (data.containsKey('health_record_version')) {
      context.handle(
        _healthRecordVersionMeta,
        healthRecordVersion.isAcceptableOrUnknown(
          data['health_record_version']!,
          _healthRecordVersionMeta,
        ),
      );
    }
    if (data.containsKey('health_synced_at_millis')) {
      context.handle(
        _healthSyncedAtMillisMeta,
        healthSyncedAtMillis.isAcceptableOrUnknown(
          data['health_synced_at_millis']!,
          _healthSyncedAtMillisMeta,
        ),
      );
    }
    if (data.containsKey('health_sync_skipped')) {
      context.handle(
        _healthSyncSkippedMeta,
        healthSyncSkipped.isAcceptableOrUnknown(
          data['health_sync_skipped']!,
          _healthSyncSkippedMeta,
        ),
      );
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SleepSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SleepSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startedAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at_millis'],
      )!,
      endedAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ended_at_millis'],
      ),
      healthRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}health_record_id'],
      ),
      healthClientRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}health_client_record_id'],
      ),
      healthRecordVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}health_record_version'],
      )!,
      healthSyncedAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}health_synced_at_millis'],
      ),
      healthSyncSkipped: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}health_sync_skipped'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
    );
  }

  @override
  $SleepSessionsTable createAlias(String alias) {
    return $SleepSessionsTable(attachedDatabase, alias);
  }
}

class SleepSessionRow extends DataClass implements Insertable<SleepSessionRow> {
  final int id;
  final int startedAtMillis;
  final int? endedAtMillis;

  /// Health Connect UUID once the record is uploaded or downloaded.
  final String? healthRecordId;

  /// Stable Health Connect id used to update the same record.
  ///
  /// Filled for every local row, even before it is uploaded, so an edit can
  /// address the record without creating a duplicate. Downloaded rows keep
  /// their own record id and leave this null.
  final String? healthClientRecordId;

  /// Health Connect record version, incremented on every upload attempt.
  ///
  /// Zero means the record was never written by Sleepy3. Downloaded rows start
  /// at zero and are not updated by the local editor.
  final int healthRecordVersion;

  /// When the record was last uploaded to or downloaded from Health Connect.
  final int? healthSyncedAtMillis;

  /// Set when the session is not eligible for upload, such as a zero duration.
  final bool healthSyncSkipped;

  /// `local` for sessions started in Sleepy3, `healthConnect` for downloads.
  final String origin;
  const SleepSessionRow({
    required this.id,
    required this.startedAtMillis,
    this.endedAtMillis,
    this.healthRecordId,
    this.healthClientRecordId,
    required this.healthRecordVersion,
    this.healthSyncedAtMillis,
    required this.healthSyncSkipped,
    required this.origin,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['started_at_millis'] = Variable<int>(startedAtMillis);
    if (!nullToAbsent || endedAtMillis != null) {
      map['ended_at_millis'] = Variable<int>(endedAtMillis);
    }
    if (!nullToAbsent || healthRecordId != null) {
      map['health_record_id'] = Variable<String>(healthRecordId);
    }
    if (!nullToAbsent || healthClientRecordId != null) {
      map['health_client_record_id'] = Variable<String>(healthClientRecordId);
    }
    map['health_record_version'] = Variable<int>(healthRecordVersion);
    if (!nullToAbsent || healthSyncedAtMillis != null) {
      map['health_synced_at_millis'] = Variable<int>(healthSyncedAtMillis);
    }
    map['health_sync_skipped'] = Variable<bool>(healthSyncSkipped);
    map['origin'] = Variable<String>(origin);
    return map;
  }

  SleepSessionsCompanion toCompanion(bool nullToAbsent) {
    return SleepSessionsCompanion(
      id: Value(id),
      startedAtMillis: Value(startedAtMillis),
      endedAtMillis: endedAtMillis == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAtMillis),
      healthRecordId: healthRecordId == null && nullToAbsent
          ? const Value.absent()
          : Value(healthRecordId),
      healthClientRecordId: healthClientRecordId == null && nullToAbsent
          ? const Value.absent()
          : Value(healthClientRecordId),
      healthRecordVersion: Value(healthRecordVersion),
      healthSyncedAtMillis: healthSyncedAtMillis == null && nullToAbsent
          ? const Value.absent()
          : Value(healthSyncedAtMillis),
      healthSyncSkipped: Value(healthSyncSkipped),
      origin: Value(origin),
    );
  }

  factory SleepSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SleepSessionRow(
      id: serializer.fromJson<int>(json['id']),
      startedAtMillis: serializer.fromJson<int>(json['startedAtMillis']),
      endedAtMillis: serializer.fromJson<int?>(json['endedAtMillis']),
      healthRecordId: serializer.fromJson<String?>(json['healthRecordId']),
      healthClientRecordId: serializer.fromJson<String?>(
        json['healthClientRecordId'],
      ),
      healthRecordVersion: serializer.fromJson<int>(
        json['healthRecordVersion'],
      ),
      healthSyncedAtMillis: serializer.fromJson<int?>(
        json['healthSyncedAtMillis'],
      ),
      healthSyncSkipped: serializer.fromJson<bool>(json['healthSyncSkipped']),
      origin: serializer.fromJson<String>(json['origin']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startedAtMillis': serializer.toJson<int>(startedAtMillis),
      'endedAtMillis': serializer.toJson<int?>(endedAtMillis),
      'healthRecordId': serializer.toJson<String?>(healthRecordId),
      'healthClientRecordId': serializer.toJson<String?>(healthClientRecordId),
      'healthRecordVersion': serializer.toJson<int>(healthRecordVersion),
      'healthSyncedAtMillis': serializer.toJson<int?>(healthSyncedAtMillis),
      'healthSyncSkipped': serializer.toJson<bool>(healthSyncSkipped),
      'origin': serializer.toJson<String>(origin),
    };
  }

  SleepSessionRow copyWith({
    int? id,
    int? startedAtMillis,
    Value<int?> endedAtMillis = const Value.absent(),
    Value<String?> healthRecordId = const Value.absent(),
    Value<String?> healthClientRecordId = const Value.absent(),
    int? healthRecordVersion,
    Value<int?> healthSyncedAtMillis = const Value.absent(),
    bool? healthSyncSkipped,
    String? origin,
  }) => SleepSessionRow(
    id: id ?? this.id,
    startedAtMillis: startedAtMillis ?? this.startedAtMillis,
    endedAtMillis: endedAtMillis.present
        ? endedAtMillis.value
        : this.endedAtMillis,
    healthRecordId: healthRecordId.present
        ? healthRecordId.value
        : this.healthRecordId,
    healthClientRecordId: healthClientRecordId.present
        ? healthClientRecordId.value
        : this.healthClientRecordId,
    healthRecordVersion: healthRecordVersion ?? this.healthRecordVersion,
    healthSyncedAtMillis: healthSyncedAtMillis.present
        ? healthSyncedAtMillis.value
        : this.healthSyncedAtMillis,
    healthSyncSkipped: healthSyncSkipped ?? this.healthSyncSkipped,
    origin: origin ?? this.origin,
  );
  SleepSessionRow copyWithCompanion(SleepSessionsCompanion data) {
    return SleepSessionRow(
      id: data.id.present ? data.id.value : this.id,
      startedAtMillis: data.startedAtMillis.present
          ? data.startedAtMillis.value
          : this.startedAtMillis,
      endedAtMillis: data.endedAtMillis.present
          ? data.endedAtMillis.value
          : this.endedAtMillis,
      healthRecordId: data.healthRecordId.present
          ? data.healthRecordId.value
          : this.healthRecordId,
      healthClientRecordId: data.healthClientRecordId.present
          ? data.healthClientRecordId.value
          : this.healthClientRecordId,
      healthRecordVersion: data.healthRecordVersion.present
          ? data.healthRecordVersion.value
          : this.healthRecordVersion,
      healthSyncedAtMillis: data.healthSyncedAtMillis.present
          ? data.healthSyncedAtMillis.value
          : this.healthSyncedAtMillis,
      healthSyncSkipped: data.healthSyncSkipped.present
          ? data.healthSyncSkipped.value
          : this.healthSyncSkipped,
      origin: data.origin.present ? data.origin.value : this.origin,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SleepSessionRow(')
          ..write('id: $id, ')
          ..write('startedAtMillis: $startedAtMillis, ')
          ..write('endedAtMillis: $endedAtMillis, ')
          ..write('healthRecordId: $healthRecordId, ')
          ..write('healthClientRecordId: $healthClientRecordId, ')
          ..write('healthRecordVersion: $healthRecordVersion, ')
          ..write('healthSyncedAtMillis: $healthSyncedAtMillis, ')
          ..write('healthSyncSkipped: $healthSyncSkipped, ')
          ..write('origin: $origin')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startedAtMillis,
    endedAtMillis,
    healthRecordId,
    healthClientRecordId,
    healthRecordVersion,
    healthSyncedAtMillis,
    healthSyncSkipped,
    origin,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SleepSessionRow &&
          other.id == this.id &&
          other.startedAtMillis == this.startedAtMillis &&
          other.endedAtMillis == this.endedAtMillis &&
          other.healthRecordId == this.healthRecordId &&
          other.healthClientRecordId == this.healthClientRecordId &&
          other.healthRecordVersion == this.healthRecordVersion &&
          other.healthSyncedAtMillis == this.healthSyncedAtMillis &&
          other.healthSyncSkipped == this.healthSyncSkipped &&
          other.origin == this.origin);
}

class SleepSessionsCompanion extends UpdateCompanion<SleepSessionRow> {
  final Value<int> id;
  final Value<int> startedAtMillis;
  final Value<int?> endedAtMillis;
  final Value<String?> healthRecordId;
  final Value<String?> healthClientRecordId;
  final Value<int> healthRecordVersion;
  final Value<int?> healthSyncedAtMillis;
  final Value<bool> healthSyncSkipped;
  final Value<String> origin;
  const SleepSessionsCompanion({
    this.id = const Value.absent(),
    this.startedAtMillis = const Value.absent(),
    this.endedAtMillis = const Value.absent(),
    this.healthRecordId = const Value.absent(),
    this.healthClientRecordId = const Value.absent(),
    this.healthRecordVersion = const Value.absent(),
    this.healthSyncedAtMillis = const Value.absent(),
    this.healthSyncSkipped = const Value.absent(),
    this.origin = const Value.absent(),
  });
  SleepSessionsCompanion.insert({
    this.id = const Value.absent(),
    required int startedAtMillis,
    this.endedAtMillis = const Value.absent(),
    this.healthRecordId = const Value.absent(),
    this.healthClientRecordId = const Value.absent(),
    this.healthRecordVersion = const Value.absent(),
    this.healthSyncedAtMillis = const Value.absent(),
    this.healthSyncSkipped = const Value.absent(),
    this.origin = const Value.absent(),
  }) : startedAtMillis = Value(startedAtMillis);
  static Insertable<SleepSessionRow> custom({
    Expression<int>? id,
    Expression<int>? startedAtMillis,
    Expression<int>? endedAtMillis,
    Expression<String>? healthRecordId,
    Expression<String>? healthClientRecordId,
    Expression<int>? healthRecordVersion,
    Expression<int>? healthSyncedAtMillis,
    Expression<bool>? healthSyncSkipped,
    Expression<String>? origin,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAtMillis != null) 'started_at_millis': startedAtMillis,
      if (endedAtMillis != null) 'ended_at_millis': endedAtMillis,
      if (healthRecordId != null) 'health_record_id': healthRecordId,
      if (healthClientRecordId != null)
        'health_client_record_id': healthClientRecordId,
      if (healthRecordVersion != null)
        'health_record_version': healthRecordVersion,
      if (healthSyncedAtMillis != null)
        'health_synced_at_millis': healthSyncedAtMillis,
      if (healthSyncSkipped != null) 'health_sync_skipped': healthSyncSkipped,
      if (origin != null) 'origin': origin,
    });
  }

  SleepSessionsCompanion copyWith({
    Value<int>? id,
    Value<int>? startedAtMillis,
    Value<int?>? endedAtMillis,
    Value<String?>? healthRecordId,
    Value<String?>? healthClientRecordId,
    Value<int>? healthRecordVersion,
    Value<int?>? healthSyncedAtMillis,
    Value<bool>? healthSyncSkipped,
    Value<String>? origin,
  }) {
    return SleepSessionsCompanion(
      id: id ?? this.id,
      startedAtMillis: startedAtMillis ?? this.startedAtMillis,
      endedAtMillis: endedAtMillis ?? this.endedAtMillis,
      healthRecordId: healthRecordId ?? this.healthRecordId,
      healthClientRecordId: healthClientRecordId ?? this.healthClientRecordId,
      healthRecordVersion: healthRecordVersion ?? this.healthRecordVersion,
      healthSyncedAtMillis: healthSyncedAtMillis ?? this.healthSyncedAtMillis,
      healthSyncSkipped: healthSyncSkipped ?? this.healthSyncSkipped,
      origin: origin ?? this.origin,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startedAtMillis.present) {
      map['started_at_millis'] = Variable<int>(startedAtMillis.value);
    }
    if (endedAtMillis.present) {
      map['ended_at_millis'] = Variable<int>(endedAtMillis.value);
    }
    if (healthRecordId.present) {
      map['health_record_id'] = Variable<String>(healthRecordId.value);
    }
    if (healthClientRecordId.present) {
      map['health_client_record_id'] = Variable<String>(
        healthClientRecordId.value,
      );
    }
    if (healthRecordVersion.present) {
      map['health_record_version'] = Variable<int>(healthRecordVersion.value);
    }
    if (healthSyncedAtMillis.present) {
      map['health_synced_at_millis'] = Variable<int>(
        healthSyncedAtMillis.value,
      );
    }
    if (healthSyncSkipped.present) {
      map['health_sync_skipped'] = Variable<bool>(healthSyncSkipped.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SleepSessionsCompanion(')
          ..write('id: $id, ')
          ..write('startedAtMillis: $startedAtMillis, ')
          ..write('endedAtMillis: $endedAtMillis, ')
          ..write('healthRecordId: $healthRecordId, ')
          ..write('healthClientRecordId: $healthClientRecordId, ')
          ..write('healthRecordVersion: $healthRecordVersion, ')
          ..write('healthSyncedAtMillis: $healthSyncedAtMillis, ')
          ..write('healthSyncSkipped: $healthSyncSkipped, ')
          ..write('origin: $origin')
          ..write(')'))
        .toString();
  }
}

class $PreferencesTable extends Preferences
    with TableInfo<$PreferencesTable, PreferenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _settingKeyMeta = const VerificationMeta(
    'settingKey',
  );
  @override
  late final GeneratedColumn<String> settingKey = GeneratedColumn<String>(
    'setting_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _settingValueMeta = const VerificationMeta(
    'settingValue',
  );
  @override
  late final GeneratedColumn<String> settingValue = GeneratedColumn<String>(
    'setting_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [settingKey, settingValue];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<PreferenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('setting_key')) {
      context.handle(
        _settingKeyMeta,
        settingKey.isAcceptableOrUnknown(data['setting_key']!, _settingKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_settingKeyMeta);
    }
    if (data.containsKey('setting_value')) {
      context.handle(
        _settingValueMeta,
        settingValue.isAcceptableOrUnknown(
          data['setting_value']!,
          _settingValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_settingValueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {settingKey};
  @override
  PreferenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PreferenceRow(
      settingKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}setting_key'],
      )!,
      settingValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}setting_value'],
      )!,
    );
  }

  @override
  $PreferencesTable createAlias(String alias) {
    return $PreferencesTable(attachedDatabase, alias);
  }
}

class PreferenceRow extends DataClass implements Insertable<PreferenceRow> {
  final String settingKey;
  final String settingValue;
  const PreferenceRow({required this.settingKey, required this.settingValue});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['setting_key'] = Variable<String>(settingKey);
    map['setting_value'] = Variable<String>(settingValue);
    return map;
  }

  PreferencesCompanion toCompanion(bool nullToAbsent) {
    return PreferencesCompanion(
      settingKey: Value(settingKey),
      settingValue: Value(settingValue),
    );
  }

  factory PreferenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PreferenceRow(
      settingKey: serializer.fromJson<String>(json['settingKey']),
      settingValue: serializer.fromJson<String>(json['settingValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'settingKey': serializer.toJson<String>(settingKey),
      'settingValue': serializer.toJson<String>(settingValue),
    };
  }

  PreferenceRow copyWith({String? settingKey, String? settingValue}) =>
      PreferenceRow(
        settingKey: settingKey ?? this.settingKey,
        settingValue: settingValue ?? this.settingValue,
      );
  PreferenceRow copyWithCompanion(PreferencesCompanion data) {
    return PreferenceRow(
      settingKey: data.settingKey.present
          ? data.settingKey.value
          : this.settingKey,
      settingValue: data.settingValue.present
          ? data.settingValue.value
          : this.settingValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PreferenceRow(')
          ..write('settingKey: $settingKey, ')
          ..write('settingValue: $settingValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(settingKey, settingValue);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PreferenceRow &&
          other.settingKey == this.settingKey &&
          other.settingValue == this.settingValue);
}

class PreferencesCompanion extends UpdateCompanion<PreferenceRow> {
  final Value<String> settingKey;
  final Value<String> settingValue;
  final Value<int> rowid;
  const PreferencesCompanion({
    this.settingKey = const Value.absent(),
    this.settingValue = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PreferencesCompanion.insert({
    required String settingKey,
    required String settingValue,
    this.rowid = const Value.absent(),
  }) : settingKey = Value(settingKey),
       settingValue = Value(settingValue);
  static Insertable<PreferenceRow> custom({
    Expression<String>? settingKey,
    Expression<String>? settingValue,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (settingKey != null) 'setting_key': settingKey,
      if (settingValue != null) 'setting_value': settingValue,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PreferencesCompanion copyWith({
    Value<String>? settingKey,
    Value<String>? settingValue,
    Value<int>? rowid,
  }) {
    return PreferencesCompanion(
      settingKey: settingKey ?? this.settingKey,
      settingValue: settingValue ?? this.settingValue,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (settingKey.present) {
      map['setting_key'] = Variable<String>(settingKey.value);
    }
    if (settingValue.present) {
      map['setting_value'] = Variable<String>(settingValue.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreferencesCompanion(')
          ..write('settingKey: $settingKey, ')
          ..write('settingValue: $settingValue, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$Sleepy3Database extends GeneratedDatabase {
  _$Sleepy3Database(QueryExecutor e) : super(e);
  $Sleepy3DatabaseManager get managers => $Sleepy3DatabaseManager(this);
  late final $SleepSessionsTable sleepSessions = $SleepSessionsTable(this);
  late final $PreferencesTable preferences = $PreferencesTable(this);
  late final Index sleepSessionsHealthRecordId = Index(
    'sleep_sessions_health_record_id',
    'CREATE UNIQUE INDEX sleep_sessions_health_record_id ON sleep_sessions (health_record_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sleepSessions,
    preferences,
    sleepSessionsHealthRecordId,
  ];
}

typedef $$SleepSessionsTableCreateCompanionBuilder =
    SleepSessionsCompanion Function({
      Value<int> id,
      required int startedAtMillis,
      Value<int?> endedAtMillis,
      Value<String?> healthRecordId,
      Value<String?> healthClientRecordId,
      Value<int> healthRecordVersion,
      Value<int?> healthSyncedAtMillis,
      Value<bool> healthSyncSkipped,
      Value<String> origin,
    });
typedef $$SleepSessionsTableUpdateCompanionBuilder =
    SleepSessionsCompanion Function({
      Value<int> id,
      Value<int> startedAtMillis,
      Value<int?> endedAtMillis,
      Value<String?> healthRecordId,
      Value<String?> healthClientRecordId,
      Value<int> healthRecordVersion,
      Value<int?> healthSyncedAtMillis,
      Value<bool> healthSyncSkipped,
      Value<String> origin,
    });

class $$SleepSessionsTableFilterComposer
    extends Composer<_$Sleepy3Database, $SleepSessionsTable> {
  $$SleepSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAtMillis => $composableBuilder(
    column: $table.startedAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endedAtMillis => $composableBuilder(
    column: $table.endedAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get healthRecordId => $composableBuilder(
    column: $table.healthRecordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get healthClientRecordId => $composableBuilder(
    column: $table.healthClientRecordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get healthRecordVersion => $composableBuilder(
    column: $table.healthRecordVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get healthSyncedAtMillis => $composableBuilder(
    column: $table.healthSyncedAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get healthSyncSkipped => $composableBuilder(
    column: $table.healthSyncSkipped,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SleepSessionsTableOrderingComposer
    extends Composer<_$Sleepy3Database, $SleepSessionsTable> {
  $$SleepSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAtMillis => $composableBuilder(
    column: $table.startedAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endedAtMillis => $composableBuilder(
    column: $table.endedAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get healthRecordId => $composableBuilder(
    column: $table.healthRecordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get healthClientRecordId => $composableBuilder(
    column: $table.healthClientRecordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get healthRecordVersion => $composableBuilder(
    column: $table.healthRecordVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get healthSyncedAtMillis => $composableBuilder(
    column: $table.healthSyncedAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get healthSyncSkipped => $composableBuilder(
    column: $table.healthSyncSkipped,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SleepSessionsTableAnnotationComposer
    extends Composer<_$Sleepy3Database, $SleepSessionsTable> {
  $$SleepSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get startedAtMillis => $composableBuilder(
    column: $table.startedAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endedAtMillis => $composableBuilder(
    column: $table.endedAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<String> get healthRecordId => $composableBuilder(
    column: $table.healthRecordId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get healthClientRecordId => $composableBuilder(
    column: $table.healthClientRecordId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get healthRecordVersion => $composableBuilder(
    column: $table.healthRecordVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get healthSyncedAtMillis => $composableBuilder(
    column: $table.healthSyncedAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get healthSyncSkipped => $composableBuilder(
    column: $table.healthSyncSkipped,
    builder: (column) => column,
  );

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);
}

class $$SleepSessionsTableTableManager
    extends
        RootTableManager<
          _$Sleepy3Database,
          $SleepSessionsTable,
          SleepSessionRow,
          $$SleepSessionsTableFilterComposer,
          $$SleepSessionsTableOrderingComposer,
          $$SleepSessionsTableAnnotationComposer,
          $$SleepSessionsTableCreateCompanionBuilder,
          $$SleepSessionsTableUpdateCompanionBuilder,
          (
            SleepSessionRow,
            BaseReferences<
              _$Sleepy3Database,
              $SleepSessionsTable,
              SleepSessionRow
            >,
          ),
          SleepSessionRow,
          PrefetchHooks Function()
        > {
  $$SleepSessionsTableTableManager(
    _$Sleepy3Database db,
    $SleepSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SleepSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SleepSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SleepSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> startedAtMillis = const Value.absent(),
                Value<int?> endedAtMillis = const Value.absent(),
                Value<String?> healthRecordId = const Value.absent(),
                Value<String?> healthClientRecordId = const Value.absent(),
                Value<int> healthRecordVersion = const Value.absent(),
                Value<int?> healthSyncedAtMillis = const Value.absent(),
                Value<bool> healthSyncSkipped = const Value.absent(),
                Value<String> origin = const Value.absent(),
              }) => SleepSessionsCompanion(
                id: id,
                startedAtMillis: startedAtMillis,
                endedAtMillis: endedAtMillis,
                healthRecordId: healthRecordId,
                healthClientRecordId: healthClientRecordId,
                healthRecordVersion: healthRecordVersion,
                healthSyncedAtMillis: healthSyncedAtMillis,
                healthSyncSkipped: healthSyncSkipped,
                origin: origin,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int startedAtMillis,
                Value<int?> endedAtMillis = const Value.absent(),
                Value<String?> healthRecordId = const Value.absent(),
                Value<String?> healthClientRecordId = const Value.absent(),
                Value<int> healthRecordVersion = const Value.absent(),
                Value<int?> healthSyncedAtMillis = const Value.absent(),
                Value<bool> healthSyncSkipped = const Value.absent(),
                Value<String> origin = const Value.absent(),
              }) => SleepSessionsCompanion.insert(
                id: id,
                startedAtMillis: startedAtMillis,
                endedAtMillis: endedAtMillis,
                healthRecordId: healthRecordId,
                healthClientRecordId: healthClientRecordId,
                healthRecordVersion: healthRecordVersion,
                healthSyncedAtMillis: healthSyncedAtMillis,
                healthSyncSkipped: healthSyncSkipped,
                origin: origin,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SleepSessionsTable, SleepSessionRow>(table),
                  BaseReferences<
                    _$Sleepy3Database,
                    $SleepSessionsTable,
                    SleepSessionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SleepSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$Sleepy3Database,
      $SleepSessionsTable,
      SleepSessionRow,
      $$SleepSessionsTableFilterComposer,
      $$SleepSessionsTableOrderingComposer,
      $$SleepSessionsTableAnnotationComposer,
      $$SleepSessionsTableCreateCompanionBuilder,
      $$SleepSessionsTableUpdateCompanionBuilder,
      (
        SleepSessionRow,
        BaseReferences<_$Sleepy3Database, $SleepSessionsTable, SleepSessionRow>,
      ),
      SleepSessionRow,
      PrefetchHooks Function()
    >;
typedef $$PreferencesTableCreateCompanionBuilder =
    PreferencesCompanion Function({
      required String settingKey,
      required String settingValue,
      Value<int> rowid,
    });
typedef $$PreferencesTableUpdateCompanionBuilder =
    PreferencesCompanion Function({
      Value<String> settingKey,
      Value<String> settingValue,
      Value<int> rowid,
    });

class $$PreferencesTableFilterComposer
    extends Composer<_$Sleepy3Database, $PreferencesTable> {
  $$PreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get settingKey => $composableBuilder(
    column: $table.settingKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settingValue => $composableBuilder(
    column: $table.settingValue,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PreferencesTableOrderingComposer
    extends Composer<_$Sleepy3Database, $PreferencesTable> {
  $$PreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get settingKey => $composableBuilder(
    column: $table.settingKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settingValue => $composableBuilder(
    column: $table.settingValue,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PreferencesTableAnnotationComposer
    extends Composer<_$Sleepy3Database, $PreferencesTable> {
  $$PreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get settingKey => $composableBuilder(
    column: $table.settingKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get settingValue => $composableBuilder(
    column: $table.settingValue,
    builder: (column) => column,
  );
}

class $$PreferencesTableTableManager
    extends
        RootTableManager<
          _$Sleepy3Database,
          $PreferencesTable,
          PreferenceRow,
          $$PreferencesTableFilterComposer,
          $$PreferencesTableOrderingComposer,
          $$PreferencesTableAnnotationComposer,
          $$PreferencesTableCreateCompanionBuilder,
          $$PreferencesTableUpdateCompanionBuilder,
          (
            PreferenceRow,
            BaseReferences<_$Sleepy3Database, $PreferencesTable, PreferenceRow>,
          ),
          PreferenceRow,
          PrefetchHooks Function()
        > {
  $$PreferencesTableTableManager(_$Sleepy3Database db, $PreferencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> settingKey = const Value.absent(),
                Value<String> settingValue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PreferencesCompanion(
                settingKey: settingKey,
                settingValue: settingValue,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String settingKey,
                required String settingValue,
                Value<int> rowid = const Value.absent(),
              }) => PreferencesCompanion.insert(
                settingKey: settingKey,
                settingValue: settingValue,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PreferencesTable, PreferenceRow>(table),
                  BaseReferences<
                    _$Sleepy3Database,
                    $PreferencesTable,
                    PreferenceRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$Sleepy3Database,
      $PreferencesTable,
      PreferenceRow,
      $$PreferencesTableFilterComposer,
      $$PreferencesTableOrderingComposer,
      $$PreferencesTableAnnotationComposer,
      $$PreferencesTableCreateCompanionBuilder,
      $$PreferencesTableUpdateCompanionBuilder,
      (
        PreferenceRow,
        BaseReferences<_$Sleepy3Database, $PreferencesTable, PreferenceRow>,
      ),
      PreferenceRow,
      PrefetchHooks Function()
    >;

class $Sleepy3DatabaseManager {
  final _$Sleepy3Database _db;
  $Sleepy3DatabaseManager(this._db);
  $$SleepSessionsTableTableManager get sleepSessions =>
      $$SleepSessionsTableTableManager(_db, _db.sleepSessions);
  $$PreferencesTableTableManager get preferences =>
      $$PreferencesTableTableManager(_db, _db.preferences);
}
