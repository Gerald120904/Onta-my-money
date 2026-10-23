import 'package:drift/drift.dart';

class LocalUsers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  TextColumn get token => text().nullable()();
  RealColumn get openingBalance => real().withDefault(const Constant(0.0))();
  BoolColumn get isCurrent => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
  IntColumn get lastServerCursor => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get type => text()(); // 'income' or 'expense'
  TextColumn get category => text()();
  RealColumn get amount => real()();
  TextColumn get description => text()();
  DateTimeColumn get date => dateTime()();
  BoolColumn get recognized => boolean().withDefault(const Constant(true))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))(); // 'synced', 'pending', 'conflict', 'error'
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalCommitments extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  RealColumn get amount => real()();
  DateTimeColumn get dueDate => dateTime()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalGoals extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  RealColumn get targetAmount => real()();
  RealColumn get savedAmount => real()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalDecisions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get action => text()();
  TextColumn get note => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalReviews extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get start => dateTime()();
  DateTimeColumn get end => dateTime()();
  TextColumn get periodTitle => text()();
  TextColumn get periodSubtitle => text()();
  TextColumn get transactionIdsJson => text()();
  TextColumn get decision => text()();
  TextColumn get decisionDetailsJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalPendingOperations extends Table {
  TextColumn get operationId => text()();
  TextColumn get userId => text()();
  TextColumn get deviceId => text().nullable()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get action => text()(); // 'create', 'update', 'delete'
  TextColumn get payloadJson => text()();
  IntColumn get baseVersion => integer().withDefault(const Constant(1))();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // 'pending', 'syncing', 'synced', 'conflict', 'failed'
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {operationId};
}

class LocalConflicts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  IntColumn get baseVersion => integer()();
  IntColumn get serverVersion => integer()();
  TextColumn get clientPayloadJson => text()();
  TextColumn get serverPayloadJson => text()();
  TextColumn get status => text().withDefault(const Constant('unresolved'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get resolvedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalChangeHistory extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get action => text()();
  TextColumn get previousValuesJson => text().nullable()();
  TextColumn get newValuesJson => text()();
  TextColumn get deviceId => text().nullable()();
  DateTimeColumn get localTimestamp => dateTime()();
  DateTimeColumn get serverTimestamp => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('local'))();

  @override
  Set<Column> get primaryKey => {id};
}
