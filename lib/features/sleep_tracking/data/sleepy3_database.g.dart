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
  @override
  List<GeneratedColumn> get $columns => [id, startedAtMillis, endedAtMillis];
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
  const SleepSessionRow({
    required this.id,
    required this.startedAtMillis,
    this.endedAtMillis,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['started_at_millis'] = Variable<int>(startedAtMillis);
    if (!nullToAbsent || endedAtMillis != null) {
      map['ended_at_millis'] = Variable<int>(endedAtMillis);
    }
    return map;
  }

  SleepSessionsCompanion toCompanion(bool nullToAbsent) {
    return SleepSessionsCompanion(
      id: Value(id),
      startedAtMillis: Value(startedAtMillis),
      endedAtMillis: endedAtMillis == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAtMillis),
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
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startedAtMillis': serializer.toJson<int>(startedAtMillis),
      'endedAtMillis': serializer.toJson<int?>(endedAtMillis),
    };
  }

  SleepSessionRow copyWith({
    int? id,
    int? startedAtMillis,
    Value<int?> endedAtMillis = const Value.absent(),
  }) => SleepSessionRow(
    id: id ?? this.id,
    startedAtMillis: startedAtMillis ?? this.startedAtMillis,
    endedAtMillis: endedAtMillis.present
        ? endedAtMillis.value
        : this.endedAtMillis,
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
    );
  }

  @override
  String toString() {
    return (StringBuffer('SleepSessionRow(')
          ..write('id: $id, ')
          ..write('startedAtMillis: $startedAtMillis, ')
          ..write('endedAtMillis: $endedAtMillis')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, startedAtMillis, endedAtMillis);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SleepSessionRow &&
          other.id == this.id &&
          other.startedAtMillis == this.startedAtMillis &&
          other.endedAtMillis == this.endedAtMillis);
}

class SleepSessionsCompanion extends UpdateCompanion<SleepSessionRow> {
  final Value<int> id;
  final Value<int> startedAtMillis;
  final Value<int?> endedAtMillis;
  const SleepSessionsCompanion({
    this.id = const Value.absent(),
    this.startedAtMillis = const Value.absent(),
    this.endedAtMillis = const Value.absent(),
  });
  SleepSessionsCompanion.insert({
    this.id = const Value.absent(),
    required int startedAtMillis,
    this.endedAtMillis = const Value.absent(),
  }) : startedAtMillis = Value(startedAtMillis);
  static Insertable<SleepSessionRow> custom({
    Expression<int>? id,
    Expression<int>? startedAtMillis,
    Expression<int>? endedAtMillis,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAtMillis != null) 'started_at_millis': startedAtMillis,
      if (endedAtMillis != null) 'ended_at_millis': endedAtMillis,
    });
  }

  SleepSessionsCompanion copyWith({
    Value<int>? id,
    Value<int>? startedAtMillis,
    Value<int?>? endedAtMillis,
  }) {
    return SleepSessionsCompanion(
      id: id ?? this.id,
      startedAtMillis: startedAtMillis ?? this.startedAtMillis,
      endedAtMillis: endedAtMillis ?? this.endedAtMillis,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SleepSessionsCompanion(')
          ..write('id: $id, ')
          ..write('startedAtMillis: $startedAtMillis, ')
          ..write('endedAtMillis: $endedAtMillis')
          ..write(')'))
        .toString();
  }
}

abstract class _$Sleepy3Database extends GeneratedDatabase {
  _$Sleepy3Database(QueryExecutor e) : super(e);
  $Sleepy3DatabaseManager get managers => $Sleepy3DatabaseManager(this);
  late final $SleepSessionsTable sleepSessions = $SleepSessionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [sleepSessions];
}

typedef $$SleepSessionsTableCreateCompanionBuilder =
    SleepSessionsCompanion Function({
      Value<int> id,
      required int startedAtMillis,
      Value<int?> endedAtMillis,
    });
typedef $$SleepSessionsTableUpdateCompanionBuilder =
    SleepSessionsCompanion Function({
      Value<int> id,
      Value<int> startedAtMillis,
      Value<int?> endedAtMillis,
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
              }) => SleepSessionsCompanion(
                id: id,
                startedAtMillis: startedAtMillis,
                endedAtMillis: endedAtMillis,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int startedAtMillis,
                Value<int?> endedAtMillis = const Value.absent(),
              }) => SleepSessionsCompanion.insert(
                id: id,
                startedAtMillis: startedAtMillis,
                endedAtMillis: endedAtMillis,
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

class $Sleepy3DatabaseManager {
  final _$Sleepy3Database _db;
  $Sleepy3DatabaseManager(this._db);
  $$SleepSessionsTableTableManager get sleepSessions =>
      $$SleepSessionsTableTableManager(_db, _db.sleepSessions);
}
