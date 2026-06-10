// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WaterEntriesTable extends WaterEntries
    with TableInfo<$WaterEntriesTable, WaterEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WaterEntriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _amountMlMeta = const VerificationMeta(
    'amountMl',
  );
  @override
  late final GeneratedColumn<int> amountMl = GeneratedColumn<int>(
    'amount_ml',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _loggedAtMeta = const VerificationMeta(
    'loggedAt',
  );
  @override
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
    'logged_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateKeyMeta = const VerificationMeta(
    'dateKey',
  );
  @override
  late final GeneratedColumn<String> dateKey = GeneratedColumn<String>(
    'date_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, amountMl, loggedAt, dateKey];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'water_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<WaterEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('amount_ml')) {
      context.handle(
        _amountMlMeta,
        amountMl.isAcceptableOrUnknown(data['amount_ml']!, _amountMlMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMlMeta);
    }
    if (data.containsKey('logged_at')) {
      context.handle(
        _loggedAtMeta,
        loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_loggedAtMeta);
    }
    if (data.containsKey('date_key')) {
      context.handle(
        _dateKeyMeta,
        dateKey.isAcceptableOrUnknown(data['date_key']!, _dateKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dateKeyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WaterEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WaterEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      amountMl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_ml'],
      )!,
      loggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}logged_at'],
      )!,
      dateKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_key'],
      )!,
    );
  }

  @override
  $WaterEntriesTable createAlias(String alias) {
    return $WaterEntriesTable(attachedDatabase, alias);
  }
}

class WaterEntry extends DataClass implements Insertable<WaterEntry> {
  final int id;
  final int amountMl;
  final DateTime loggedAt;
  final String dateKey;
  const WaterEntry({
    required this.id,
    required this.amountMl,
    required this.loggedAt,
    required this.dateKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['amount_ml'] = Variable<int>(amountMl);
    map['logged_at'] = Variable<DateTime>(loggedAt);
    map['date_key'] = Variable<String>(dateKey);
    return map;
  }

  WaterEntriesCompanion toCompanion(bool nullToAbsent) {
    return WaterEntriesCompanion(
      id: Value(id),
      amountMl: Value(amountMl),
      loggedAt: Value(loggedAt),
      dateKey: Value(dateKey),
    );
  }

  factory WaterEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WaterEntry(
      id: serializer.fromJson<int>(json['id']),
      amountMl: serializer.fromJson<int>(json['amountMl']),
      loggedAt: serializer.fromJson<DateTime>(json['loggedAt']),
      dateKey: serializer.fromJson<String>(json['dateKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'amountMl': serializer.toJson<int>(amountMl),
      'loggedAt': serializer.toJson<DateTime>(loggedAt),
      'dateKey': serializer.toJson<String>(dateKey),
    };
  }

  WaterEntry copyWith({
    int? id,
    int? amountMl,
    DateTime? loggedAt,
    String? dateKey,
  }) => WaterEntry(
    id: id ?? this.id,
    amountMl: amountMl ?? this.amountMl,
    loggedAt: loggedAt ?? this.loggedAt,
    dateKey: dateKey ?? this.dateKey,
  );
  WaterEntry copyWithCompanion(WaterEntriesCompanion data) {
    return WaterEntry(
      id: data.id.present ? data.id.value : this.id,
      amountMl: data.amountMl.present ? data.amountMl.value : this.amountMl,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
      dateKey: data.dateKey.present ? data.dateKey.value : this.dateKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WaterEntry(')
          ..write('id: $id, ')
          ..write('amountMl: $amountMl, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('dateKey: $dateKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, amountMl, loggedAt, dateKey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WaterEntry &&
          other.id == this.id &&
          other.amountMl == this.amountMl &&
          other.loggedAt == this.loggedAt &&
          other.dateKey == this.dateKey);
}

class WaterEntriesCompanion extends UpdateCompanion<WaterEntry> {
  final Value<int> id;
  final Value<int> amountMl;
  final Value<DateTime> loggedAt;
  final Value<String> dateKey;
  const WaterEntriesCompanion({
    this.id = const Value.absent(),
    this.amountMl = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.dateKey = const Value.absent(),
  });
  WaterEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int amountMl,
    required DateTime loggedAt,
    required String dateKey,
  }) : amountMl = Value(amountMl),
       loggedAt = Value(loggedAt),
       dateKey = Value(dateKey);
  static Insertable<WaterEntry> custom({
    Expression<int>? id,
    Expression<int>? amountMl,
    Expression<DateTime>? loggedAt,
    Expression<String>? dateKey,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amountMl != null) 'amount_ml': amountMl,
      if (loggedAt != null) 'logged_at': loggedAt,
      if (dateKey != null) 'date_key': dateKey,
    });
  }

  WaterEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? amountMl,
    Value<DateTime>? loggedAt,
    Value<String>? dateKey,
  }) {
    return WaterEntriesCompanion(
      id: id ?? this.id,
      amountMl: amountMl ?? this.amountMl,
      loggedAt: loggedAt ?? this.loggedAt,
      dateKey: dateKey ?? this.dateKey,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (amountMl.present) {
      map['amount_ml'] = Variable<int>(amountMl.value);
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    if (dateKey.present) {
      map['date_key'] = Variable<String>(dateKey.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WaterEntriesCompanion(')
          ..write('id: $id, ')
          ..write('amountMl: $amountMl, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('dateKey: $dateKey')
          ..write(')'))
        .toString();
  }
}

class $UserSettingsTable extends UserSettings
    with TableInfo<$UserSettingsTable, UserSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserSettingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dailyTargetMlMeta = const VerificationMeta(
    'dailyTargetMl',
  );
  @override
  late final GeneratedColumn<int> dailyTargetMl = GeneratedColumn<int>(
    'daily_target_ml',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2000),
  );
  static const VerificationMeta _notificationIntervalMinutesMeta =
      const VerificationMeta('notificationIntervalMinutes');
  @override
  late final GeneratedColumn<int> notificationIntervalMinutes =
      GeneratedColumn<int>(
        'notification_interval_minutes',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(60),
      );
  static const VerificationMeta _dndStartHourMeta = const VerificationMeta(
    'dndStartHour',
  );
  @override
  late final GeneratedColumn<int> dndStartHour = GeneratedColumn<int>(
    'dnd_start_hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(23),
  );
  static const VerificationMeta _dndStartMinuteMeta = const VerificationMeta(
    'dndStartMinute',
  );
  @override
  late final GeneratedColumn<int> dndStartMinute = GeneratedColumn<int>(
    'dnd_start_minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dndEndHourMeta = const VerificationMeta(
    'dndEndHour',
  );
  @override
  late final GeneratedColumn<int> dndEndHour = GeneratedColumn<int>(
    'dnd_end_hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(7),
  );
  static const VerificationMeta _dndEndMinuteMeta = const VerificationMeta(
    'dndEndMinute',
  );
  @override
  late final GeneratedColumn<int> dndEndMinute = GeneratedColumn<int>(
    'dnd_end_minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dndEnabledMeta = const VerificationMeta(
    'dndEnabled',
  );
  @override
  late final GeneratedColumn<bool> dndEnabled = GeneratedColumn<bool>(
    'dnd_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dnd_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dailyTargetMl,
    notificationIntervalMinutes,
    dndStartHour,
    dndStartMinute,
    dndEndHour,
    dndEndMinute,
    dndEnabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('daily_target_ml')) {
      context.handle(
        _dailyTargetMlMeta,
        dailyTargetMl.isAcceptableOrUnknown(
          data['daily_target_ml']!,
          _dailyTargetMlMeta,
        ),
      );
    }
    if (data.containsKey('notification_interval_minutes')) {
      context.handle(
        _notificationIntervalMinutesMeta,
        notificationIntervalMinutes.isAcceptableOrUnknown(
          data['notification_interval_minutes']!,
          _notificationIntervalMinutesMeta,
        ),
      );
    }
    if (data.containsKey('dnd_start_hour')) {
      context.handle(
        _dndStartHourMeta,
        dndStartHour.isAcceptableOrUnknown(
          data['dnd_start_hour']!,
          _dndStartHourMeta,
        ),
      );
    }
    if (data.containsKey('dnd_start_minute')) {
      context.handle(
        _dndStartMinuteMeta,
        dndStartMinute.isAcceptableOrUnknown(
          data['dnd_start_minute']!,
          _dndStartMinuteMeta,
        ),
      );
    }
    if (data.containsKey('dnd_end_hour')) {
      context.handle(
        _dndEndHourMeta,
        dndEndHour.isAcceptableOrUnknown(
          data['dnd_end_hour']!,
          _dndEndHourMeta,
        ),
      );
    }
    if (data.containsKey('dnd_end_minute')) {
      context.handle(
        _dndEndMinuteMeta,
        dndEndMinute.isAcceptableOrUnknown(
          data['dnd_end_minute']!,
          _dndEndMinuteMeta,
        ),
      );
    }
    if (data.containsKey('dnd_enabled')) {
      context.handle(
        _dndEnabledMeta,
        dndEnabled.isAcceptableOrUnknown(data['dnd_enabled']!, _dndEnabledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dailyTargetMl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_target_ml'],
      )!,
      notificationIntervalMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notification_interval_minutes'],
      )!,
      dndStartHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dnd_start_hour'],
      )!,
      dndStartMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dnd_start_minute'],
      )!,
      dndEndHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dnd_end_hour'],
      )!,
      dndEndMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dnd_end_minute'],
      )!,
      dndEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dnd_enabled'],
      )!,
    );
  }

  @override
  $UserSettingsTable createAlias(String alias) {
    return $UserSettingsTable(attachedDatabase, alias);
  }
}

class UserSetting extends DataClass implements Insertable<UserSetting> {
  final int id;
  final int dailyTargetMl;
  final int notificationIntervalMinutes;
  final int dndStartHour;
  final int dndStartMinute;
  final int dndEndHour;
  final int dndEndMinute;
  final bool dndEnabled;
  const UserSetting({
    required this.id,
    required this.dailyTargetMl,
    required this.notificationIntervalMinutes,
    required this.dndStartHour,
    required this.dndStartMinute,
    required this.dndEndHour,
    required this.dndEndMinute,
    required this.dndEnabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['daily_target_ml'] = Variable<int>(dailyTargetMl);
    map['notification_interval_minutes'] = Variable<int>(
      notificationIntervalMinutes,
    );
    map['dnd_start_hour'] = Variable<int>(dndStartHour);
    map['dnd_start_minute'] = Variable<int>(dndStartMinute);
    map['dnd_end_hour'] = Variable<int>(dndEndHour);
    map['dnd_end_minute'] = Variable<int>(dndEndMinute);
    map['dnd_enabled'] = Variable<bool>(dndEnabled);
    return map;
  }

  UserSettingsCompanion toCompanion(bool nullToAbsent) {
    return UserSettingsCompanion(
      id: Value(id),
      dailyTargetMl: Value(dailyTargetMl),
      notificationIntervalMinutes: Value(notificationIntervalMinutes),
      dndStartHour: Value(dndStartHour),
      dndStartMinute: Value(dndStartMinute),
      dndEndHour: Value(dndEndHour),
      dndEndMinute: Value(dndEndMinute),
      dndEnabled: Value(dndEnabled),
    );
  }

  factory UserSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserSetting(
      id: serializer.fromJson<int>(json['id']),
      dailyTargetMl: serializer.fromJson<int>(json['dailyTargetMl']),
      notificationIntervalMinutes: serializer.fromJson<int>(
        json['notificationIntervalMinutes'],
      ),
      dndStartHour: serializer.fromJson<int>(json['dndStartHour']),
      dndStartMinute: serializer.fromJson<int>(json['dndStartMinute']),
      dndEndHour: serializer.fromJson<int>(json['dndEndHour']),
      dndEndMinute: serializer.fromJson<int>(json['dndEndMinute']),
      dndEnabled: serializer.fromJson<bool>(json['dndEnabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dailyTargetMl': serializer.toJson<int>(dailyTargetMl),
      'notificationIntervalMinutes': serializer.toJson<int>(
        notificationIntervalMinutes,
      ),
      'dndStartHour': serializer.toJson<int>(dndStartHour),
      'dndStartMinute': serializer.toJson<int>(dndStartMinute),
      'dndEndHour': serializer.toJson<int>(dndEndHour),
      'dndEndMinute': serializer.toJson<int>(dndEndMinute),
      'dndEnabled': serializer.toJson<bool>(dndEnabled),
    };
  }

  UserSetting copyWith({
    int? id,
    int? dailyTargetMl,
    int? notificationIntervalMinutes,
    int? dndStartHour,
    int? dndStartMinute,
    int? dndEndHour,
    int? dndEndMinute,
    bool? dndEnabled,
  }) => UserSetting(
    id: id ?? this.id,
    dailyTargetMl: dailyTargetMl ?? this.dailyTargetMl,
    notificationIntervalMinutes:
        notificationIntervalMinutes ?? this.notificationIntervalMinutes,
    dndStartHour: dndStartHour ?? this.dndStartHour,
    dndStartMinute: dndStartMinute ?? this.dndStartMinute,
    dndEndHour: dndEndHour ?? this.dndEndHour,
    dndEndMinute: dndEndMinute ?? this.dndEndMinute,
    dndEnabled: dndEnabled ?? this.dndEnabled,
  );
  UserSetting copyWithCompanion(UserSettingsCompanion data) {
    return UserSetting(
      id: data.id.present ? data.id.value : this.id,
      dailyTargetMl: data.dailyTargetMl.present
          ? data.dailyTargetMl.value
          : this.dailyTargetMl,
      notificationIntervalMinutes: data.notificationIntervalMinutes.present
          ? data.notificationIntervalMinutes.value
          : this.notificationIntervalMinutes,
      dndStartHour: data.dndStartHour.present
          ? data.dndStartHour.value
          : this.dndStartHour,
      dndStartMinute: data.dndStartMinute.present
          ? data.dndStartMinute.value
          : this.dndStartMinute,
      dndEndHour: data.dndEndHour.present
          ? data.dndEndHour.value
          : this.dndEndHour,
      dndEndMinute: data.dndEndMinute.present
          ? data.dndEndMinute.value
          : this.dndEndMinute,
      dndEnabled: data.dndEnabled.present
          ? data.dndEnabled.value
          : this.dndEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserSetting(')
          ..write('id: $id, ')
          ..write('dailyTargetMl: $dailyTargetMl, ')
          ..write('notificationIntervalMinutes: $notificationIntervalMinutes, ')
          ..write('dndStartHour: $dndStartHour, ')
          ..write('dndStartMinute: $dndStartMinute, ')
          ..write('dndEndHour: $dndEndHour, ')
          ..write('dndEndMinute: $dndEndMinute, ')
          ..write('dndEnabled: $dndEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dailyTargetMl,
    notificationIntervalMinutes,
    dndStartHour,
    dndStartMinute,
    dndEndHour,
    dndEndMinute,
    dndEnabled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserSetting &&
          other.id == this.id &&
          other.dailyTargetMl == this.dailyTargetMl &&
          other.notificationIntervalMinutes ==
              this.notificationIntervalMinutes &&
          other.dndStartHour == this.dndStartHour &&
          other.dndStartMinute == this.dndStartMinute &&
          other.dndEndHour == this.dndEndHour &&
          other.dndEndMinute == this.dndEndMinute &&
          other.dndEnabled == this.dndEnabled);
}

class UserSettingsCompanion extends UpdateCompanion<UserSetting> {
  final Value<int> id;
  final Value<int> dailyTargetMl;
  final Value<int> notificationIntervalMinutes;
  final Value<int> dndStartHour;
  final Value<int> dndStartMinute;
  final Value<int> dndEndHour;
  final Value<int> dndEndMinute;
  final Value<bool> dndEnabled;
  const UserSettingsCompanion({
    this.id = const Value.absent(),
    this.dailyTargetMl = const Value.absent(),
    this.notificationIntervalMinutes = const Value.absent(),
    this.dndStartHour = const Value.absent(),
    this.dndStartMinute = const Value.absent(),
    this.dndEndHour = const Value.absent(),
    this.dndEndMinute = const Value.absent(),
    this.dndEnabled = const Value.absent(),
  });
  UserSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.dailyTargetMl = const Value.absent(),
    this.notificationIntervalMinutes = const Value.absent(),
    this.dndStartHour = const Value.absent(),
    this.dndStartMinute = const Value.absent(),
    this.dndEndHour = const Value.absent(),
    this.dndEndMinute = const Value.absent(),
    this.dndEnabled = const Value.absent(),
  });
  static Insertable<UserSetting> custom({
    Expression<int>? id,
    Expression<int>? dailyTargetMl,
    Expression<int>? notificationIntervalMinutes,
    Expression<int>? dndStartHour,
    Expression<int>? dndStartMinute,
    Expression<int>? dndEndHour,
    Expression<int>? dndEndMinute,
    Expression<bool>? dndEnabled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dailyTargetMl != null) 'daily_target_ml': dailyTargetMl,
      if (notificationIntervalMinutes != null)
        'notification_interval_minutes': notificationIntervalMinutes,
      if (dndStartHour != null) 'dnd_start_hour': dndStartHour,
      if (dndStartMinute != null) 'dnd_start_minute': dndStartMinute,
      if (dndEndHour != null) 'dnd_end_hour': dndEndHour,
      if (dndEndMinute != null) 'dnd_end_minute': dndEndMinute,
      if (dndEnabled != null) 'dnd_enabled': dndEnabled,
    });
  }

  UserSettingsCompanion copyWith({
    Value<int>? id,
    Value<int>? dailyTargetMl,
    Value<int>? notificationIntervalMinutes,
    Value<int>? dndStartHour,
    Value<int>? dndStartMinute,
    Value<int>? dndEndHour,
    Value<int>? dndEndMinute,
    Value<bool>? dndEnabled,
  }) {
    return UserSettingsCompanion(
      id: id ?? this.id,
      dailyTargetMl: dailyTargetMl ?? this.dailyTargetMl,
      notificationIntervalMinutes:
          notificationIntervalMinutes ?? this.notificationIntervalMinutes,
      dndStartHour: dndStartHour ?? this.dndStartHour,
      dndStartMinute: dndStartMinute ?? this.dndStartMinute,
      dndEndHour: dndEndHour ?? this.dndEndHour,
      dndEndMinute: dndEndMinute ?? this.dndEndMinute,
      dndEnabled: dndEnabled ?? this.dndEnabled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dailyTargetMl.present) {
      map['daily_target_ml'] = Variable<int>(dailyTargetMl.value);
    }
    if (notificationIntervalMinutes.present) {
      map['notification_interval_minutes'] = Variable<int>(
        notificationIntervalMinutes.value,
      );
    }
    if (dndStartHour.present) {
      map['dnd_start_hour'] = Variable<int>(dndStartHour.value);
    }
    if (dndStartMinute.present) {
      map['dnd_start_minute'] = Variable<int>(dndStartMinute.value);
    }
    if (dndEndHour.present) {
      map['dnd_end_hour'] = Variable<int>(dndEndHour.value);
    }
    if (dndEndMinute.present) {
      map['dnd_end_minute'] = Variable<int>(dndEndMinute.value);
    }
    if (dndEnabled.present) {
      map['dnd_enabled'] = Variable<bool>(dndEnabled.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsCompanion(')
          ..write('id: $id, ')
          ..write('dailyTargetMl: $dailyTargetMl, ')
          ..write('notificationIntervalMinutes: $notificationIntervalMinutes, ')
          ..write('dndStartHour: $dndStartHour, ')
          ..write('dndStartMinute: $dndStartMinute, ')
          ..write('dndEndHour: $dndEndHour, ')
          ..write('dndEndMinute: $dndEndMinute, ')
          ..write('dndEnabled: $dndEnabled')
          ..write(')'))
        .toString();
  }
}

class $DrinkPresetsTable extends DrinkPresets
    with TableInfo<$DrinkPresetsTable, DrinkPreset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DrinkPresetsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _amountMlMeta = const VerificationMeta(
    'amountMl',
  );
  @override
  late final GeneratedColumn<int> amountMl = GeneratedColumn<int>(
    'amount_ml',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, amountMl, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drink_presets';
  @override
  VerificationContext validateIntegrity(
    Insertable<DrinkPreset> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('amount_ml')) {
      context.handle(
        _amountMlMeta,
        amountMl.isAcceptableOrUnknown(data['amount_ml']!, _amountMlMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMlMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DrinkPreset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DrinkPreset(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      amountMl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_ml'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $DrinkPresetsTable createAlias(String alias) {
    return $DrinkPresetsTable(attachedDatabase, alias);
  }
}

class DrinkPreset extends DataClass implements Insertable<DrinkPreset> {
  final int id;
  final int amountMl;
  final int sortOrder;
  const DrinkPreset({
    required this.id,
    required this.amountMl,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['amount_ml'] = Variable<int>(amountMl);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  DrinkPresetsCompanion toCompanion(bool nullToAbsent) {
    return DrinkPresetsCompanion(
      id: Value(id),
      amountMl: Value(amountMl),
      sortOrder: Value(sortOrder),
    );
  }

  factory DrinkPreset.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DrinkPreset(
      id: serializer.fromJson<int>(json['id']),
      amountMl: serializer.fromJson<int>(json['amountMl']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'amountMl': serializer.toJson<int>(amountMl),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  DrinkPreset copyWith({int? id, int? amountMl, int? sortOrder}) => DrinkPreset(
    id: id ?? this.id,
    amountMl: amountMl ?? this.amountMl,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  DrinkPreset copyWithCompanion(DrinkPresetsCompanion data) {
    return DrinkPreset(
      id: data.id.present ? data.id.value : this.id,
      amountMl: data.amountMl.present ? data.amountMl.value : this.amountMl,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DrinkPreset(')
          ..write('id: $id, ')
          ..write('amountMl: $amountMl, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, amountMl, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DrinkPreset &&
          other.id == this.id &&
          other.amountMl == this.amountMl &&
          other.sortOrder == this.sortOrder);
}

class DrinkPresetsCompanion extends UpdateCompanion<DrinkPreset> {
  final Value<int> id;
  final Value<int> amountMl;
  final Value<int> sortOrder;
  const DrinkPresetsCompanion({
    this.id = const Value.absent(),
    this.amountMl = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  DrinkPresetsCompanion.insert({
    this.id = const Value.absent(),
    required int amountMl,
    required int sortOrder,
  }) : amountMl = Value(amountMl),
       sortOrder = Value(sortOrder);
  static Insertable<DrinkPreset> custom({
    Expression<int>? id,
    Expression<int>? amountMl,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amountMl != null) 'amount_ml': amountMl,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  DrinkPresetsCompanion copyWith({
    Value<int>? id,
    Value<int>? amountMl,
    Value<int>? sortOrder,
  }) {
    return DrinkPresetsCompanion(
      id: id ?? this.id,
      amountMl: amountMl ?? this.amountMl,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (amountMl.present) {
      map['amount_ml'] = Variable<int>(amountMl.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DrinkPresetsCompanion(')
          ..write('id: $id, ')
          ..write('amountMl: $amountMl, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $TargetHistoryTable extends TargetHistory
    with TableInfo<$TargetHistoryTable, TargetHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TargetHistoryTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _effectiveDateMeta = const VerificationMeta(
    'effectiveDate',
  );
  @override
  late final GeneratedColumn<String> effectiveDate = GeneratedColumn<String>(
    'effective_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _targetMlMeta = const VerificationMeta(
    'targetMl',
  );
  @override
  late final GeneratedColumn<int> targetMl = GeneratedColumn<int>(
    'target_ml',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, effectiveDate, targetMl];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'target_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<TargetHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('effective_date')) {
      context.handle(
        _effectiveDateMeta,
        effectiveDate.isAcceptableOrUnknown(
          data['effective_date']!,
          _effectiveDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_effectiveDateMeta);
    }
    if (data.containsKey('target_ml')) {
      context.handle(
        _targetMlMeta,
        targetMl.isAcceptableOrUnknown(data['target_ml']!, _targetMlMeta),
      );
    } else if (isInserting) {
      context.missing(_targetMlMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TargetHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TargetHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      effectiveDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}effective_date'],
      )!,
      targetMl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_ml'],
      )!,
    );
  }

  @override
  $TargetHistoryTable createAlias(String alias) {
    return $TargetHistoryTable(attachedDatabase, alias);
  }
}

class TargetHistoryData extends DataClass
    implements Insertable<TargetHistoryData> {
  final int id;
  final String effectiveDate;
  final int targetMl;
  const TargetHistoryData({
    required this.id,
    required this.effectiveDate,
    required this.targetMl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['effective_date'] = Variable<String>(effectiveDate);
    map['target_ml'] = Variable<int>(targetMl);
    return map;
  }

  TargetHistoryCompanion toCompanion(bool nullToAbsent) {
    return TargetHistoryCompanion(
      id: Value(id),
      effectiveDate: Value(effectiveDate),
      targetMl: Value(targetMl),
    );
  }

  factory TargetHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TargetHistoryData(
      id: serializer.fromJson<int>(json['id']),
      effectiveDate: serializer.fromJson<String>(json['effectiveDate']),
      targetMl: serializer.fromJson<int>(json['targetMl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'effectiveDate': serializer.toJson<String>(effectiveDate),
      'targetMl': serializer.toJson<int>(targetMl),
    };
  }

  TargetHistoryData copyWith({int? id, String? effectiveDate, int? targetMl}) =>
      TargetHistoryData(
        id: id ?? this.id,
        effectiveDate: effectiveDate ?? this.effectiveDate,
        targetMl: targetMl ?? this.targetMl,
      );
  TargetHistoryData copyWithCompanion(TargetHistoryCompanion data) {
    return TargetHistoryData(
      id: data.id.present ? data.id.value : this.id,
      effectiveDate: data.effectiveDate.present
          ? data.effectiveDate.value
          : this.effectiveDate,
      targetMl: data.targetMl.present ? data.targetMl.value : this.targetMl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TargetHistoryData(')
          ..write('id: $id, ')
          ..write('effectiveDate: $effectiveDate, ')
          ..write('targetMl: $targetMl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, effectiveDate, targetMl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TargetHistoryData &&
          other.id == this.id &&
          other.effectiveDate == this.effectiveDate &&
          other.targetMl == this.targetMl);
}

class TargetHistoryCompanion extends UpdateCompanion<TargetHistoryData> {
  final Value<int> id;
  final Value<String> effectiveDate;
  final Value<int> targetMl;
  const TargetHistoryCompanion({
    this.id = const Value.absent(),
    this.effectiveDate = const Value.absent(),
    this.targetMl = const Value.absent(),
  });
  TargetHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String effectiveDate,
    required int targetMl,
  }) : effectiveDate = Value(effectiveDate),
       targetMl = Value(targetMl);
  static Insertable<TargetHistoryData> custom({
    Expression<int>? id,
    Expression<String>? effectiveDate,
    Expression<int>? targetMl,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (effectiveDate != null) 'effective_date': effectiveDate,
      if (targetMl != null) 'target_ml': targetMl,
    });
  }

  TargetHistoryCompanion copyWith({
    Value<int>? id,
    Value<String>? effectiveDate,
    Value<int>? targetMl,
  }) {
    return TargetHistoryCompanion(
      id: id ?? this.id,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      targetMl: targetMl ?? this.targetMl,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (effectiveDate.present) {
      map['effective_date'] = Variable<String>(effectiveDate.value);
    }
    if (targetMl.present) {
      map['target_ml'] = Variable<int>(targetMl.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TargetHistoryCompanion(')
          ..write('id: $id, ')
          ..write('effectiveDate: $effectiveDate, ')
          ..write('targetMl: $targetMl')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WaterEntriesTable waterEntries = $WaterEntriesTable(this);
  late final $UserSettingsTable userSettings = $UserSettingsTable(this);
  late final $DrinkPresetsTable drinkPresets = $DrinkPresetsTable(this);
  late final $TargetHistoryTable targetHistory = $TargetHistoryTable(this);
  late final Index idxWaterEntriesDateKey = Index(
    'idx_water_entries_date_key',
    'CREATE INDEX idx_water_entries_date_key ON water_entries (date_key)',
  );
  late final WaterEntryDao waterEntryDao = WaterEntryDao(this as AppDatabase);
  late final UserSettingsDao userSettingsDao = UserSettingsDao(
    this as AppDatabase,
  );
  late final DrinkPresetDao drinkPresetDao = DrinkPresetDao(
    this as AppDatabase,
  );
  late final TargetHistoryDao targetHistoryDao = TargetHistoryDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    waterEntries,
    userSettings,
    drinkPresets,
    targetHistory,
    idxWaterEntriesDateKey,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$WaterEntriesTableCreateCompanionBuilder =
    WaterEntriesCompanion Function({
      Value<int> id,
      required int amountMl,
      required DateTime loggedAt,
      required String dateKey,
    });
typedef $$WaterEntriesTableUpdateCompanionBuilder =
    WaterEntriesCompanion Function({
      Value<int> id,
      Value<int> amountMl,
      Value<DateTime> loggedAt,
      Value<String> dateKey,
    });

class $$WaterEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $WaterEntriesTable> {
  $$WaterEntriesTableFilterComposer({
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

  ColumnFilters<int> get amountMl => $composableBuilder(
    column: $table.amountMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dateKey => $composableBuilder(
    column: $table.dateKey,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WaterEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $WaterEntriesTable> {
  $$WaterEntriesTableOrderingComposer({
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

  ColumnOrderings<int> get amountMl => $composableBuilder(
    column: $table.amountMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dateKey => $composableBuilder(
    column: $table.dateKey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WaterEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WaterEntriesTable> {
  $$WaterEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountMl =>
      $composableBuilder(column: $table.amountMl, builder: (column) => column);

  GeneratedColumn<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);

  GeneratedColumn<String> get dateKey =>
      $composableBuilder(column: $table.dateKey, builder: (column) => column);
}

class $$WaterEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WaterEntriesTable,
          WaterEntry,
          $$WaterEntriesTableFilterComposer,
          $$WaterEntriesTableOrderingComposer,
          $$WaterEntriesTableAnnotationComposer,
          $$WaterEntriesTableCreateCompanionBuilder,
          $$WaterEntriesTableUpdateCompanionBuilder,
          (
            WaterEntry,
            BaseReferences<_$AppDatabase, $WaterEntriesTable, WaterEntry>,
          ),
          WaterEntry,
          PrefetchHooks Function()
        > {
  $$WaterEntriesTableTableManager(_$AppDatabase db, $WaterEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WaterEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WaterEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WaterEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> amountMl = const Value.absent(),
                Value<DateTime> loggedAt = const Value.absent(),
                Value<String> dateKey = const Value.absent(),
              }) => WaterEntriesCompanion(
                id: id,
                amountMl: amountMl,
                loggedAt: loggedAt,
                dateKey: dateKey,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int amountMl,
                required DateTime loggedAt,
                required String dateKey,
              }) => WaterEntriesCompanion.insert(
                id: id,
                amountMl: amountMl,
                loggedAt: loggedAt,
                dateKey: dateKey,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WaterEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WaterEntriesTable,
      WaterEntry,
      $$WaterEntriesTableFilterComposer,
      $$WaterEntriesTableOrderingComposer,
      $$WaterEntriesTableAnnotationComposer,
      $$WaterEntriesTableCreateCompanionBuilder,
      $$WaterEntriesTableUpdateCompanionBuilder,
      (
        WaterEntry,
        BaseReferences<_$AppDatabase, $WaterEntriesTable, WaterEntry>,
      ),
      WaterEntry,
      PrefetchHooks Function()
    >;
typedef $$UserSettingsTableCreateCompanionBuilder =
    UserSettingsCompanion Function({
      Value<int> id,
      Value<int> dailyTargetMl,
      Value<int> notificationIntervalMinutes,
      Value<int> dndStartHour,
      Value<int> dndStartMinute,
      Value<int> dndEndHour,
      Value<int> dndEndMinute,
      Value<bool> dndEnabled,
    });
typedef $$UserSettingsTableUpdateCompanionBuilder =
    UserSettingsCompanion Function({
      Value<int> id,
      Value<int> dailyTargetMl,
      Value<int> notificationIntervalMinutes,
      Value<int> dndStartHour,
      Value<int> dndStartMinute,
      Value<int> dndEndHour,
      Value<int> dndEndMinute,
      Value<bool> dndEnabled,
    });

class $$UserSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableFilterComposer({
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

  ColumnFilters<int> get dailyTargetMl => $composableBuilder(
    column: $table.dailyTargetMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get notificationIntervalMinutes => $composableBuilder(
    column: $table.notificationIntervalMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dndStartHour => $composableBuilder(
    column: $table.dndStartHour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dndStartMinute => $composableBuilder(
    column: $table.dndStartMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dndEndHour => $composableBuilder(
    column: $table.dndEndHour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dndEndMinute => $composableBuilder(
    column: $table.dndEndMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dndEnabled => $composableBuilder(
    column: $table.dndEnabled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableOrderingComposer({
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

  ColumnOrderings<int> get dailyTargetMl => $composableBuilder(
    column: $table.dailyTargetMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get notificationIntervalMinutes => $composableBuilder(
    column: $table.notificationIntervalMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dndStartHour => $composableBuilder(
    column: $table.dndStartHour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dndStartMinute => $composableBuilder(
    column: $table.dndStartMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dndEndHour => $composableBuilder(
    column: $table.dndEndHour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dndEndMinute => $composableBuilder(
    column: $table.dndEndMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dndEnabled => $composableBuilder(
    column: $table.dndEnabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dailyTargetMl => $composableBuilder(
    column: $table.dailyTargetMl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get notificationIntervalMinutes => $composableBuilder(
    column: $table.notificationIntervalMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dndStartHour => $composableBuilder(
    column: $table.dndStartHour,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dndStartMinute => $composableBuilder(
    column: $table.dndStartMinute,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dndEndHour => $composableBuilder(
    column: $table.dndEndHour,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dndEndMinute => $composableBuilder(
    column: $table.dndEndMinute,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get dndEnabled => $composableBuilder(
    column: $table.dndEnabled,
    builder: (column) => column,
  );
}

class $$UserSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserSettingsTable,
          UserSetting,
          $$UserSettingsTableFilterComposer,
          $$UserSettingsTableOrderingComposer,
          $$UserSettingsTableAnnotationComposer,
          $$UserSettingsTableCreateCompanionBuilder,
          $$UserSettingsTableUpdateCompanionBuilder,
          (
            UserSetting,
            BaseReferences<_$AppDatabase, $UserSettingsTable, UserSetting>,
          ),
          UserSetting,
          PrefetchHooks Function()
        > {
  $$UserSettingsTableTableManager(_$AppDatabase db, $UserSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dailyTargetMl = const Value.absent(),
                Value<int> notificationIntervalMinutes = const Value.absent(),
                Value<int> dndStartHour = const Value.absent(),
                Value<int> dndStartMinute = const Value.absent(),
                Value<int> dndEndHour = const Value.absent(),
                Value<int> dndEndMinute = const Value.absent(),
                Value<bool> dndEnabled = const Value.absent(),
              }) => UserSettingsCompanion(
                id: id,
                dailyTargetMl: dailyTargetMl,
                notificationIntervalMinutes: notificationIntervalMinutes,
                dndStartHour: dndStartHour,
                dndStartMinute: dndStartMinute,
                dndEndHour: dndEndHour,
                dndEndMinute: dndEndMinute,
                dndEnabled: dndEnabled,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dailyTargetMl = const Value.absent(),
                Value<int> notificationIntervalMinutes = const Value.absent(),
                Value<int> dndStartHour = const Value.absent(),
                Value<int> dndStartMinute = const Value.absent(),
                Value<int> dndEndHour = const Value.absent(),
                Value<int> dndEndMinute = const Value.absent(),
                Value<bool> dndEnabled = const Value.absent(),
              }) => UserSettingsCompanion.insert(
                id: id,
                dailyTargetMl: dailyTargetMl,
                notificationIntervalMinutes: notificationIntervalMinutes,
                dndStartHour: dndStartHour,
                dndStartMinute: dndStartMinute,
                dndEndHour: dndEndHour,
                dndEndMinute: dndEndMinute,
                dndEnabled: dndEnabled,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserSettingsTable,
      UserSetting,
      $$UserSettingsTableFilterComposer,
      $$UserSettingsTableOrderingComposer,
      $$UserSettingsTableAnnotationComposer,
      $$UserSettingsTableCreateCompanionBuilder,
      $$UserSettingsTableUpdateCompanionBuilder,
      (
        UserSetting,
        BaseReferences<_$AppDatabase, $UserSettingsTable, UserSetting>,
      ),
      UserSetting,
      PrefetchHooks Function()
    >;
typedef $$DrinkPresetsTableCreateCompanionBuilder =
    DrinkPresetsCompanion Function({
      Value<int> id,
      required int amountMl,
      required int sortOrder,
    });
typedef $$DrinkPresetsTableUpdateCompanionBuilder =
    DrinkPresetsCompanion Function({
      Value<int> id,
      Value<int> amountMl,
      Value<int> sortOrder,
    });

class $$DrinkPresetsTableFilterComposer
    extends Composer<_$AppDatabase, $DrinkPresetsTable> {
  $$DrinkPresetsTableFilterComposer({
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

  ColumnFilters<int> get amountMl => $composableBuilder(
    column: $table.amountMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DrinkPresetsTableOrderingComposer
    extends Composer<_$AppDatabase, $DrinkPresetsTable> {
  $$DrinkPresetsTableOrderingComposer({
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

  ColumnOrderings<int> get amountMl => $composableBuilder(
    column: $table.amountMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DrinkPresetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DrinkPresetsTable> {
  $$DrinkPresetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountMl =>
      $composableBuilder(column: $table.amountMl, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$DrinkPresetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DrinkPresetsTable,
          DrinkPreset,
          $$DrinkPresetsTableFilterComposer,
          $$DrinkPresetsTableOrderingComposer,
          $$DrinkPresetsTableAnnotationComposer,
          $$DrinkPresetsTableCreateCompanionBuilder,
          $$DrinkPresetsTableUpdateCompanionBuilder,
          (
            DrinkPreset,
            BaseReferences<_$AppDatabase, $DrinkPresetsTable, DrinkPreset>,
          ),
          DrinkPreset,
          PrefetchHooks Function()
        > {
  $$DrinkPresetsTableTableManager(_$AppDatabase db, $DrinkPresetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DrinkPresetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DrinkPresetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DrinkPresetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> amountMl = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => DrinkPresetsCompanion(
                id: id,
                amountMl: amountMl,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int amountMl,
                required int sortOrder,
              }) => DrinkPresetsCompanion.insert(
                id: id,
                amountMl: amountMl,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DrinkPresetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DrinkPresetsTable,
      DrinkPreset,
      $$DrinkPresetsTableFilterComposer,
      $$DrinkPresetsTableOrderingComposer,
      $$DrinkPresetsTableAnnotationComposer,
      $$DrinkPresetsTableCreateCompanionBuilder,
      $$DrinkPresetsTableUpdateCompanionBuilder,
      (
        DrinkPreset,
        BaseReferences<_$AppDatabase, $DrinkPresetsTable, DrinkPreset>,
      ),
      DrinkPreset,
      PrefetchHooks Function()
    >;
typedef $$TargetHistoryTableCreateCompanionBuilder =
    TargetHistoryCompanion Function({
      Value<int> id,
      required String effectiveDate,
      required int targetMl,
    });
typedef $$TargetHistoryTableUpdateCompanionBuilder =
    TargetHistoryCompanion Function({
      Value<int> id,
      Value<String> effectiveDate,
      Value<int> targetMl,
    });

class $$TargetHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $TargetHistoryTable> {
  $$TargetHistoryTableFilterComposer({
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

  ColumnFilters<String> get effectiveDate => $composableBuilder(
    column: $table.effectiveDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetMl => $composableBuilder(
    column: $table.targetMl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TargetHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $TargetHistoryTable> {
  $$TargetHistoryTableOrderingComposer({
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

  ColumnOrderings<String> get effectiveDate => $composableBuilder(
    column: $table.effectiveDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetMl => $composableBuilder(
    column: $table.targetMl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TargetHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $TargetHistoryTable> {
  $$TargetHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get effectiveDate => $composableBuilder(
    column: $table.effectiveDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetMl =>
      $composableBuilder(column: $table.targetMl, builder: (column) => column);
}

class $$TargetHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TargetHistoryTable,
          TargetHistoryData,
          $$TargetHistoryTableFilterComposer,
          $$TargetHistoryTableOrderingComposer,
          $$TargetHistoryTableAnnotationComposer,
          $$TargetHistoryTableCreateCompanionBuilder,
          $$TargetHistoryTableUpdateCompanionBuilder,
          (
            TargetHistoryData,
            BaseReferences<
              _$AppDatabase,
              $TargetHistoryTable,
              TargetHistoryData
            >,
          ),
          TargetHistoryData,
          PrefetchHooks Function()
        > {
  $$TargetHistoryTableTableManager(_$AppDatabase db, $TargetHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TargetHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TargetHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TargetHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> effectiveDate = const Value.absent(),
                Value<int> targetMl = const Value.absent(),
              }) => TargetHistoryCompanion(
                id: id,
                effectiveDate: effectiveDate,
                targetMl: targetMl,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String effectiveDate,
                required int targetMl,
              }) => TargetHistoryCompanion.insert(
                id: id,
                effectiveDate: effectiveDate,
                targetMl: targetMl,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TargetHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TargetHistoryTable,
      TargetHistoryData,
      $$TargetHistoryTableFilterComposer,
      $$TargetHistoryTableOrderingComposer,
      $$TargetHistoryTableAnnotationComposer,
      $$TargetHistoryTableCreateCompanionBuilder,
      $$TargetHistoryTableUpdateCompanionBuilder,
      (
        TargetHistoryData,
        BaseReferences<_$AppDatabase, $TargetHistoryTable, TargetHistoryData>,
      ),
      TargetHistoryData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WaterEntriesTableTableManager get waterEntries =>
      $$WaterEntriesTableTableManager(_db, _db.waterEntries);
  $$UserSettingsTableTableManager get userSettings =>
      $$UserSettingsTableTableManager(_db, _db.userSettings);
  $$DrinkPresetsTableTableManager get drinkPresets =>
      $$DrinkPresetsTableTableManager(_db, _db.drinkPresets);
  $$TargetHistoryTableTableManager get targetHistory =>
      $$TargetHistoryTableTableManager(_db, _db.targetHistory);
}
