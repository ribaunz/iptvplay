// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $PlaylistsTable extends Playlists
    with TableInfo<$PlaylistsTable, Playlist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PlaylistType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PlaylistType>($PlaylistsTable.$convertertype);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hostMeta = const VerificationMeta('host');
  @override
  late final GeneratedColumn<String> host = GeneratedColumn<String>(
    'host',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _portMeta = const VerificationMeta('port');
  @override
  late final GeneratedColumn<int> port = GeneratedColumn<int>(
    'port',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userAgentMeta = const VerificationMeta(
    'userAgent',
  );
  @override
  late final GeneratedColumn<String> userAgent = GeneratedColumn<String>(
    'user_agent',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _epgUrlMeta = const VerificationMeta('epgUrl');
  @override
  late final GeneratedColumn<String> epgUrl = GeneratedColumn<String>(
    'epg_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _channelCountMeta = const VerificationMeta(
    'channelCount',
  );
  @override
  late final GeneratedColumn<int> channelCount = GeneratedColumn<int>(
    'channel_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    url,
    host,
    port,
    username,
    userAgent,
    epgUrl,
    lastSyncAt,
    channelCount,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<Playlist> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('host')) {
      context.handle(
        _hostMeta,
        host.isAcceptableOrUnknown(data['host']!, _hostMeta),
      );
    }
    if (data.containsKey('port')) {
      context.handle(
        _portMeta,
        port.isAcceptableOrUnknown(data['port']!, _portMeta),
      );
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    }
    if (data.containsKey('user_agent')) {
      context.handle(
        _userAgentMeta,
        userAgent.isAcceptableOrUnknown(data['user_agent']!, _userAgentMeta),
      );
    }
    if (data.containsKey('epg_url')) {
      context.handle(
        _epgUrlMeta,
        epgUrl.isAcceptableOrUnknown(data['epg_url']!, _epgUrlMeta),
      );
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    if (data.containsKey('channel_count')) {
      context.handle(
        _channelCountMeta,
        channelCount.isAcceptableOrUnknown(
          data['channel_count']!,
          _channelCountMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Playlist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Playlist(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: $PlaylistsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      host: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}host'],
      ),
      port: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}port'],
      ),
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      ),
      userAgent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_agent'],
      ),
      epgUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}epg_url'],
      ),
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_at'],
      ),
      channelCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}channel_count'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $PlaylistsTable createAlias(String alias) {
    return $PlaylistsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PlaylistType, String, String> $convertertype =
      const EnumNameConverter<PlaylistType>(PlaylistType.values);
}

class Playlist extends DataClass implements Insertable<Playlist> {
  final int id;
  final String name;
  final PlaylistType type;

  /// URL della M3U, oppure `get.php?...` per Xtream.
  final String? url;
  final String? host;
  final int? port;
  final String? username;

  /// `User-Agent` con cui contattare questo provider.
  ///
  /// `null` significa "usa il default dell'app", non "non mandare nulla":
  /// esiste per i pannelli che pretendono una stringa propria, che né VLC né un
  /// browser coprono.
  final String? userAgent;
  final String? epgUrl;
  final DateTime? lastSyncAt;
  final int channelCount;
  final bool isActive;
  const Playlist({
    required this.id,
    required this.name,
    required this.type,
    this.url,
    this.host,
    this.port,
    this.username,
    this.userAgent,
    this.epgUrl,
    this.lastSyncAt,
    required this.channelCount,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<String>(
        $PlaylistsTable.$convertertype.toSql(type),
      );
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || host != null) {
      map['host'] = Variable<String>(host);
    }
    if (!nullToAbsent || port != null) {
      map['port'] = Variable<int>(port);
    }
    if (!nullToAbsent || username != null) {
      map['username'] = Variable<String>(username);
    }
    if (!nullToAbsent || userAgent != null) {
      map['user_agent'] = Variable<String>(userAgent);
    }
    if (!nullToAbsent || epgUrl != null) {
      map['epg_url'] = Variable<String>(epgUrl);
    }
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    map['channel_count'] = Variable<int>(channelCount);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  PlaylistsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      host: host == null && nullToAbsent ? const Value.absent() : Value(host),
      port: port == null && nullToAbsent ? const Value.absent() : Value(port),
      username: username == null && nullToAbsent
          ? const Value.absent()
          : Value(username),
      userAgent: userAgent == null && nullToAbsent
          ? const Value.absent()
          : Value(userAgent),
      epgUrl: epgUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(epgUrl),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
      channelCount: Value(channelCount),
      isActive: Value(isActive),
    );
  }

  factory Playlist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Playlist(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: $PlaylistsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      url: serializer.fromJson<String?>(json['url']),
      host: serializer.fromJson<String?>(json['host']),
      port: serializer.fromJson<int?>(json['port']),
      username: serializer.fromJson<String?>(json['username']),
      userAgent: serializer.fromJson<String?>(json['userAgent']),
      epgUrl: serializer.fromJson<String?>(json['epgUrl']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
      channelCount: serializer.fromJson<int>(json['channelCount']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(
        $PlaylistsTable.$convertertype.toJson(type),
      ),
      'url': serializer.toJson<String?>(url),
      'host': serializer.toJson<String?>(host),
      'port': serializer.toJson<int?>(port),
      'username': serializer.toJson<String?>(username),
      'userAgent': serializer.toJson<String?>(userAgent),
      'epgUrl': serializer.toJson<String?>(epgUrl),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
      'channelCount': serializer.toJson<int>(channelCount),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  Playlist copyWith({
    int? id,
    String? name,
    PlaylistType? type,
    Value<String?> url = const Value.absent(),
    Value<String?> host = const Value.absent(),
    Value<int?> port = const Value.absent(),
    Value<String?> username = const Value.absent(),
    Value<String?> userAgent = const Value.absent(),
    Value<String?> epgUrl = const Value.absent(),
    Value<DateTime?> lastSyncAt = const Value.absent(),
    int? channelCount,
    bool? isActive,
  }) => Playlist(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    url: url.present ? url.value : this.url,
    host: host.present ? host.value : this.host,
    port: port.present ? port.value : this.port,
    username: username.present ? username.value : this.username,
    userAgent: userAgent.present ? userAgent.value : this.userAgent,
    epgUrl: epgUrl.present ? epgUrl.value : this.epgUrl,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
    channelCount: channelCount ?? this.channelCount,
    isActive: isActive ?? this.isActive,
  );
  Playlist copyWithCompanion(PlaylistsCompanion data) {
    return Playlist(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      url: data.url.present ? data.url.value : this.url,
      host: data.host.present ? data.host.value : this.host,
      port: data.port.present ? data.port.value : this.port,
      username: data.username.present ? data.username.value : this.username,
      userAgent: data.userAgent.present ? data.userAgent.value : this.userAgent,
      epgUrl: data.epgUrl.present ? data.epgUrl.value : this.epgUrl,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
      channelCount: data.channelCount.present
          ? data.channelCount.value
          : this.channelCount,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Playlist(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('url: $url, ')
          ..write('host: $host, ')
          ..write('port: $port, ')
          ..write('username: $username, ')
          ..write('userAgent: $userAgent, ')
          ..write('epgUrl: $epgUrl, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('channelCount: $channelCount, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    url,
    host,
    port,
    username,
    userAgent,
    epgUrl,
    lastSyncAt,
    channelCount,
    isActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Playlist &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.url == this.url &&
          other.host == this.host &&
          other.port == this.port &&
          other.username == this.username &&
          other.userAgent == this.userAgent &&
          other.epgUrl == this.epgUrl &&
          other.lastSyncAt == this.lastSyncAt &&
          other.channelCount == this.channelCount &&
          other.isActive == this.isActive);
}

class PlaylistsCompanion extends UpdateCompanion<Playlist> {
  final Value<int> id;
  final Value<String> name;
  final Value<PlaylistType> type;
  final Value<String?> url;
  final Value<String?> host;
  final Value<int?> port;
  final Value<String?> username;
  final Value<String?> userAgent;
  final Value<String?> epgUrl;
  final Value<DateTime?> lastSyncAt;
  final Value<int> channelCount;
  final Value<bool> isActive;
  const PlaylistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.url = const Value.absent(),
    this.host = const Value.absent(),
    this.port = const Value.absent(),
    this.username = const Value.absent(),
    this.userAgent = const Value.absent(),
    this.epgUrl = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.channelCount = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  PlaylistsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required PlaylistType type,
    this.url = const Value.absent(),
    this.host = const Value.absent(),
    this.port = const Value.absent(),
    this.username = const Value.absent(),
    this.userAgent = const Value.absent(),
    this.epgUrl = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.channelCount = const Value.absent(),
    this.isActive = const Value.absent(),
  }) : name = Value(name),
       type = Value(type);
  static Insertable<Playlist> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? url,
    Expression<String>? host,
    Expression<int>? port,
    Expression<String>? username,
    Expression<String>? userAgent,
    Expression<String>? epgUrl,
    Expression<DateTime>? lastSyncAt,
    Expression<int>? channelCount,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (url != null) 'url': url,
      if (host != null) 'host': host,
      if (port != null) 'port': port,
      if (username != null) 'username': username,
      if (userAgent != null) 'user_agent': userAgent,
      if (epgUrl != null) 'epg_url': epgUrl,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (channelCount != null) 'channel_count': channelCount,
      if (isActive != null) 'is_active': isActive,
    });
  }

  PlaylistsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<PlaylistType>? type,
    Value<String?>? url,
    Value<String?>? host,
    Value<int?>? port,
    Value<String?>? username,
    Value<String?>? userAgent,
    Value<String?>? epgUrl,
    Value<DateTime?>? lastSyncAt,
    Value<int>? channelCount,
    Value<bool>? isActive,
  }) {
    return PlaylistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      url: url ?? this.url,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      userAgent: userAgent ?? this.userAgent,
      epgUrl: epgUrl ?? this.epgUrl,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      channelCount: channelCount ?? this.channelCount,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $PlaylistsTable.$convertertype.toSql(type.value),
      );
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (host.present) {
      map['host'] = Variable<String>(host.value);
    }
    if (port.present) {
      map['port'] = Variable<int>(port.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (userAgent.present) {
      map['user_agent'] = Variable<String>(userAgent.value);
    }
    if (epgUrl.present) {
      map['epg_url'] = Variable<String>(epgUrl.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (channelCount.present) {
      map['channel_count'] = Variable<int>(channelCount.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('url: $url, ')
          ..write('host: $host, ')
          ..write('port: $port, ')
          ..write('username: $username, ')
          ..write('userAgent: $userAgent, ')
          ..write('epgUrl: $epgUrl, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('channelCount: $channelCount, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

class $GroupsTable extends Groups with TableInfo<$GroupsTable, Group> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<int> playlistId = GeneratedColumn<int>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES playlists (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _channelCountMeta = const VerificationMeta(
    'channelCount',
  );
  @override
  late final GeneratedColumn<int> channelCount = GeneratedColumn<int>(
    'channel_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    playlistId,
    name,
    sortOrder,
    channelCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<Group> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('channel_count')) {
      context.handle(
        _channelCountMeta,
        channelCount.isAcceptableOrUnknown(
          data['channel_count']!,
          _channelCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Group map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Group(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}playlist_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      channelCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}channel_count'],
      )!,
    );
  }

  @override
  $GroupsTable createAlias(String alias) {
    return $GroupsTable(attachedDatabase, alias);
  }
}

class Group extends DataClass implements Insertable<Group> {
  final int id;
  final int playlistId;
  final String name;
  final int sortOrder;
  final int channelCount;
  const Group({
    required this.id,
    required this.playlistId,
    required this.name,
    required this.sortOrder,
    required this.channelCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['playlist_id'] = Variable<int>(playlistId);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    map['channel_count'] = Variable<int>(channelCount);
    return map;
  }

  GroupsCompanion toCompanion(bool nullToAbsent) {
    return GroupsCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      name: Value(name),
      sortOrder: Value(sortOrder),
      channelCount: Value(channelCount),
    );
  }

  factory Group.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Group(
      id: serializer.fromJson<int>(json['id']),
      playlistId: serializer.fromJson<int>(json['playlistId']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      channelCount: serializer.fromJson<int>(json['channelCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playlistId': serializer.toJson<int>(playlistId),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'channelCount': serializer.toJson<int>(channelCount),
    };
  }

  Group copyWith({
    int? id,
    int? playlistId,
    String? name,
    int? sortOrder,
    int? channelCount,
  }) => Group(
    id: id ?? this.id,
    playlistId: playlistId ?? this.playlistId,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
    channelCount: channelCount ?? this.channelCount,
  );
  Group copyWithCompanion(GroupsCompanion data) {
    return Group(
      id: data.id.present ? data.id.value : this.id,
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      channelCount: data.channelCount.present
          ? data.channelCount.value
          : this.channelCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Group(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('channelCount: $channelCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, playlistId, name, sortOrder, channelCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Group &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.channelCount == this.channelCount);
}

class GroupsCompanion extends UpdateCompanion<Group> {
  final Value<int> id;
  final Value<int> playlistId;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<int> channelCount;
  const GroupsCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.channelCount = const Value.absent(),
  });
  GroupsCompanion.insert({
    this.id = const Value.absent(),
    required int playlistId,
    required String name,
    this.sortOrder = const Value.absent(),
    this.channelCount = const Value.absent(),
  }) : playlistId = Value(playlistId),
       name = Value(name);
  static Insertable<Group> custom({
    Expression<int>? id,
    Expression<int>? playlistId,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<int>? channelCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (channelCount != null) 'channel_count': channelCount,
    });
  }

  GroupsCompanion copyWith({
    Value<int>? id,
    Value<int>? playlistId,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<int>? channelCount,
  }) {
    return GroupsCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      channelCount: channelCount ?? this.channelCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<int>(playlistId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (channelCount.present) {
      map['channel_count'] = Variable<int>(channelCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupsCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('channelCount: $channelCount')
          ..write(')'))
        .toString();
  }
}

class $ChannelsTable extends Channels with TableInfo<$ChannelsTable, Channel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChannelsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<int> playlistId = GeneratedColumn<int>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES playlists (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<int> groupId = GeneratedColumn<int>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES "groups" (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _logoUrlMeta = const VerificationMeta(
    'logoUrl',
  );
  @override
  late final GeneratedColumn<String> logoUrl = GeneratedColumn<String>(
    'logo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tvgIdMeta = const VerificationMeta('tvgId');
  @override
  late final GeneratedColumn<String> tvgId = GeneratedColumn<String>(
    'tvg_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tvgNameMeta = const VerificationMeta(
    'tvgName',
  );
  @override
  late final GeneratedColumn<String> tvgName = GeneratedColumn<String>(
    'tvg_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _streamIdMeta = const VerificationMeta(
    'streamId',
  );
  @override
  late final GeneratedColumn<int> streamId = GeneratedColumn<int>(
    'stream_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _containerExtMeta = const VerificationMeta(
    'containerExt',
  );
  @override
  late final GeneratedColumn<String> containerExt = GeneratedColumn<String>(
    'container_ext',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ChannelKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('live'),
      ).withConverter<ChannelKind>($ChannelsTable.$converterkind);
  static const VerificationMeta _tvArchiveMeta = const VerificationMeta(
    'tvArchive',
  );
  @override
  late final GeneratedColumn<bool> tvArchive = GeneratedColumn<bool>(
    'tv_archive',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("tv_archive" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _httpUserAgentMeta = const VerificationMeta(
    'httpUserAgent',
  );
  @override
  late final GeneratedColumn<String> httpUserAgent = GeneratedColumn<String>(
    'http_user_agent',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _httpReferrerMeta = const VerificationMeta(
    'httpReferrer',
  );
  @override
  late final GeneratedColumn<String> httpReferrer = GeneratedColumn<String>(
    'http_referrer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    playlistId,
    groupId,
    name,
    url,
    logoUrl,
    tvgId,
    tvgName,
    streamId,
    containerExt,
    kind,
    tvArchive,
    httpUserAgent,
    httpReferrer,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'channels';
  @override
  VerificationContext validateIntegrity(
    Insertable<Channel> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('logo_url')) {
      context.handle(
        _logoUrlMeta,
        logoUrl.isAcceptableOrUnknown(data['logo_url']!, _logoUrlMeta),
      );
    }
    if (data.containsKey('tvg_id')) {
      context.handle(
        _tvgIdMeta,
        tvgId.isAcceptableOrUnknown(data['tvg_id']!, _tvgIdMeta),
      );
    }
    if (data.containsKey('tvg_name')) {
      context.handle(
        _tvgNameMeta,
        tvgName.isAcceptableOrUnknown(data['tvg_name']!, _tvgNameMeta),
      );
    }
    if (data.containsKey('stream_id')) {
      context.handle(
        _streamIdMeta,
        streamId.isAcceptableOrUnknown(data['stream_id']!, _streamIdMeta),
      );
    }
    if (data.containsKey('container_ext')) {
      context.handle(
        _containerExtMeta,
        containerExt.isAcceptableOrUnknown(
          data['container_ext']!,
          _containerExtMeta,
        ),
      );
    }
    if (data.containsKey('tv_archive')) {
      context.handle(
        _tvArchiveMeta,
        tvArchive.isAcceptableOrUnknown(data['tv_archive']!, _tvArchiveMeta),
      );
    }
    if (data.containsKey('http_user_agent')) {
      context.handle(
        _httpUserAgentMeta,
        httpUserAgent.isAcceptableOrUnknown(
          data['http_user_agent']!,
          _httpUserAgentMeta,
        ),
      );
    }
    if (data.containsKey('http_referrer')) {
      context.handle(
        _httpReferrerMeta,
        httpReferrer.isAcceptableOrUnknown(
          data['http_referrer']!,
          _httpReferrerMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Channel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Channel(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}playlist_id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      logoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logo_url'],
      ),
      tvgId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tvg_id'],
      ),
      tvgName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tvg_name'],
      ),
      streamId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stream_id'],
      ),
      containerExt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}container_ext'],
      ),
      kind: $ChannelsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      tvArchive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}tv_archive'],
      )!,
      httpUserAgent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}http_user_agent'],
      ),
      httpReferrer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}http_referrer'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $ChannelsTable createAlias(String alias) {
    return $ChannelsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ChannelKind, String, String> $converterkind =
      const EnumNameConverter<ChannelKind>(ChannelKind.values);
}

class Channel extends DataClass implements Insertable<Channel> {
  final int id;
  final int playlistId;
  final int? groupId;
  final String name;
  final String url;
  final String? logoUrl;

  /// `tvg-id`: è la chiave di aggancio all'EPG.
  final String? tvgId;
  final String? tvgName;

  /// Solo Xtream: consente di ricostruire l'URL senza persistere le credenziali.
  final int? streamId;
  final String? containerExt;
  final ChannelKind kind;

  /// True se il provider espone il timeshift per questo canale.
  final bool tvArchive;

  /// Da `#EXTVLCOPT:http-user-agent` / `http-referrer`: alcuni provider
  /// servono lo stream solo con l'header giusto.
  final String? httpUserAgent;
  final String? httpReferrer;
  final int sortOrder;
  const Channel({
    required this.id,
    required this.playlistId,
    this.groupId,
    required this.name,
    required this.url,
    this.logoUrl,
    this.tvgId,
    this.tvgName,
    this.streamId,
    this.containerExt,
    required this.kind,
    required this.tvArchive,
    this.httpUserAgent,
    this.httpReferrer,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['playlist_id'] = Variable<int>(playlistId);
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<int>(groupId);
    }
    map['name'] = Variable<String>(name);
    map['url'] = Variable<String>(url);
    if (!nullToAbsent || logoUrl != null) {
      map['logo_url'] = Variable<String>(logoUrl);
    }
    if (!nullToAbsent || tvgId != null) {
      map['tvg_id'] = Variable<String>(tvgId);
    }
    if (!nullToAbsent || tvgName != null) {
      map['tvg_name'] = Variable<String>(tvgName);
    }
    if (!nullToAbsent || streamId != null) {
      map['stream_id'] = Variable<int>(streamId);
    }
    if (!nullToAbsent || containerExt != null) {
      map['container_ext'] = Variable<String>(containerExt);
    }
    {
      map['kind'] = Variable<String>($ChannelsTable.$converterkind.toSql(kind));
    }
    map['tv_archive'] = Variable<bool>(tvArchive);
    if (!nullToAbsent || httpUserAgent != null) {
      map['http_user_agent'] = Variable<String>(httpUserAgent);
    }
    if (!nullToAbsent || httpReferrer != null) {
      map['http_referrer'] = Variable<String>(httpReferrer);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ChannelsCompanion toCompanion(bool nullToAbsent) {
    return ChannelsCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      name: Value(name),
      url: Value(url),
      logoUrl: logoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(logoUrl),
      tvgId: tvgId == null && nullToAbsent
          ? const Value.absent()
          : Value(tvgId),
      tvgName: tvgName == null && nullToAbsent
          ? const Value.absent()
          : Value(tvgName),
      streamId: streamId == null && nullToAbsent
          ? const Value.absent()
          : Value(streamId),
      containerExt: containerExt == null && nullToAbsent
          ? const Value.absent()
          : Value(containerExt),
      kind: Value(kind),
      tvArchive: Value(tvArchive),
      httpUserAgent: httpUserAgent == null && nullToAbsent
          ? const Value.absent()
          : Value(httpUserAgent),
      httpReferrer: httpReferrer == null && nullToAbsent
          ? const Value.absent()
          : Value(httpReferrer),
      sortOrder: Value(sortOrder),
    );
  }

  factory Channel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Channel(
      id: serializer.fromJson<int>(json['id']),
      playlistId: serializer.fromJson<int>(json['playlistId']),
      groupId: serializer.fromJson<int?>(json['groupId']),
      name: serializer.fromJson<String>(json['name']),
      url: serializer.fromJson<String>(json['url']),
      logoUrl: serializer.fromJson<String?>(json['logoUrl']),
      tvgId: serializer.fromJson<String?>(json['tvgId']),
      tvgName: serializer.fromJson<String?>(json['tvgName']),
      streamId: serializer.fromJson<int?>(json['streamId']),
      containerExt: serializer.fromJson<String?>(json['containerExt']),
      kind: $ChannelsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      tvArchive: serializer.fromJson<bool>(json['tvArchive']),
      httpUserAgent: serializer.fromJson<String?>(json['httpUserAgent']),
      httpReferrer: serializer.fromJson<String?>(json['httpReferrer']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playlistId': serializer.toJson<int>(playlistId),
      'groupId': serializer.toJson<int?>(groupId),
      'name': serializer.toJson<String>(name),
      'url': serializer.toJson<String>(url),
      'logoUrl': serializer.toJson<String?>(logoUrl),
      'tvgId': serializer.toJson<String?>(tvgId),
      'tvgName': serializer.toJson<String?>(tvgName),
      'streamId': serializer.toJson<int?>(streamId),
      'containerExt': serializer.toJson<String?>(containerExt),
      'kind': serializer.toJson<String>(
        $ChannelsTable.$converterkind.toJson(kind),
      ),
      'tvArchive': serializer.toJson<bool>(tvArchive),
      'httpUserAgent': serializer.toJson<String?>(httpUserAgent),
      'httpReferrer': serializer.toJson<String?>(httpReferrer),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Channel copyWith({
    int? id,
    int? playlistId,
    Value<int?> groupId = const Value.absent(),
    String? name,
    String? url,
    Value<String?> logoUrl = const Value.absent(),
    Value<String?> tvgId = const Value.absent(),
    Value<String?> tvgName = const Value.absent(),
    Value<int?> streamId = const Value.absent(),
    Value<String?> containerExt = const Value.absent(),
    ChannelKind? kind,
    bool? tvArchive,
    Value<String?> httpUserAgent = const Value.absent(),
    Value<String?> httpReferrer = const Value.absent(),
    int? sortOrder,
  }) => Channel(
    id: id ?? this.id,
    playlistId: playlistId ?? this.playlistId,
    groupId: groupId.present ? groupId.value : this.groupId,
    name: name ?? this.name,
    url: url ?? this.url,
    logoUrl: logoUrl.present ? logoUrl.value : this.logoUrl,
    tvgId: tvgId.present ? tvgId.value : this.tvgId,
    tvgName: tvgName.present ? tvgName.value : this.tvgName,
    streamId: streamId.present ? streamId.value : this.streamId,
    containerExt: containerExt.present ? containerExt.value : this.containerExt,
    kind: kind ?? this.kind,
    tvArchive: tvArchive ?? this.tvArchive,
    httpUserAgent: httpUserAgent.present
        ? httpUserAgent.value
        : this.httpUserAgent,
    httpReferrer: httpReferrer.present ? httpReferrer.value : this.httpReferrer,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Channel copyWithCompanion(ChannelsCompanion data) {
    return Channel(
      id: data.id.present ? data.id.value : this.id,
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      name: data.name.present ? data.name.value : this.name,
      url: data.url.present ? data.url.value : this.url,
      logoUrl: data.logoUrl.present ? data.logoUrl.value : this.logoUrl,
      tvgId: data.tvgId.present ? data.tvgId.value : this.tvgId,
      tvgName: data.tvgName.present ? data.tvgName.value : this.tvgName,
      streamId: data.streamId.present ? data.streamId.value : this.streamId,
      containerExt: data.containerExt.present
          ? data.containerExt.value
          : this.containerExt,
      kind: data.kind.present ? data.kind.value : this.kind,
      tvArchive: data.tvArchive.present ? data.tvArchive.value : this.tvArchive,
      httpUserAgent: data.httpUserAgent.present
          ? data.httpUserAgent.value
          : this.httpUserAgent,
      httpReferrer: data.httpReferrer.present
          ? data.httpReferrer.value
          : this.httpReferrer,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Channel(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('tvgId: $tvgId, ')
          ..write('tvgName: $tvgName, ')
          ..write('streamId: $streamId, ')
          ..write('containerExt: $containerExt, ')
          ..write('kind: $kind, ')
          ..write('tvArchive: $tvArchive, ')
          ..write('httpUserAgent: $httpUserAgent, ')
          ..write('httpReferrer: $httpReferrer, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    playlistId,
    groupId,
    name,
    url,
    logoUrl,
    tvgId,
    tvgName,
    streamId,
    containerExt,
    kind,
    tvArchive,
    httpUserAgent,
    httpReferrer,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Channel &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.groupId == this.groupId &&
          other.name == this.name &&
          other.url == this.url &&
          other.logoUrl == this.logoUrl &&
          other.tvgId == this.tvgId &&
          other.tvgName == this.tvgName &&
          other.streamId == this.streamId &&
          other.containerExt == this.containerExt &&
          other.kind == this.kind &&
          other.tvArchive == this.tvArchive &&
          other.httpUserAgent == this.httpUserAgent &&
          other.httpReferrer == this.httpReferrer &&
          other.sortOrder == this.sortOrder);
}

class ChannelsCompanion extends UpdateCompanion<Channel> {
  final Value<int> id;
  final Value<int> playlistId;
  final Value<int?> groupId;
  final Value<String> name;
  final Value<String> url;
  final Value<String?> logoUrl;
  final Value<String?> tvgId;
  final Value<String?> tvgName;
  final Value<int?> streamId;
  final Value<String?> containerExt;
  final Value<ChannelKind> kind;
  final Value<bool> tvArchive;
  final Value<String?> httpUserAgent;
  final Value<String?> httpReferrer;
  final Value<int> sortOrder;
  const ChannelsCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.name = const Value.absent(),
    this.url = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.tvgId = const Value.absent(),
    this.tvgName = const Value.absent(),
    this.streamId = const Value.absent(),
    this.containerExt = const Value.absent(),
    this.kind = const Value.absent(),
    this.tvArchive = const Value.absent(),
    this.httpUserAgent = const Value.absent(),
    this.httpReferrer = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  ChannelsCompanion.insert({
    this.id = const Value.absent(),
    required int playlistId,
    this.groupId = const Value.absent(),
    required String name,
    required String url,
    this.logoUrl = const Value.absent(),
    this.tvgId = const Value.absent(),
    this.tvgName = const Value.absent(),
    this.streamId = const Value.absent(),
    this.containerExt = const Value.absent(),
    this.kind = const Value.absent(),
    this.tvArchive = const Value.absent(),
    this.httpUserAgent = const Value.absent(),
    this.httpReferrer = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : playlistId = Value(playlistId),
       name = Value(name),
       url = Value(url);
  static Insertable<Channel> custom({
    Expression<int>? id,
    Expression<int>? playlistId,
    Expression<int>? groupId,
    Expression<String>? name,
    Expression<String>? url,
    Expression<String>? logoUrl,
    Expression<String>? tvgId,
    Expression<String>? tvgName,
    Expression<int>? streamId,
    Expression<String>? containerExt,
    Expression<String>? kind,
    Expression<bool>? tvArchive,
    Expression<String>? httpUserAgent,
    Expression<String>? httpReferrer,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (groupId != null) 'group_id': groupId,
      if (name != null) 'name': name,
      if (url != null) 'url': url,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (tvgId != null) 'tvg_id': tvgId,
      if (tvgName != null) 'tvg_name': tvgName,
      if (streamId != null) 'stream_id': streamId,
      if (containerExt != null) 'container_ext': containerExt,
      if (kind != null) 'kind': kind,
      if (tvArchive != null) 'tv_archive': tvArchive,
      if (httpUserAgent != null) 'http_user_agent': httpUserAgent,
      if (httpReferrer != null) 'http_referrer': httpReferrer,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  ChannelsCompanion copyWith({
    Value<int>? id,
    Value<int>? playlistId,
    Value<int?>? groupId,
    Value<String>? name,
    Value<String>? url,
    Value<String?>? logoUrl,
    Value<String?>? tvgId,
    Value<String?>? tvgName,
    Value<int?>? streamId,
    Value<String?>? containerExt,
    Value<ChannelKind>? kind,
    Value<bool>? tvArchive,
    Value<String?>? httpUserAgent,
    Value<String?>? httpReferrer,
    Value<int>? sortOrder,
  }) {
    return ChannelsCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      url: url ?? this.url,
      logoUrl: logoUrl ?? this.logoUrl,
      tvgId: tvgId ?? this.tvgId,
      tvgName: tvgName ?? this.tvgName,
      streamId: streamId ?? this.streamId,
      containerExt: containerExt ?? this.containerExt,
      kind: kind ?? this.kind,
      tvArchive: tvArchive ?? this.tvArchive,
      httpUserAgent: httpUserAgent ?? this.httpUserAgent,
      httpReferrer: httpReferrer ?? this.httpReferrer,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<int>(playlistId.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<int>(groupId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (logoUrl.present) {
      map['logo_url'] = Variable<String>(logoUrl.value);
    }
    if (tvgId.present) {
      map['tvg_id'] = Variable<String>(tvgId.value);
    }
    if (tvgName.present) {
      map['tvg_name'] = Variable<String>(tvgName.value);
    }
    if (streamId.present) {
      map['stream_id'] = Variable<int>(streamId.value);
    }
    if (containerExt.present) {
      map['container_ext'] = Variable<String>(containerExt.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $ChannelsTable.$converterkind.toSql(kind.value),
      );
    }
    if (tvArchive.present) {
      map['tv_archive'] = Variable<bool>(tvArchive.value);
    }
    if (httpUserAgent.present) {
      map['http_user_agent'] = Variable<String>(httpUserAgent.value);
    }
    if (httpReferrer.present) {
      map['http_referrer'] = Variable<String>(httpReferrer.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChannelsCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('tvgId: $tvgId, ')
          ..write('tvgName: $tvgName, ')
          ..write('streamId: $streamId, ')
          ..write('containerExt: $containerExt, ')
          ..write('kind: $kind, ')
          ..write('tvArchive: $tvArchive, ')
          ..write('httpUserAgent: $httpUserAgent, ')
          ..write('httpReferrer: $httpReferrer, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $EpgChannelsTable extends EpgChannels
    with TableInfo<$EpgChannelsTable, EpgChannel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpgChannelsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<int> playlistId = GeneratedColumn<int>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES playlists (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _xmltvIdMeta = const VerificationMeta(
    'xmltvId',
  );
  @override
  late final GeneratedColumn<String> xmltvId = GeneratedColumn<String>(
    'xmltv_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconUrlMeta = const VerificationMeta(
    'iconUrl',
  );
  @override
  late final GeneratedColumn<String> iconUrl = GeneratedColumn<String>(
    'icon_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    playlistId,
    xmltvId,
    displayName,
    iconUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'epg_channels';
  @override
  VerificationContext validateIntegrity(
    Insertable<EpgChannel> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('xmltv_id')) {
      context.handle(
        _xmltvIdMeta,
        xmltvId.isAcceptableOrUnknown(data['xmltv_id']!, _xmltvIdMeta),
      );
    } else if (isInserting) {
      context.missing(_xmltvIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('icon_url')) {
      context.handle(
        _iconUrlMeta,
        iconUrl.isAcceptableOrUnknown(data['icon_url']!, _iconUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EpgChannel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EpgChannel(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}playlist_id'],
      )!,
      xmltvId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}xmltv_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      iconUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_url'],
      ),
    );
  }

  @override
  $EpgChannelsTable createAlias(String alias) {
    return $EpgChannelsTable(attachedDatabase, alias);
  }
}

class EpgChannel extends DataClass implements Insertable<EpgChannel> {
  final int id;
  final int playlistId;
  final String xmltvId;
  final String? displayName;
  final String? iconUrl;
  const EpgChannel({
    required this.id,
    required this.playlistId,
    required this.xmltvId,
    this.displayName,
    this.iconUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['playlist_id'] = Variable<int>(playlistId);
    map['xmltv_id'] = Variable<String>(xmltvId);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    if (!nullToAbsent || iconUrl != null) {
      map['icon_url'] = Variable<String>(iconUrl);
    }
    return map;
  }

  EpgChannelsCompanion toCompanion(bool nullToAbsent) {
    return EpgChannelsCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      xmltvId: Value(xmltvId),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      iconUrl: iconUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(iconUrl),
    );
  }

  factory EpgChannel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EpgChannel(
      id: serializer.fromJson<int>(json['id']),
      playlistId: serializer.fromJson<int>(json['playlistId']),
      xmltvId: serializer.fromJson<String>(json['xmltvId']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      iconUrl: serializer.fromJson<String?>(json['iconUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playlistId': serializer.toJson<int>(playlistId),
      'xmltvId': serializer.toJson<String>(xmltvId),
      'displayName': serializer.toJson<String?>(displayName),
      'iconUrl': serializer.toJson<String?>(iconUrl),
    };
  }

  EpgChannel copyWith({
    int? id,
    int? playlistId,
    String? xmltvId,
    Value<String?> displayName = const Value.absent(),
    Value<String?> iconUrl = const Value.absent(),
  }) => EpgChannel(
    id: id ?? this.id,
    playlistId: playlistId ?? this.playlistId,
    xmltvId: xmltvId ?? this.xmltvId,
    displayName: displayName.present ? displayName.value : this.displayName,
    iconUrl: iconUrl.present ? iconUrl.value : this.iconUrl,
  );
  EpgChannel copyWithCompanion(EpgChannelsCompanion data) {
    return EpgChannel(
      id: data.id.present ? data.id.value : this.id,
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      xmltvId: data.xmltvId.present ? data.xmltvId.value : this.xmltvId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      iconUrl: data.iconUrl.present ? data.iconUrl.value : this.iconUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EpgChannel(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('xmltvId: $xmltvId, ')
          ..write('displayName: $displayName, ')
          ..write('iconUrl: $iconUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, playlistId, xmltvId, displayName, iconUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EpgChannel &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.xmltvId == this.xmltvId &&
          other.displayName == this.displayName &&
          other.iconUrl == this.iconUrl);
}

class EpgChannelsCompanion extends UpdateCompanion<EpgChannel> {
  final Value<int> id;
  final Value<int> playlistId;
  final Value<String> xmltvId;
  final Value<String?> displayName;
  final Value<String?> iconUrl;
  const EpgChannelsCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.xmltvId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.iconUrl = const Value.absent(),
  });
  EpgChannelsCompanion.insert({
    this.id = const Value.absent(),
    required int playlistId,
    required String xmltvId,
    this.displayName = const Value.absent(),
    this.iconUrl = const Value.absent(),
  }) : playlistId = Value(playlistId),
       xmltvId = Value(xmltvId);
  static Insertable<EpgChannel> custom({
    Expression<int>? id,
    Expression<int>? playlistId,
    Expression<String>? xmltvId,
    Expression<String>? displayName,
    Expression<String>? iconUrl,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (xmltvId != null) 'xmltv_id': xmltvId,
      if (displayName != null) 'display_name': displayName,
      if (iconUrl != null) 'icon_url': iconUrl,
    });
  }

  EpgChannelsCompanion copyWith({
    Value<int>? id,
    Value<int>? playlistId,
    Value<String>? xmltvId,
    Value<String?>? displayName,
    Value<String?>? iconUrl,
  }) {
    return EpgChannelsCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      xmltvId: xmltvId ?? this.xmltvId,
      displayName: displayName ?? this.displayName,
      iconUrl: iconUrl ?? this.iconUrl,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<int>(playlistId.value);
    }
    if (xmltvId.present) {
      map['xmltv_id'] = Variable<String>(xmltvId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (iconUrl.present) {
      map['icon_url'] = Variable<String>(iconUrl.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpgChannelsCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('xmltvId: $xmltvId, ')
          ..write('displayName: $displayName, ')
          ..write('iconUrl: $iconUrl')
          ..write(')'))
        .toString();
  }
}

class $ProgrammesTable extends Programmes
    with TableInfo<$ProgrammesTable, Programme> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgrammesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _epgChannelIdMeta = const VerificationMeta(
    'epgChannelId',
  );
  @override
  late final GeneratedColumn<int> epgChannelId = GeneratedColumn<int>(
    'epg_channel_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES epg_channels (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _startUtcMeta = const VerificationMeta(
    'startUtc',
  );
  @override
  late final GeneratedColumn<DateTime> startUtc = GeneratedColumn<DateTime>(
    'start_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stopUtcMeta = const VerificationMeta(
    'stopUtc',
  );
  @override
  late final GeneratedColumn<DateTime> stopUtc = GeneratedColumn<DateTime>(
    'stop_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    epgChannelId,
    startUtc,
    stopUtc,
    title,
    description,
    category,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'programmes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Programme> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('epg_channel_id')) {
      context.handle(
        _epgChannelIdMeta,
        epgChannelId.isAcceptableOrUnknown(
          data['epg_channel_id']!,
          _epgChannelIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_epgChannelIdMeta);
    }
    if (data.containsKey('start_utc')) {
      context.handle(
        _startUtcMeta,
        startUtc.isAcceptableOrUnknown(data['start_utc']!, _startUtcMeta),
      );
    } else if (isInserting) {
      context.missing(_startUtcMeta);
    }
    if (data.containsKey('stop_utc')) {
      context.handle(
        _stopUtcMeta,
        stopUtc.isAcceptableOrUnknown(data['stop_utc']!, _stopUtcMeta),
      );
    } else if (isInserting) {
      context.missing(_stopUtcMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Programme map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Programme(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      epgChannelId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}epg_channel_id'],
      )!,
      startUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_utc'],
      )!,
      stopUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}stop_utc'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
    );
  }

  @override
  $ProgrammesTable createAlias(String alias) {
    return $ProgrammesTable(attachedDatabase, alias);
  }
}

class Programme extends DataClass implements Insertable<Programme> {
  final int id;
  final int epgChannelId;
  final DateTime startUtc;
  final DateTime stopUtc;
  final String title;
  final String? description;
  final String? category;
  const Programme({
    required this.id,
    required this.epgChannelId,
    required this.startUtc,
    required this.stopUtc,
    required this.title,
    this.description,
    this.category,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['epg_channel_id'] = Variable<int>(epgChannelId);
    map['start_utc'] = Variable<DateTime>(startUtc);
    map['stop_utc'] = Variable<DateTime>(stopUtc);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    return map;
  }

  ProgrammesCompanion toCompanion(bool nullToAbsent) {
    return ProgrammesCompanion(
      id: Value(id),
      epgChannelId: Value(epgChannelId),
      startUtc: Value(startUtc),
      stopUtc: Value(stopUtc),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
    );
  }

  factory Programme.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Programme(
      id: serializer.fromJson<int>(json['id']),
      epgChannelId: serializer.fromJson<int>(json['epgChannelId']),
      startUtc: serializer.fromJson<DateTime>(json['startUtc']),
      stopUtc: serializer.fromJson<DateTime>(json['stopUtc']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      category: serializer.fromJson<String?>(json['category']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'epgChannelId': serializer.toJson<int>(epgChannelId),
      'startUtc': serializer.toJson<DateTime>(startUtc),
      'stopUtc': serializer.toJson<DateTime>(stopUtc),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'category': serializer.toJson<String?>(category),
    };
  }

  Programme copyWith({
    int? id,
    int? epgChannelId,
    DateTime? startUtc,
    DateTime? stopUtc,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<String?> category = const Value.absent(),
  }) => Programme(
    id: id ?? this.id,
    epgChannelId: epgChannelId ?? this.epgChannelId,
    startUtc: startUtc ?? this.startUtc,
    stopUtc: stopUtc ?? this.stopUtc,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    category: category.present ? category.value : this.category,
  );
  Programme copyWithCompanion(ProgrammesCompanion data) {
    return Programme(
      id: data.id.present ? data.id.value : this.id,
      epgChannelId: data.epgChannelId.present
          ? data.epgChannelId.value
          : this.epgChannelId,
      startUtc: data.startUtc.present ? data.startUtc.value : this.startUtc,
      stopUtc: data.stopUtc.present ? data.stopUtc.value : this.stopUtc,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      category: data.category.present ? data.category.value : this.category,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Programme(')
          ..write('id: $id, ')
          ..write('epgChannelId: $epgChannelId, ')
          ..write('startUtc: $startUtc, ')
          ..write('stopUtc: $stopUtc, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    epgChannelId,
    startUtc,
    stopUtc,
    title,
    description,
    category,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Programme &&
          other.id == this.id &&
          other.epgChannelId == this.epgChannelId &&
          other.startUtc == this.startUtc &&
          other.stopUtc == this.stopUtc &&
          other.title == this.title &&
          other.description == this.description &&
          other.category == this.category);
}

class ProgrammesCompanion extends UpdateCompanion<Programme> {
  final Value<int> id;
  final Value<int> epgChannelId;
  final Value<DateTime> startUtc;
  final Value<DateTime> stopUtc;
  final Value<String> title;
  final Value<String?> description;
  final Value<String?> category;
  const ProgrammesCompanion({
    this.id = const Value.absent(),
    this.epgChannelId = const Value.absent(),
    this.startUtc = const Value.absent(),
    this.stopUtc = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
  });
  ProgrammesCompanion.insert({
    this.id = const Value.absent(),
    required int epgChannelId,
    required DateTime startUtc,
    required DateTime stopUtc,
    required String title,
    this.description = const Value.absent(),
    this.category = const Value.absent(),
  }) : epgChannelId = Value(epgChannelId),
       startUtc = Value(startUtc),
       stopUtc = Value(stopUtc),
       title = Value(title);
  static Insertable<Programme> custom({
    Expression<int>? id,
    Expression<int>? epgChannelId,
    Expression<DateTime>? startUtc,
    Expression<DateTime>? stopUtc,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? category,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (epgChannelId != null) 'epg_channel_id': epgChannelId,
      if (startUtc != null) 'start_utc': startUtc,
      if (stopUtc != null) 'stop_utc': stopUtc,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
    });
  }

  ProgrammesCompanion copyWith({
    Value<int>? id,
    Value<int>? epgChannelId,
    Value<DateTime>? startUtc,
    Value<DateTime>? stopUtc,
    Value<String>? title,
    Value<String?>? description,
    Value<String?>? category,
  }) {
    return ProgrammesCompanion(
      id: id ?? this.id,
      epgChannelId: epgChannelId ?? this.epgChannelId,
      startUtc: startUtc ?? this.startUtc,
      stopUtc: stopUtc ?? this.stopUtc,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (epgChannelId.present) {
      map['epg_channel_id'] = Variable<int>(epgChannelId.value);
    }
    if (startUtc.present) {
      map['start_utc'] = Variable<DateTime>(startUtc.value);
    }
    if (stopUtc.present) {
      map['stop_utc'] = Variable<DateTime>(stopUtc.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgrammesCompanion(')
          ..write('id: $id, ')
          ..write('epgChannelId: $epgChannelId, ')
          ..write('startUtc: $startUtc, ')
          ..write('stopUtc: $stopUtc, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }
}

class $FavoritesTable extends Favorites
    with TableInfo<$FavoritesTable, Favorite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<int> channelId = GeneratedColumn<int>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES channels (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
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
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [channelId, addedAt, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<Favorite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {channelId};
  @override
  Favorite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Favorite(
      channelId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}channel_id'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $FavoritesTable createAlias(String alias) {
    return $FavoritesTable(attachedDatabase, alias);
  }
}

class Favorite extends DataClass implements Insertable<Favorite> {
  final int channelId;
  final DateTime addedAt;
  final int sortOrder;
  const Favorite({
    required this.channelId,
    required this.addedAt,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['channel_id'] = Variable<int>(channelId);
    map['added_at'] = Variable<DateTime>(addedAt);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(
      channelId: Value(channelId),
      addedAt: Value(addedAt),
      sortOrder: Value(sortOrder),
    );
  }

  factory Favorite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Favorite(
      channelId: serializer.fromJson<int>(json['channelId']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'channelId': serializer.toJson<int>(channelId),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Favorite copyWith({int? channelId, DateTime? addedAt, int? sortOrder}) =>
      Favorite(
        channelId: channelId ?? this.channelId,
        addedAt: addedAt ?? this.addedAt,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  Favorite copyWithCompanion(FavoritesCompanion data) {
    return Favorite(
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Favorite(')
          ..write('channelId: $channelId, ')
          ..write('addedAt: $addedAt, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(channelId, addedAt, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Favorite &&
          other.channelId == this.channelId &&
          other.addedAt == this.addedAt &&
          other.sortOrder == this.sortOrder);
}

class FavoritesCompanion extends UpdateCompanion<Favorite> {
  final Value<int> channelId;
  final Value<DateTime> addedAt;
  final Value<int> sortOrder;
  const FavoritesCompanion({
    this.channelId = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  FavoritesCompanion.insert({
    this.channelId = const Value.absent(),
    required DateTime addedAt,
    this.sortOrder = const Value.absent(),
  }) : addedAt = Value(addedAt);
  static Insertable<Favorite> custom({
    Expression<int>? channelId,
    Expression<DateTime>? addedAt,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (channelId != null) 'channel_id': channelId,
      if (addedAt != null) 'added_at': addedAt,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  FavoritesCompanion copyWith({
    Value<int>? channelId,
    Value<DateTime>? addedAt,
    Value<int>? sortOrder,
  }) {
    return FavoritesCompanion(
      channelId: channelId ?? this.channelId,
      addedAt: addedAt ?? this.addedAt,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (channelId.present) {
      map['channel_id'] = Variable<int>(channelId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesCompanion(')
          ..write('channelId: $channelId, ')
          ..write('addedAt: $addedAt, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $WatchHistoryTable extends WatchHistory
    with TableInfo<$WatchHistoryTable, WatchHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WatchHistoryTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<int> channelId = GeneratedColumn<int>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES channels (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _watchedAtMeta = const VerificationMeta(
    'watchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> watchedAt = GeneratedColumn<DateTime>(
    'watched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMsMeta = const VerificationMeta(
    'positionMs',
  );
  @override
  late final GeneratedColumn<int> positionMs = GeneratedColumn<int>(
    'position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, channelId, watchedAt, positionMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'watch_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<WatchHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('watched_at')) {
      context.handle(
        _watchedAtMeta,
        watchedAt.isAcceptableOrUnknown(data['watched_at']!, _watchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_watchedAtMeta);
    }
    if (data.containsKey('position_ms')) {
      context.handle(
        _positionMsMeta,
        positionMs.isAcceptableOrUnknown(data['position_ms']!, _positionMsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WatchHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WatchHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      channelId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}channel_id'],
      )!,
      watchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}watched_at'],
      )!,
      positionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_ms'],
      )!,
    );
  }

  @override
  $WatchHistoryTable createAlias(String alias) {
    return $WatchHistoryTable(attachedDatabase, alias);
  }
}

class WatchHistoryData extends DataClass
    implements Insertable<WatchHistoryData> {
  final int id;
  final int channelId;
  final DateTime watchedAt;
  final int positionMs;
  const WatchHistoryData({
    required this.id,
    required this.channelId,
    required this.watchedAt,
    required this.positionMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['channel_id'] = Variable<int>(channelId);
    map['watched_at'] = Variable<DateTime>(watchedAt);
    map['position_ms'] = Variable<int>(positionMs);
    return map;
  }

  WatchHistoryCompanion toCompanion(bool nullToAbsent) {
    return WatchHistoryCompanion(
      id: Value(id),
      channelId: Value(channelId),
      watchedAt: Value(watchedAt),
      positionMs: Value(positionMs),
    );
  }

  factory WatchHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WatchHistoryData(
      id: serializer.fromJson<int>(json['id']),
      channelId: serializer.fromJson<int>(json['channelId']),
      watchedAt: serializer.fromJson<DateTime>(json['watchedAt']),
      positionMs: serializer.fromJson<int>(json['positionMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'channelId': serializer.toJson<int>(channelId),
      'watchedAt': serializer.toJson<DateTime>(watchedAt),
      'positionMs': serializer.toJson<int>(positionMs),
    };
  }

  WatchHistoryData copyWith({
    int? id,
    int? channelId,
    DateTime? watchedAt,
    int? positionMs,
  }) => WatchHistoryData(
    id: id ?? this.id,
    channelId: channelId ?? this.channelId,
    watchedAt: watchedAt ?? this.watchedAt,
    positionMs: positionMs ?? this.positionMs,
  );
  WatchHistoryData copyWithCompanion(WatchHistoryCompanion data) {
    return WatchHistoryData(
      id: data.id.present ? data.id.value : this.id,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      watchedAt: data.watchedAt.present ? data.watchedAt.value : this.watchedAt,
      positionMs: data.positionMs.present
          ? data.positionMs.value
          : this.positionMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WatchHistoryData(')
          ..write('id: $id, ')
          ..write('channelId: $channelId, ')
          ..write('watchedAt: $watchedAt, ')
          ..write('positionMs: $positionMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, channelId, watchedAt, positionMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WatchHistoryData &&
          other.id == this.id &&
          other.channelId == this.channelId &&
          other.watchedAt == this.watchedAt &&
          other.positionMs == this.positionMs);
}

class WatchHistoryCompanion extends UpdateCompanion<WatchHistoryData> {
  final Value<int> id;
  final Value<int> channelId;
  final Value<DateTime> watchedAt;
  final Value<int> positionMs;
  const WatchHistoryCompanion({
    this.id = const Value.absent(),
    this.channelId = const Value.absent(),
    this.watchedAt = const Value.absent(),
    this.positionMs = const Value.absent(),
  });
  WatchHistoryCompanion.insert({
    this.id = const Value.absent(),
    required int channelId,
    required DateTime watchedAt,
    this.positionMs = const Value.absent(),
  }) : channelId = Value(channelId),
       watchedAt = Value(watchedAt);
  static Insertable<WatchHistoryData> custom({
    Expression<int>? id,
    Expression<int>? channelId,
    Expression<DateTime>? watchedAt,
    Expression<int>? positionMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (channelId != null) 'channel_id': channelId,
      if (watchedAt != null) 'watched_at': watchedAt,
      if (positionMs != null) 'position_ms': positionMs,
    });
  }

  WatchHistoryCompanion copyWith({
    Value<int>? id,
    Value<int>? channelId,
    Value<DateTime>? watchedAt,
    Value<int>? positionMs,
  }) {
    return WatchHistoryCompanion(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      watchedAt: watchedAt ?? this.watchedAt,
      positionMs: positionMs ?? this.positionMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<int>(channelId.value);
    }
    if (watchedAt.present) {
      map['watched_at'] = Variable<DateTime>(watchedAt.value);
    }
    if (positionMs.present) {
      map['position_ms'] = Variable<int>(positionMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WatchHistoryCompanion(')
          ..write('id: $id, ')
          ..write('channelId: $channelId, ')
          ..write('watchedAt: $watchedAt, ')
          ..write('positionMs: $positionMs')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PlaylistsTable playlists = $PlaylistsTable(this);
  late final $GroupsTable groups = $GroupsTable(this);
  late final $ChannelsTable channels = $ChannelsTable(this);
  late final $EpgChannelsTable epgChannels = $EpgChannelsTable(this);
  late final $ProgrammesTable programmes = $ProgrammesTable(this);
  late final $FavoritesTable favorites = $FavoritesTable(this);
  late final $WatchHistoryTable watchHistory = $WatchHistoryTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final Index idxGroupsPlaylist = Index(
    'idx_groups_playlist',
    'CREATE INDEX idx_groups_playlist ON "groups" (playlist_id, sort_order)',
  );
  late final Index idxChannelsPlaylistGroup = Index(
    'idx_channels_playlist_group',
    'CREATE INDEX idx_channels_playlist_group ON channels (playlist_id, group_id, sort_order)',
  );
  late final Index idxChannelsPlaylistKind = Index(
    'idx_channels_playlist_kind',
    'CREATE INDEX idx_channels_playlist_kind ON channels (playlist_id, kind, sort_order)',
  );
  late final Index idxChannelsTvg = Index(
    'idx_channels_tvg',
    'CREATE INDEX idx_channels_tvg ON channels (tvg_id)',
  );
  late final Index idxEpgchanPlaylistXmltv = Index(
    'idx_epgchan_playlist_xmltv',
    'CREATE INDEX idx_epgchan_playlist_xmltv ON epg_channels (playlist_id, xmltv_id)',
  );
  late final Index idxProgrammesChanStart = Index(
    'idx_programmes_chan_start',
    'CREATE INDEX idx_programmes_chan_start ON programmes (epg_channel_id, start_utc)',
  );
  late final Index idxProgrammesStop = Index(
    'idx_programmes_stop',
    'CREATE INDEX idx_programmes_stop ON programmes (stop_utc)',
  );
  late final Index idxHistoryWatched = Index(
    'idx_history_watched',
    'CREATE INDEX idx_history_watched ON watch_history (watched_at)',
  );
  late final ChannelsDao channelsDao = ChannelsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    playlists,
    groups,
    channels,
    epgChannels,
    programmes,
    favorites,
    watchHistory,
    settings,
    idxGroupsPlaylist,
    idxChannelsPlaylistGroup,
    idxChannelsPlaylistKind,
    idxChannelsTvg,
    idxEpgchanPlaylistXmltv,
    idxProgrammesChanStart,
    idxProgrammesStop,
    idxHistoryWatched,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('groups', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('channels', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'groups',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('channels', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('epg_channels', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'epg_channels',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('programmes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'channels',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('favorites', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'channels',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('watch_history', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$PlaylistsTableCreateCompanionBuilder = PlaylistsCompanion Function({
  Value<int> id,
  required String name,
  required PlaylistType type,
  Value<String?> url,
  Value<String?> host,
  Value<int?> port,
  Value<String?> username,
  Value<String?> userAgent,
  Value<String?> epgUrl,
  Value<DateTime?> lastSyncAt,
  Value<int> channelCount,
  Value<bool> isActive,
});
typedef $$PlaylistsTableUpdateCompanionBuilder = PlaylistsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<PlaylistType> type,
  Value<String?> url,
  Value<String?> host,
  Value<int?> port,
  Value<String?> username,
  Value<String?> userAgent,
  Value<String?> epgUrl,
  Value<DateTime?> lastSyncAt,
  Value<int> channelCount,
  Value<bool> isActive,
});

final class $$PlaylistsTableReferences
    extends BaseReferences<_$AppDatabase, $PlaylistsTable, Playlist> {
  $$PlaylistsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$GroupsTable, List<Group>> _groupsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.groups,
    aliasName: 'playlists__id__groups__playlist_id',
  );

  $$GroupsTableProcessedTableManager get groupsRefs {
    final manager = $$GroupsTableTableManager(
      $_db,
      $_db.groups,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_groupsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ChannelsTable, List<Channel>> _channelsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.channels,
    aliasName: 'playlists__id__channels__playlist_id',
  );

  $$ChannelsTableProcessedTableManager get channelsRefs {
    final manager = $$ChannelsTableTableManager(
      $_db,
      $_db.channels,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_channelsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EpgChannelsTable, List<EpgChannel>>
  _epgChannelsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.epgChannels,
    aliasName: 'playlists__id__epg_channels__playlist_id',
  );

  $$EpgChannelsTableProcessedTableManager get epgChannelsRefs {
    final manager = $$EpgChannelsTableTableManager(
      $_db,
      $_db.epgChannels,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_epgChannelsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlaylistsTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PlaylistType, PlaylistType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userAgent => $composableBuilder(
    column: $table.userAgent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get epgUrl => $composableBuilder(
    column: $table.epgUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get channelCount => $composableBuilder(
    column: $table.channelCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> groupsRefs(
    Expression<bool> Function($$GroupsTableFilterComposer f) f,
  ) {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableFilterComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> channelsRefs(
    Expression<bool> Function($$ChannelsTableFilterComposer f) f,
  ) {
    final $$ChannelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableFilterComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> epgChannelsRefs(
    Expression<bool> Function($$EpgChannelsTableFilterComposer f) f,
  ) {
    final $$EpgChannelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.epgChannels,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpgChannelsTableFilterComposer(
            $db: $db,
            $table: $db.epgChannels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userAgent => $composableBuilder(
    column: $table.userAgent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get epgUrl => $composableBuilder(
    column: $table.epgUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get channelCount => $composableBuilder(
    column: $table.channelCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaylistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PlaylistType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get host =>
      $composableBuilder(column: $table.host, builder: (column) => column);

  GeneratedColumn<int> get port =>
      $composableBuilder(column: $table.port, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get userAgent =>
      $composableBuilder(column: $table.userAgent, builder: (column) => column);

  GeneratedColumn<String> get epgUrl =>
      $composableBuilder(column: $table.epgUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get channelCount => $composableBuilder(
    column: $table.channelCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  Expression<T> groupsRefs<T extends Object>(
    Expression<T> Function($$GroupsTableAnnotationComposer a) f,
  ) {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> channelsRefs<T extends Object>(
    Expression<T> Function($$ChannelsTableAnnotationComposer a) f,
  ) {
    final $$ChannelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableAnnotationComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> epgChannelsRefs<T extends Object>(
    Expression<T> Function($$EpgChannelsTableAnnotationComposer a) f,
  ) {
    final $$EpgChannelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.epgChannels,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpgChannelsTableAnnotationComposer(
            $db: $db,
            $table: $db.epgChannels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaylistsTable,
          Playlist,
          $$PlaylistsTableFilterComposer,
          $$PlaylistsTableOrderingComposer,
          $$PlaylistsTableAnnotationComposer,
          $$PlaylistsTableCreateCompanionBuilder,
          $$PlaylistsTableUpdateCompanionBuilder,
          (Playlist, $$PlaylistsTableReferences),
          Playlist,
          PrefetchHooks Function({
            bool groupsRefs,
            bool channelsRefs,
            bool epgChannelsRefs,
          })
        > {
  $$PlaylistsTableTableManager(_$AppDatabase db, $PlaylistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<PlaylistType> type = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> host = const Value.absent(),
                Value<int?> port = const Value.absent(),
                Value<String?> username = const Value.absent(),
                Value<String?> userAgent = const Value.absent(),
                Value<String?> epgUrl = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<int> channelCount = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => PlaylistsCompanion(
                id: id,
                name: name,
                type: type,
                url: url,
                host: host,
                port: port,
                username: username,
                userAgent: userAgent,
                epgUrl: epgUrl,
                lastSyncAt: lastSyncAt,
                channelCount: channelCount,
                isActive: isActive,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required PlaylistType type,
                Value<String?> url = const Value.absent(),
                Value<String?> host = const Value.absent(),
                Value<int?> port = const Value.absent(),
                Value<String?> username = const Value.absent(),
                Value<String?> userAgent = const Value.absent(),
                Value<String?> epgUrl = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<int> channelCount = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => PlaylistsCompanion.insert(
                id: id,
                name: name,
                type: type,
                url: url,
                host: host,
                port: port,
                username: username,
                userAgent: userAgent,
                epgUrl: epgUrl,
                lastSyncAt: lastSyncAt,
                channelCount: channelCount,
                isActive: isActive,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaylistsTable, Playlist>(table),
                  $$PlaylistsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                groupsRefs = false,
                channelsRefs = false,
                epgChannelsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (groupsRefs) db.groups,
                    if (channelsRefs) db.channels,
                    if (epgChannelsRefs) db.epgChannels,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (groupsRefs)
                        await $_getPrefetchedData<
                          Playlist,
                          $PlaylistsTable,
                          Group
                        >(
                          currentTable: table,
                          referencedTable: $$PlaylistsTableReferences
                              ._groupsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlaylistsTableReferences(
                                db,
                                table,
                                p0,
                              ).groupsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playlistId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (channelsRefs)
                        await $_getPrefetchedData<
                          Playlist,
                          $PlaylistsTable,
                          Channel
                        >(
                          currentTable: table,
                          referencedTable: $$PlaylistsTableReferences
                              ._channelsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlaylistsTableReferences(
                                db,
                                table,
                                p0,
                              ).channelsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playlistId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (epgChannelsRefs)
                        await $_getPrefetchedData<
                          Playlist,
                          $PlaylistsTable,
                          EpgChannel
                        >(
                          currentTable: table,
                          referencedTable: $$PlaylistsTableReferences
                              ._epgChannelsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlaylistsTableReferences(
                                db,
                                table,
                                p0,
                              ).epgChannelsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playlistId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PlaylistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaylistsTable,
      Playlist,
      $$PlaylistsTableFilterComposer,
      $$PlaylistsTableOrderingComposer,
      $$PlaylistsTableAnnotationComposer,
      $$PlaylistsTableCreateCompanionBuilder,
      $$PlaylistsTableUpdateCompanionBuilder,
      (Playlist, $$PlaylistsTableReferences),
      Playlist,
      PrefetchHooks Function({
        bool groupsRefs,
        bool channelsRefs,
        bool epgChannelsRefs,
      })
    >;
typedef $$GroupsTableCreateCompanionBuilder = GroupsCompanion Function({
  Value<int> id,
  required int playlistId,
  required String name,
  Value<int> sortOrder,
  Value<int> channelCount,
});
typedef $$GroupsTableUpdateCompanionBuilder = GroupsCompanion Function({
  Value<int> id,
  Value<int> playlistId,
  Value<String> name,
  Value<int> sortOrder,
  Value<int> channelCount,
});

final class $$GroupsTableReferences
    extends BaseReferences<_$AppDatabase, $GroupsTable, Group> {
  $$GroupsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlaylistsTable _playlistIdTable(_$AppDatabase db) =>
      db.playlists.createAlias('groups__playlist_id__playlists__id');

  $$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<int>('playlist_id')!;

    final manager = $$PlaylistsTableTableManager(
      $_db,
      $_db.playlists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ChannelsTable, List<Channel>> _channelsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.channels,
    aliasName: 'groups__id__channels__group_id',
  );

  $$ChannelsTableProcessedTableManager get channelsRefs {
    final manager = $$ChannelsTableTableManager(
      $_db,
      $_db.channels,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_channelsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GroupsTableFilterComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get channelCount => $composableBuilder(
    column: $table.channelCount,
    builder: (column) => ColumnFilters(column),
  );

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> channelsRefs(
    Expression<bool> Function($$ChannelsTableFilterComposer f) f,
  ) {
    final $$ChannelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableFilterComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get channelCount => $composableBuilder(
    column: $table.channelCount,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get channelCount => $composableBuilder(
    column: $table.channelCount,
    builder: (column) => column,
  );

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> channelsRefs<T extends Object>(
    Expression<T> Function($$ChannelsTableAnnotationComposer a) f,
  ) {
    final $$ChannelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableAnnotationComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroupsTable,
          Group,
          $$GroupsTableFilterComposer,
          $$GroupsTableOrderingComposer,
          $$GroupsTableAnnotationComposer,
          $$GroupsTableCreateCompanionBuilder,
          $$GroupsTableUpdateCompanionBuilder,
          (Group, $$GroupsTableReferences),
          Group,
          PrefetchHooks Function({bool playlistId, bool channelsRefs})
        > {
  $$GroupsTableTableManager(_$AppDatabase db, $GroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> playlistId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> channelCount = const Value.absent(),
              }) => GroupsCompanion(
                id: id,
                playlistId: playlistId,
                name: name,
                sortOrder: sortOrder,
                channelCount: channelCount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int playlistId,
                required String name,
                Value<int> sortOrder = const Value.absent(),
                Value<int> channelCount = const Value.absent(),
              }) => GroupsCompanion.insert(
                id: id,
                playlistId: playlistId,
                name: name,
                sortOrder: sortOrder,
                channelCount: channelCount,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GroupsTable, Group>(table),
                  $$GroupsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistId = false, channelsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (channelsRefs) db.channels],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (playlistId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.playlistId,
                        referencedTable: $$GroupsTableReferences
                            ._playlistIdTable(db),
                        referencedColumn: $$GroupsTableReferences
                            ._playlistIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (channelsRefs)
                    await $_getPrefetchedData<Group, $GroupsTable, Channel>(
                      currentTable: table,
                      referencedTable: $$GroupsTableReferences
                          ._channelsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$GroupsTableReferences(db, table, p0).channelsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.groupId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$GroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroupsTable,
      Group,
      $$GroupsTableFilterComposer,
      $$GroupsTableOrderingComposer,
      $$GroupsTableAnnotationComposer,
      $$GroupsTableCreateCompanionBuilder,
      $$GroupsTableUpdateCompanionBuilder,
      (Group, $$GroupsTableReferences),
      Group,
      PrefetchHooks Function({bool playlistId, bool channelsRefs})
    >;
typedef $$ChannelsTableCreateCompanionBuilder = ChannelsCompanion Function({
  Value<int> id,
  required int playlistId,
  Value<int?> groupId,
  required String name,
  required String url,
  Value<String?> logoUrl,
  Value<String?> tvgId,
  Value<String?> tvgName,
  Value<int?> streamId,
  Value<String?> containerExt,
  Value<ChannelKind> kind,
  Value<bool> tvArchive,
  Value<String?> httpUserAgent,
  Value<String?> httpReferrer,
  Value<int> sortOrder,
});
typedef $$ChannelsTableUpdateCompanionBuilder = ChannelsCompanion Function({
  Value<int> id,
  Value<int> playlistId,
  Value<int?> groupId,
  Value<String> name,
  Value<String> url,
  Value<String?> logoUrl,
  Value<String?> tvgId,
  Value<String?> tvgName,
  Value<int?> streamId,
  Value<String?> containerExt,
  Value<ChannelKind> kind,
  Value<bool> tvArchive,
  Value<String?> httpUserAgent,
  Value<String?> httpReferrer,
  Value<int> sortOrder,
});

final class $$ChannelsTableReferences
    extends BaseReferences<_$AppDatabase, $ChannelsTable, Channel> {
  $$ChannelsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlaylistsTable _playlistIdTable(_$AppDatabase db) =>
      db.playlists.createAlias('channels__playlist_id__playlists__id');

  $$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<int>('playlist_id')!;

    final manager = $$PlaylistsTableTableManager(
      $_db,
      $_db.playlists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $GroupsTable _groupIdTable(_$AppDatabase db) =>
      db.groups.createAlias('channels__group_id__groups__id');

  $$GroupsTableProcessedTableManager? get groupId {
    final $_column = $_itemColumn<int>('group_id');
    if ($_column == null) return null;
    final manager = $$GroupsTableTableManager(
      $_db,
      $_db.groups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$FavoritesTable, List<Favorite>>
  _favoritesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.favorites,
    aliasName: 'channels__id__favorites__channel_id',
  );

  $$FavoritesTableProcessedTableManager get favoritesRefs {
    final manager = $$FavoritesTableTableManager(
      $_db,
      $_db.favorites,
    ).filter((f) => f.channelId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_favoritesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WatchHistoryTable, List<WatchHistoryData>>
  _watchHistoryRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.watchHistory,
    aliasName: 'channels__id__watch_history__channel_id',
  );

  $$WatchHistoryTableProcessedTableManager get watchHistoryRefs {
    final manager = $$WatchHistoryTableTableManager(
      $_db,
      $_db.watchHistory,
    ).filter((f) => f.channelId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_watchHistoryRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChannelsTableFilterComposer
    extends Composer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logoUrl => $composableBuilder(
    column: $table.logoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tvgId => $composableBuilder(
    column: $table.tvgId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tvgName => $composableBuilder(
    column: $table.tvgName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get streamId => $composableBuilder(
    column: $table.streamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get containerExt => $composableBuilder(
    column: $table.containerExt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ChannelKind, ChannelKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get tvArchive => $composableBuilder(
    column: $table.tvArchive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get httpUserAgent => $composableBuilder(
    column: $table.httpUserAgent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get httpReferrer => $composableBuilder(
    column: $table.httpReferrer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GroupsTableFilterComposer get groupId {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableFilterComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> favoritesRefs(
    Expression<bool> Function($$FavoritesTableFilterComposer f) f,
  ) {
    final $$FavoritesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.favorites,
      getReferencedColumn: (t) => t.channelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoritesTableFilterComposer(
            $db: $db,
            $table: $db.favorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> watchHistoryRefs(
    Expression<bool> Function($$WatchHistoryTableFilterComposer f) f,
  ) {
    final $$WatchHistoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.watchHistory,
      getReferencedColumn: (t) => t.channelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WatchHistoryTableFilterComposer(
            $db: $db,
            $table: $db.watchHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChannelsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logoUrl => $composableBuilder(
    column: $table.logoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tvgId => $composableBuilder(
    column: $table.tvgId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tvgName => $composableBuilder(
    column: $table.tvgName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get streamId => $composableBuilder(
    column: $table.streamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get containerExt => $composableBuilder(
    column: $table.containerExt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get tvArchive => $composableBuilder(
    column: $table.tvArchive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get httpUserAgent => $composableBuilder(
    column: $table.httpUserAgent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get httpReferrer => $composableBuilder(
    column: $table.httpReferrer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GroupsTableOrderingComposer get groupId {
    final $$GroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableOrderingComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChannelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get logoUrl =>
      $composableBuilder(column: $table.logoUrl, builder: (column) => column);

  GeneratedColumn<String> get tvgId =>
      $composableBuilder(column: $table.tvgId, builder: (column) => column);

  GeneratedColumn<String> get tvgName =>
      $composableBuilder(column: $table.tvgName, builder: (column) => column);

  GeneratedColumn<int> get streamId =>
      $composableBuilder(column: $table.streamId, builder: (column) => column);

  GeneratedColumn<String> get containerExt => $composableBuilder(
    column: $table.containerExt,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ChannelKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<bool> get tvArchive =>
      $composableBuilder(column: $table.tvArchive, builder: (column) => column);

  GeneratedColumn<String> get httpUserAgent => $composableBuilder(
    column: $table.httpUserAgent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get httpReferrer => $composableBuilder(
    column: $table.httpReferrer,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GroupsTableAnnotationComposer get groupId {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> favoritesRefs<T extends Object>(
    Expression<T> Function($$FavoritesTableAnnotationComposer a) f,
  ) {
    final $$FavoritesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.favorites,
      getReferencedColumn: (t) => t.channelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoritesTableAnnotationComposer(
            $db: $db,
            $table: $db.favorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> watchHistoryRefs<T extends Object>(
    Expression<T> Function($$WatchHistoryTableAnnotationComposer a) f,
  ) {
    final $$WatchHistoryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.watchHistory,
      getReferencedColumn: (t) => t.channelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WatchHistoryTableAnnotationComposer(
            $db: $db,
            $table: $db.watchHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChannelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChannelsTable,
          Channel,
          $$ChannelsTableFilterComposer,
          $$ChannelsTableOrderingComposer,
          $$ChannelsTableAnnotationComposer,
          $$ChannelsTableCreateCompanionBuilder,
          $$ChannelsTableUpdateCompanionBuilder,
          (Channel, $$ChannelsTableReferences),
          Channel,
          PrefetchHooks Function({
            bool playlistId,
            bool groupId,
            bool favoritesRefs,
            bool watchHistoryRefs,
          })
        > {
  $$ChannelsTableTableManager(_$AppDatabase db, $ChannelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChannelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChannelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChannelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> playlistId = const Value.absent(),
                Value<int?> groupId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String?> logoUrl = const Value.absent(),
                Value<String?> tvgId = const Value.absent(),
                Value<String?> tvgName = const Value.absent(),
                Value<int?> streamId = const Value.absent(),
                Value<String?> containerExt = const Value.absent(),
                Value<ChannelKind> kind = const Value.absent(),
                Value<bool> tvArchive = const Value.absent(),
                Value<String?> httpUserAgent = const Value.absent(),
                Value<String?> httpReferrer = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => ChannelsCompanion(
                id: id,
                playlistId: playlistId,
                groupId: groupId,
                name: name,
                url: url,
                logoUrl: logoUrl,
                tvgId: tvgId,
                tvgName: tvgName,
                streamId: streamId,
                containerExt: containerExt,
                kind: kind,
                tvArchive: tvArchive,
                httpUserAgent: httpUserAgent,
                httpReferrer: httpReferrer,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int playlistId,
                Value<int?> groupId = const Value.absent(),
                required String name,
                required String url,
                Value<String?> logoUrl = const Value.absent(),
                Value<String?> tvgId = const Value.absent(),
                Value<String?> tvgName = const Value.absent(),
                Value<int?> streamId = const Value.absent(),
                Value<String?> containerExt = const Value.absent(),
                Value<ChannelKind> kind = const Value.absent(),
                Value<bool> tvArchive = const Value.absent(),
                Value<String?> httpUserAgent = const Value.absent(),
                Value<String?> httpReferrer = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => ChannelsCompanion.insert(
                id: id,
                playlistId: playlistId,
                groupId: groupId,
                name: name,
                url: url,
                logoUrl: logoUrl,
                tvgId: tvgId,
                tvgName: tvgName,
                streamId: streamId,
                containerExt: containerExt,
                kind: kind,
                tvArchive: tvArchive,
                httpUserAgent: httpUserAgent,
                httpReferrer: httpReferrer,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChannelsTable, Channel>(table),
                  $$ChannelsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                playlistId = false,
                groupId = false,
                favoritesRefs = false,
                watchHistoryRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (favoritesRefs) db.favorites,
                    if (watchHistoryRefs) db.watchHistory,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (playlistId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.playlistId,
                            referencedTable: $$ChannelsTableReferences
                                ._playlistIdTable(db),
                            referencedColumn: $$ChannelsTableReferences
                                ._playlistIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (groupId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.groupId,
                            referencedTable: $$ChannelsTableReferences
                                ._groupIdTable(db),
                            referencedColumn: $$ChannelsTableReferences
                                ._groupIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (favoritesRefs)
                        await $_getPrefetchedData<
                          Channel,
                          $ChannelsTable,
                          Favorite
                        >(
                          currentTable: table,
                          referencedTable: $$ChannelsTableReferences
                              ._favoritesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChannelsTableReferences(
                                db,
                                table,
                                p0,
                              ).favoritesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.channelId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (watchHistoryRefs)
                        await $_getPrefetchedData<
                          Channel,
                          $ChannelsTable,
                          WatchHistoryData
                        >(
                          currentTable: table,
                          referencedTable: $$ChannelsTableReferences
                              ._watchHistoryRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChannelsTableReferences(
                                db,
                                table,
                                p0,
                              ).watchHistoryRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.channelId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ChannelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChannelsTable,
      Channel,
      $$ChannelsTableFilterComposer,
      $$ChannelsTableOrderingComposer,
      $$ChannelsTableAnnotationComposer,
      $$ChannelsTableCreateCompanionBuilder,
      $$ChannelsTableUpdateCompanionBuilder,
      (Channel, $$ChannelsTableReferences),
      Channel,
      PrefetchHooks Function({
        bool playlistId,
        bool groupId,
        bool favoritesRefs,
        bool watchHistoryRefs,
      })
    >;
typedef $$EpgChannelsTableCreateCompanionBuilder =
    EpgChannelsCompanion Function({
      Value<int> id,
      required int playlistId,
      required String xmltvId,
      Value<String?> displayName,
      Value<String?> iconUrl,
    });
typedef $$EpgChannelsTableUpdateCompanionBuilder =
    EpgChannelsCompanion Function({
      Value<int> id,
      Value<int> playlistId,
      Value<String> xmltvId,
      Value<String?> displayName,
      Value<String?> iconUrl,
    });

final class $$EpgChannelsTableReferences
    extends BaseReferences<_$AppDatabase, $EpgChannelsTable, EpgChannel> {
  $$EpgChannelsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlaylistsTable _playlistIdTable(_$AppDatabase db) =>
      db.playlists.createAlias('epg_channels__playlist_id__playlists__id');

  $$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<int>('playlist_id')!;

    final manager = $$PlaylistsTableTableManager(
      $_db,
      $_db.playlists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ProgrammesTable, List<Programme>>
  _programmesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.programmes,
    aliasName: 'epg_channels__id__programmes__epg_channel_id',
  );

  $$ProgrammesTableProcessedTableManager get programmesRefs {
    final manager = $$ProgrammesTableTableManager(
      $_db,
      $_db.programmes,
    ).filter((f) => f.epgChannelId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_programmesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EpgChannelsTableFilterComposer
    extends Composer<_$AppDatabase, $EpgChannelsTable> {
  $$EpgChannelsTableFilterComposer({
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

  ColumnFilters<String> get xmltvId => $composableBuilder(
    column: $table.xmltvId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconUrl => $composableBuilder(
    column: $table.iconUrl,
    builder: (column) => ColumnFilters(column),
  );

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> programmesRefs(
    Expression<bool> Function($$ProgrammesTableFilterComposer f) f,
  ) {
    final $$ProgrammesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.programmes,
      getReferencedColumn: (t) => t.epgChannelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgrammesTableFilterComposer(
            $db: $db,
            $table: $db.programmes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EpgChannelsTableOrderingComposer
    extends Composer<_$AppDatabase, $EpgChannelsTable> {
  $$EpgChannelsTableOrderingComposer({
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

  ColumnOrderings<String> get xmltvId => $composableBuilder(
    column: $table.xmltvId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconUrl => $composableBuilder(
    column: $table.iconUrl,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpgChannelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EpgChannelsTable> {
  $$EpgChannelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get xmltvId =>
      $composableBuilder(column: $table.xmltvId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get iconUrl =>
      $composableBuilder(column: $table.iconUrl, builder: (column) => column);

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> programmesRefs<T extends Object>(
    Expression<T> Function($$ProgrammesTableAnnotationComposer a) f,
  ) {
    final $$ProgrammesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.programmes,
      getReferencedColumn: (t) => t.epgChannelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgrammesTableAnnotationComposer(
            $db: $db,
            $table: $db.programmes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EpgChannelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EpgChannelsTable,
          EpgChannel,
          $$EpgChannelsTableFilterComposer,
          $$EpgChannelsTableOrderingComposer,
          $$EpgChannelsTableAnnotationComposer,
          $$EpgChannelsTableCreateCompanionBuilder,
          $$EpgChannelsTableUpdateCompanionBuilder,
          (EpgChannel, $$EpgChannelsTableReferences),
          EpgChannel,
          PrefetchHooks Function({bool playlistId, bool programmesRefs})
        > {
  $$EpgChannelsTableTableManager(_$AppDatabase db, $EpgChannelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpgChannelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpgChannelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EpgChannelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> playlistId = const Value.absent(),
                Value<String> xmltvId = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<String?> iconUrl = const Value.absent(),
              }) => EpgChannelsCompanion(
                id: id,
                playlistId: playlistId,
                xmltvId: xmltvId,
                displayName: displayName,
                iconUrl: iconUrl,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int playlistId,
                required String xmltvId,
                Value<String?> displayName = const Value.absent(),
                Value<String?> iconUrl = const Value.absent(),
              }) => EpgChannelsCompanion.insert(
                id: id,
                playlistId: playlistId,
                xmltvId: xmltvId,
                displayName: displayName,
                iconUrl: iconUrl,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EpgChannelsTable, EpgChannel>(table),
                  $$EpgChannelsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({playlistId = false, programmesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (programmesRefs) db.programmes],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (playlistId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.playlistId,
                            referencedTable: $$EpgChannelsTableReferences
                                ._playlistIdTable(db),
                            referencedColumn: $$EpgChannelsTableReferences
                                ._playlistIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (programmesRefs)
                        await $_getPrefetchedData<
                          EpgChannel,
                          $EpgChannelsTable,
                          Programme
                        >(
                          currentTable: table,
                          referencedTable: $$EpgChannelsTableReferences
                              ._programmesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EpgChannelsTableReferences(
                                db,
                                table,
                                p0,
                              ).programmesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.epgChannelId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$EpgChannelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EpgChannelsTable,
      EpgChannel,
      $$EpgChannelsTableFilterComposer,
      $$EpgChannelsTableOrderingComposer,
      $$EpgChannelsTableAnnotationComposer,
      $$EpgChannelsTableCreateCompanionBuilder,
      $$EpgChannelsTableUpdateCompanionBuilder,
      (EpgChannel, $$EpgChannelsTableReferences),
      EpgChannel,
      PrefetchHooks Function({bool playlistId, bool programmesRefs})
    >;
typedef $$ProgrammesTableCreateCompanionBuilder = ProgrammesCompanion Function({
  Value<int> id,
  required int epgChannelId,
  required DateTime startUtc,
  required DateTime stopUtc,
  required String title,
  Value<String?> description,
  Value<String?> category,
});
typedef $$ProgrammesTableUpdateCompanionBuilder = ProgrammesCompanion Function({
  Value<int> id,
  Value<int> epgChannelId,
  Value<DateTime> startUtc,
  Value<DateTime> stopUtc,
  Value<String> title,
  Value<String?> description,
  Value<String?> category,
});

final class $$ProgrammesTableReferences
    extends BaseReferences<_$AppDatabase, $ProgrammesTable, Programme> {
  $$ProgrammesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EpgChannelsTable _epgChannelIdTable(_$AppDatabase db) => db
      .epgChannels
      .createAlias('programmes__epg_channel_id__epg_channels__id');

  $$EpgChannelsTableProcessedTableManager get epgChannelId {
    final $_column = $_itemColumn<int>('epg_channel_id')!;

    final manager = $$EpgChannelsTableTableManager(
      $_db,
      $_db.epgChannels,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_epgChannelIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProgrammesTableFilterComposer
    extends Composer<_$AppDatabase, $ProgrammesTable> {
  $$ProgrammesTableFilterComposer({
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

  ColumnFilters<DateTime> get startUtc => $composableBuilder(
    column: $table.startUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get stopUtc => $composableBuilder(
    column: $table.stopUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  $$EpgChannelsTableFilterComposer get epgChannelId {
    final $$EpgChannelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.epgChannelId,
      referencedTable: $db.epgChannels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpgChannelsTableFilterComposer(
            $db: $db,
            $table: $db.epgChannels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProgrammesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProgrammesTable> {
  $$ProgrammesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get startUtc => $composableBuilder(
    column: $table.startUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get stopUtc => $composableBuilder(
    column: $table.stopUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  $$EpgChannelsTableOrderingComposer get epgChannelId {
    final $$EpgChannelsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.epgChannelId,
      referencedTable: $db.epgChannels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpgChannelsTableOrderingComposer(
            $db: $db,
            $table: $db.epgChannels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProgrammesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProgrammesTable> {
  $$ProgrammesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startUtc =>
      $composableBuilder(column: $table.startUtc, builder: (column) => column);

  GeneratedColumn<DateTime> get stopUtc =>
      $composableBuilder(column: $table.stopUtc, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  $$EpgChannelsTableAnnotationComposer get epgChannelId {
    final $$EpgChannelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.epgChannelId,
      referencedTable: $db.epgChannels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpgChannelsTableAnnotationComposer(
            $db: $db,
            $table: $db.epgChannels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProgrammesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProgrammesTable,
          Programme,
          $$ProgrammesTableFilterComposer,
          $$ProgrammesTableOrderingComposer,
          $$ProgrammesTableAnnotationComposer,
          $$ProgrammesTableCreateCompanionBuilder,
          $$ProgrammesTableUpdateCompanionBuilder,
          (Programme, $$ProgrammesTableReferences),
          Programme,
          PrefetchHooks Function({bool epgChannelId})
        > {
  $$ProgrammesTableTableManager(_$AppDatabase db, $ProgrammesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgrammesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgrammesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgrammesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> epgChannelId = const Value.absent(),
                Value<DateTime> startUtc = const Value.absent(),
                Value<DateTime> stopUtc = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> category = const Value.absent(),
              }) => ProgrammesCompanion(
                id: id,
                epgChannelId: epgChannelId,
                startUtc: startUtc,
                stopUtc: stopUtc,
                title: title,
                description: description,
                category: category,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int epgChannelId,
                required DateTime startUtc,
                required DateTime stopUtc,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String?> category = const Value.absent(),
              }) => ProgrammesCompanion.insert(
                id: id,
                epgChannelId: epgChannelId,
                startUtc: startUtc,
                stopUtc: stopUtc,
                title: title,
                description: description,
                category: category,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProgrammesTable, Programme>(table),
                  $$ProgrammesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({epgChannelId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (epgChannelId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.epgChannelId,
                        referencedTable: $$ProgrammesTableReferences
                            ._epgChannelIdTable(db),
                        referencedColumn: $$ProgrammesTableReferences
                            ._epgChannelIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProgrammesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProgrammesTable,
      Programme,
      $$ProgrammesTableFilterComposer,
      $$ProgrammesTableOrderingComposer,
      $$ProgrammesTableAnnotationComposer,
      $$ProgrammesTableCreateCompanionBuilder,
      $$ProgrammesTableUpdateCompanionBuilder,
      (Programme, $$ProgrammesTableReferences),
      Programme,
      PrefetchHooks Function({bool epgChannelId})
    >;
typedef $$FavoritesTableCreateCompanionBuilder = FavoritesCompanion Function({
  Value<int> channelId,
  required DateTime addedAt,
  Value<int> sortOrder,
});
typedef $$FavoritesTableUpdateCompanionBuilder = FavoritesCompanion Function({
  Value<int> channelId,
  Value<DateTime> addedAt,
  Value<int> sortOrder,
});

final class $$FavoritesTableReferences
    extends BaseReferences<_$AppDatabase, $FavoritesTable, Favorite> {
  $$FavoritesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChannelsTable _channelIdTable(_$AppDatabase db) =>
      db.channels.createAlias('favorites__channel_id__channels__id');

  $$ChannelsTableProcessedTableManager get channelId {
    final $_column = $_itemColumn<int>('channel_id')!;

    final manager = $$ChannelsTableTableManager(
      $_db,
      $_db.channels,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_channelIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FavoritesTableFilterComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$ChannelsTableFilterComposer get channelId {
    final $$ChannelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.channelId,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableFilterComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoritesTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChannelsTableOrderingComposer get channelId {
    final $$ChannelsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.channelId,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableOrderingComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$ChannelsTableAnnotationComposer get channelId {
    final $$ChannelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.channelId,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableAnnotationComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoritesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoritesTable,
          Favorite,
          $$FavoritesTableFilterComposer,
          $$FavoritesTableOrderingComposer,
          $$FavoritesTableAnnotationComposer,
          $$FavoritesTableCreateCompanionBuilder,
          $$FavoritesTableUpdateCompanionBuilder,
          (Favorite, $$FavoritesTableReferences),
          Favorite,
          PrefetchHooks Function({bool channelId})
        > {
  $$FavoritesTableTableManager(_$AppDatabase db, $FavoritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> channelId = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => FavoritesCompanion(
                channelId: channelId,
                addedAt: addedAt,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> channelId = const Value.absent(),
                required DateTime addedAt,
                Value<int> sortOrder = const Value.absent(),
              }) => FavoritesCompanion.insert(
                channelId: channelId,
                addedAt: addedAt,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FavoritesTable, Favorite>(table),
                  $$FavoritesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({channelId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (channelId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.channelId,
                        referencedTable: $$FavoritesTableReferences
                            ._channelIdTable(db),
                        referencedColumn: $$FavoritesTableReferences
                            ._channelIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FavoritesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoritesTable,
      Favorite,
      $$FavoritesTableFilterComposer,
      $$FavoritesTableOrderingComposer,
      $$FavoritesTableAnnotationComposer,
      $$FavoritesTableCreateCompanionBuilder,
      $$FavoritesTableUpdateCompanionBuilder,
      (Favorite, $$FavoritesTableReferences),
      Favorite,
      PrefetchHooks Function({bool channelId})
    >;
typedef $$WatchHistoryTableCreateCompanionBuilder =
    WatchHistoryCompanion Function({
      Value<int> id,
      required int channelId,
      required DateTime watchedAt,
      Value<int> positionMs,
    });
typedef $$WatchHistoryTableUpdateCompanionBuilder =
    WatchHistoryCompanion Function({
      Value<int> id,
      Value<int> channelId,
      Value<DateTime> watchedAt,
      Value<int> positionMs,
    });

final class $$WatchHistoryTableReferences
    extends
        BaseReferences<_$AppDatabase, $WatchHistoryTable, WatchHistoryData> {
  $$WatchHistoryTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChannelsTable _channelIdTable(_$AppDatabase db) =>
      db.channels.createAlias('watch_history__channel_id__channels__id');

  $$ChannelsTableProcessedTableManager get channelId {
    final $_column = $_itemColumn<int>('channel_id')!;

    final manager = $$ChannelsTableTableManager(
      $_db,
      $_db.channels,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_channelIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WatchHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $WatchHistoryTable> {
  $$WatchHistoryTableFilterComposer({
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

  ColumnFilters<DateTime> get watchedAt => $composableBuilder(
    column: $table.watchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnFilters(column),
  );

  $$ChannelsTableFilterComposer get channelId {
    final $$ChannelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.channelId,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableFilterComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WatchHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $WatchHistoryTable> {
  $$WatchHistoryTableOrderingComposer({
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

  ColumnOrderings<DateTime> get watchedAt => $composableBuilder(
    column: $table.watchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChannelsTableOrderingComposer get channelId {
    final $$ChannelsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.channelId,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableOrderingComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WatchHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $WatchHistoryTable> {
  $$WatchHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get watchedAt =>
      $composableBuilder(column: $table.watchedAt, builder: (column) => column);

  GeneratedColumn<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => column,
  );

  $$ChannelsTableAnnotationComposer get channelId {
    final $$ChannelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.channelId,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableAnnotationComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WatchHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WatchHistoryTable,
          WatchHistoryData,
          $$WatchHistoryTableFilterComposer,
          $$WatchHistoryTableOrderingComposer,
          $$WatchHistoryTableAnnotationComposer,
          $$WatchHistoryTableCreateCompanionBuilder,
          $$WatchHistoryTableUpdateCompanionBuilder,
          (WatchHistoryData, $$WatchHistoryTableReferences),
          WatchHistoryData,
          PrefetchHooks Function({bool channelId})
        > {
  $$WatchHistoryTableTableManager(_$AppDatabase db, $WatchHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WatchHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WatchHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WatchHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> channelId = const Value.absent(),
                Value<DateTime> watchedAt = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
              }) => WatchHistoryCompanion(
                id: id,
                channelId: channelId,
                watchedAt: watchedAt,
                positionMs: positionMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int channelId,
                required DateTime watchedAt,
                Value<int> positionMs = const Value.absent(),
              }) => WatchHistoryCompanion.insert(
                id: id,
                channelId: channelId,
                watchedAt: watchedAt,
                positionMs: positionMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WatchHistoryTable, WatchHistoryData>(table),
                  $$WatchHistoryTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({channelId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (channelId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.channelId,
                        referencedTable: $$WatchHistoryTableReferences
                            ._channelIdTable(db),
                        referencedColumn: $$WatchHistoryTableReferences
                            ._channelIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WatchHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WatchHistoryTable,
      WatchHistoryData,
      $$WatchHistoryTableFilterComposer,
      $$WatchHistoryTableOrderingComposer,
      $$WatchHistoryTableAnnotationComposer,
      $$WatchHistoryTableCreateCompanionBuilder,
      $$WatchHistoryTableUpdateCompanionBuilder,
      (WatchHistoryData, $$WatchHistoryTableReferences),
      WatchHistoryData,
      PrefetchHooks Function({bool channelId})
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PlaylistsTableTableManager get playlists =>
      $$PlaylistsTableTableManager(_db, _db.playlists);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db, _db.groups);
  $$ChannelsTableTableManager get channels =>
      $$ChannelsTableTableManager(_db, _db.channels);
  $$EpgChannelsTableTableManager get epgChannels =>
      $$EpgChannelsTableTableManager(_db, _db.epgChannels);
  $$ProgrammesTableTableManager get programmes =>
      $$ProgrammesTableTableManager(_db, _db.programmes);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db, _db.favorites);
  $$WatchHistoryTableTableManager get watchHistory =>
      $$WatchHistoryTableTableManager(_db, _db.watchHistory);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
