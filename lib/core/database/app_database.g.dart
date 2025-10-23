// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, UserEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneNumberMeta = const VerificationMeta(
    'phoneNumber',
  );
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
    'phone_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fcmTokenMeta = const VerificationMeta(
    'fcmToken',
  );
  @override
  late final GeneratedColumn<String> fcmToken = GeneratedColumn<String>(
    'fcm_token',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _preferredLanguageMeta = const VerificationMeta(
    'preferredLanguage',
  );
  @override
  late final GeneratedColumn<String> preferredLanguage =
      GeneratedColumn<String>(
        'preferred_language',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('en'),
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSeenMeta = const VerificationMeta(
    'lastSeen',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeen = GeneratedColumn<DateTime>(
    'last_seen',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isOnlineMeta = const VerificationMeta(
    'isOnline',
  );
  @override
  late final GeneratedColumn<bool> isOnline = GeneratedColumn<bool>(
    'is_online',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_online" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    uid,
    email,
    phoneNumber,
    name,
    imageUrl,
    fcmToken,
    preferredLanguage,
    createdAt,
    lastSeen,
    isOnline,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('phone_number')) {
      context.handle(
        _phoneNumberMeta,
        phoneNumber.isAcceptableOrUnknown(
          data['phone_number']!,
          _phoneNumberMeta,
        ),
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
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('fcm_token')) {
      context.handle(
        _fcmTokenMeta,
        fcmToken.isAcceptableOrUnknown(data['fcm_token']!, _fcmTokenMeta),
      );
    }
    if (data.containsKey('preferred_language')) {
      context.handle(
        _preferredLanguageMeta,
        preferredLanguage.isAcceptableOrUnknown(
          data['preferred_language']!,
          _preferredLanguageMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_seen')) {
      context.handle(
        _lastSeenMeta,
        lastSeen.isAcceptableOrUnknown(data['last_seen']!, _lastSeenMeta),
      );
    } else if (isInserting) {
      context.missing(_lastSeenMeta);
    }
    if (data.containsKey('is_online')) {
      context.handle(
        _isOnlineMeta,
        isOnline.isAcceptableOrUnknown(data['is_online']!, _isOnlineMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  UserEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserEntity(
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      phoneNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone_number'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      fcmToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fcm_token'],
      ),
      preferredLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_language'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen'],
      )!,
      isOnline: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_online'],
      )!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class UserEntity extends DataClass implements Insertable<UserEntity> {
  /// Unique user ID (matches Firebase Auth UID)
  final String uid;

  /// User's email address
  final String? email;

  /// User's phone number
  final String? phoneNumber;

  /// Display name
  final String name;

  /// Profile image URL
  final String? imageUrl;

  /// FCM token for push notifications
  final String? fcmToken;

  /// Preferred language code (e.g., 'en', 'es')
  final String preferredLanguage;

  /// Account creation timestamp
  final DateTime createdAt;

  /// Last seen timestamp
  final DateTime lastSeen;

  /// Online status indicator
  final bool isOnline;
  const UserEntity({
    required this.uid,
    this.email,
    this.phoneNumber,
    required this.name,
    this.imageUrl,
    this.fcmToken,
    required this.preferredLanguage,
    required this.createdAt,
    required this.lastSeen,
    required this.isOnline,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || phoneNumber != null) {
      map['phone_number'] = Variable<String>(phoneNumber);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || fcmToken != null) {
      map['fcm_token'] = Variable<String>(fcmToken);
    }
    map['preferred_language'] = Variable<String>(preferredLanguage);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_seen'] = Variable<DateTime>(lastSeen);
    map['is_online'] = Variable<bool>(isOnline);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      uid: Value(uid),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      phoneNumber: phoneNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneNumber),
      name: Value(name),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      fcmToken: fcmToken == null && nullToAbsent
          ? const Value.absent()
          : Value(fcmToken),
      preferredLanguage: Value(preferredLanguage),
      createdAt: Value(createdAt),
      lastSeen: Value(lastSeen),
      isOnline: Value(isOnline),
    );
  }

  factory UserEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserEntity(
      uid: serializer.fromJson<String>(json['uid']),
      email: serializer.fromJson<String?>(json['email']),
      phoneNumber: serializer.fromJson<String?>(json['phoneNumber']),
      name: serializer.fromJson<String>(json['name']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      fcmToken: serializer.fromJson<String?>(json['fcmToken']),
      preferredLanguage: serializer.fromJson<String>(json['preferredLanguage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastSeen: serializer.fromJson<DateTime>(json['lastSeen']),
      isOnline: serializer.fromJson<bool>(json['isOnline']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'email': serializer.toJson<String?>(email),
      'phoneNumber': serializer.toJson<String?>(phoneNumber),
      'name': serializer.toJson<String>(name),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'fcmToken': serializer.toJson<String?>(fcmToken),
      'preferredLanguage': serializer.toJson<String>(preferredLanguage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastSeen': serializer.toJson<DateTime>(lastSeen),
      'isOnline': serializer.toJson<bool>(isOnline),
    };
  }

  UserEntity copyWith({
    String? uid,
    Value<String?> email = const Value.absent(),
    Value<String?> phoneNumber = const Value.absent(),
    String? name,
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> fcmToken = const Value.absent(),
    String? preferredLanguage,
    DateTime? createdAt,
    DateTime? lastSeen,
    bool? isOnline,
  }) => UserEntity(
    uid: uid ?? this.uid,
    email: email.present ? email.value : this.email,
    phoneNumber: phoneNumber.present ? phoneNumber.value : this.phoneNumber,
    name: name ?? this.name,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    fcmToken: fcmToken.present ? fcmToken.value : this.fcmToken,
    preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    createdAt: createdAt ?? this.createdAt,
    lastSeen: lastSeen ?? this.lastSeen,
    isOnline: isOnline ?? this.isOnline,
  );
  UserEntity copyWithCompanion(UsersCompanion data) {
    return UserEntity(
      uid: data.uid.present ? data.uid.value : this.uid,
      email: data.email.present ? data.email.value : this.email,
      phoneNumber: data.phoneNumber.present
          ? data.phoneNumber.value
          : this.phoneNumber,
      name: data.name.present ? data.name.value : this.name,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      fcmToken: data.fcmToken.present ? data.fcmToken.value : this.fcmToken,
      preferredLanguage: data.preferredLanguage.present
          ? data.preferredLanguage.value
          : this.preferredLanguage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastSeen: data.lastSeen.present ? data.lastSeen.value : this.lastSeen,
      isOnline: data.isOnline.present ? data.isOnline.value : this.isOnline,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserEntity(')
          ..write('uid: $uid, ')
          ..write('email: $email, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('name: $name, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('fcmToken: $fcmToken, ')
          ..write('preferredLanguage: $preferredLanguage, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('isOnline: $isOnline')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uid,
    email,
    phoneNumber,
    name,
    imageUrl,
    fcmToken,
    preferredLanguage,
    createdAt,
    lastSeen,
    isOnline,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserEntity &&
          other.uid == this.uid &&
          other.email == this.email &&
          other.phoneNumber == this.phoneNumber &&
          other.name == this.name &&
          other.imageUrl == this.imageUrl &&
          other.fcmToken == this.fcmToken &&
          other.preferredLanguage == this.preferredLanguage &&
          other.createdAt == this.createdAt &&
          other.lastSeen == this.lastSeen &&
          other.isOnline == this.isOnline);
}

class UsersCompanion extends UpdateCompanion<UserEntity> {
  final Value<String> uid;
  final Value<String?> email;
  final Value<String?> phoneNumber;
  final Value<String> name;
  final Value<String?> imageUrl;
  final Value<String?> fcmToken;
  final Value<String> preferredLanguage;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastSeen;
  final Value<bool> isOnline;
  final Value<int> rowid;
  const UsersCompanion({
    this.uid = const Value.absent(),
    this.email = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.name = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.fcmToken = const Value.absent(),
    this.preferredLanguage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastSeen = const Value.absent(),
    this.isOnline = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String uid,
    this.email = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    required String name,
    this.imageUrl = const Value.absent(),
    this.fcmToken = const Value.absent(),
    this.preferredLanguage = const Value.absent(),
    required DateTime createdAt,
    required DateTime lastSeen,
    this.isOnline = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uid = Value(uid),
       name = Value(name),
       createdAt = Value(createdAt),
       lastSeen = Value(lastSeen);
  static Insertable<UserEntity> custom({
    Expression<String>? uid,
    Expression<String>? email,
    Expression<String>? phoneNumber,
    Expression<String>? name,
    Expression<String>? imageUrl,
    Expression<String>? fcmToken,
    Expression<String>? preferredLanguage,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastSeen,
    Expression<bool>? isOnline,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (email != null) 'email': email,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (name != null) 'name': name,
      if (imageUrl != null) 'image_url': imageUrl,
      if (fcmToken != null) 'fcm_token': fcmToken,
      if (preferredLanguage != null) 'preferred_language': preferredLanguage,
      if (createdAt != null) 'created_at': createdAt,
      if (lastSeen != null) 'last_seen': lastSeen,
      if (isOnline != null) 'is_online': isOnline,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith({
    Value<String>? uid,
    Value<String?>? email,
    Value<String?>? phoneNumber,
    Value<String>? name,
    Value<String?>? imageUrl,
    Value<String?>? fcmToken,
    Value<String>? preferredLanguage,
    Value<DateTime>? createdAt,
    Value<DateTime>? lastSeen,
    Value<bool>? isOnline,
    Value<int>? rowid,
  }) {
    return UsersCompanion(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (fcmToken.present) {
      map['fcm_token'] = Variable<String>(fcmToken.value);
    }
    if (preferredLanguage.present) {
      map['preferred_language'] = Variable<String>(preferredLanguage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastSeen.present) {
      map['last_seen'] = Variable<DateTime>(lastSeen.value);
    }
    if (isOnline.present) {
      map['is_online'] = Variable<bool>(isOnline.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('uid: $uid, ')
          ..write('email: $email, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('name: $name, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('fcmToken: $fcmToken, ')
          ..write('preferredLanguage: $preferredLanguage, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('isOnline: $isOnline, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConversationsTable extends Conversations
    with TableInfo<$ConversationsTable, ConversationEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conversationTypeMeta = const VerificationMeta(
    'conversationType',
  );
  @override
  late final GeneratedColumn<String> conversationType = GeneratedColumn<String>(
    'conversation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupNameMeta = const VerificationMeta(
    'groupName',
  );
  @override
  late final GeneratedColumn<String> groupName = GeneratedColumn<String>(
    'group_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupImageMeta = const VerificationMeta(
    'groupImage',
  );
  @override
  late final GeneratedColumn<String> groupImage = GeneratedColumn<String>(
    'group_image',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _participantIdsMeta = const VerificationMeta(
    'participantIds',
  );
  @override
  late final GeneratedColumn<String> participantIds = GeneratedColumn<String>(
    'participant_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _participantsMeta = const VerificationMeta(
    'participants',
  );
  @override
  late final GeneratedColumn<String> participants = GeneratedColumn<String>(
    'participants',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _adminIdsMeta = const VerificationMeta(
    'adminIds',
  );
  @override
  late final GeneratedColumn<String> adminIds = GeneratedColumn<String>(
    'admin_ids',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessageTextMeta = const VerificationMeta(
    'lastMessageText',
  );
  @override
  late final GeneratedColumn<String> lastMessageText = GeneratedColumn<String>(
    'last_message_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessageSenderIdMeta =
      const VerificationMeta('lastMessageSenderId');
  @override
  late final GeneratedColumn<String> lastMessageSenderId =
      GeneratedColumn<String>(
        'last_message_sender_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastMessageSenderNameMeta =
      const VerificationMeta('lastMessageSenderName');
  @override
  late final GeneratedColumn<String> lastMessageSenderName =
      GeneratedColumn<String>(
        'last_message_sender_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastMessageTimestampMeta =
      const VerificationMeta('lastMessageTimestamp');
  @override
  late final GeneratedColumn<DateTime> lastMessageTimestamp =
      GeneratedColumn<DateTime>(
        'last_message_timestamp',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastMessageTypeMeta = const VerificationMeta(
    'lastMessageType',
  );
  @override
  late final GeneratedColumn<String> lastMessageType = GeneratedColumn<String>(
    'last_message_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessageTranslationsMeta =
      const VerificationMeta('lastMessageTranslations');
  @override
  late final GeneratedColumn<String> lastMessageTranslations =
      GeneratedColumn<String>(
        'last_message_translations',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastUpdatedAtMeta = const VerificationMeta(
    'lastUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUpdatedAt =
      GeneratedColumn<DateTime>(
        'last_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _initiatedAtMeta = const VerificationMeta(
    'initiatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> initiatedAt = GeneratedColumn<DateTime>(
    'initiated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unreadCountMeta = const VerificationMeta(
    'unreadCount',
  );
  @override
  late final GeneratedColumn<String> unreadCount = GeneratedColumn<String>(
    'unread_count',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _translationEnabledMeta =
      const VerificationMeta('translationEnabled');
  @override
  late final GeneratedColumn<bool> translationEnabled = GeneratedColumn<bool>(
    'translation_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("translation_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _autoDetectLanguageMeta =
      const VerificationMeta('autoDetectLanguage');
  @override
  late final GeneratedColumn<bool> autoDetectLanguage = GeneratedColumn<bool>(
    'auto_detect_language',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_detect_language" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    documentId,
    conversationType,
    groupName,
    groupImage,
    participantIds,
    participants,
    adminIds,
    lastMessageText,
    lastMessageSenderId,
    lastMessageSenderName,
    lastMessageTimestamp,
    lastMessageType,
    lastMessageTranslations,
    lastUpdatedAt,
    initiatedAt,
    unreadCount,
    translationEnabled,
    autoDetectLanguage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversations';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConversationEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('conversation_type')) {
      context.handle(
        _conversationTypeMeta,
        conversationType.isAcceptableOrUnknown(
          data['conversation_type']!,
          _conversationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationTypeMeta);
    }
    if (data.containsKey('group_name')) {
      context.handle(
        _groupNameMeta,
        groupName.isAcceptableOrUnknown(data['group_name']!, _groupNameMeta),
      );
    }
    if (data.containsKey('group_image')) {
      context.handle(
        _groupImageMeta,
        groupImage.isAcceptableOrUnknown(data['group_image']!, _groupImageMeta),
      );
    }
    if (data.containsKey('participant_ids')) {
      context.handle(
        _participantIdsMeta,
        participantIds.isAcceptableOrUnknown(
          data['participant_ids']!,
          _participantIdsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_participantIdsMeta);
    }
    if (data.containsKey('participants')) {
      context.handle(
        _participantsMeta,
        participants.isAcceptableOrUnknown(
          data['participants']!,
          _participantsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_participantsMeta);
    }
    if (data.containsKey('admin_ids')) {
      context.handle(
        _adminIdsMeta,
        adminIds.isAcceptableOrUnknown(data['admin_ids']!, _adminIdsMeta),
      );
    }
    if (data.containsKey('last_message_text')) {
      context.handle(
        _lastMessageTextMeta,
        lastMessageText.isAcceptableOrUnknown(
          data['last_message_text']!,
          _lastMessageTextMeta,
        ),
      );
    }
    if (data.containsKey('last_message_sender_id')) {
      context.handle(
        _lastMessageSenderIdMeta,
        lastMessageSenderId.isAcceptableOrUnknown(
          data['last_message_sender_id']!,
          _lastMessageSenderIdMeta,
        ),
      );
    }
    if (data.containsKey('last_message_sender_name')) {
      context.handle(
        _lastMessageSenderNameMeta,
        lastMessageSenderName.isAcceptableOrUnknown(
          data['last_message_sender_name']!,
          _lastMessageSenderNameMeta,
        ),
      );
    }
    if (data.containsKey('last_message_timestamp')) {
      context.handle(
        _lastMessageTimestampMeta,
        lastMessageTimestamp.isAcceptableOrUnknown(
          data['last_message_timestamp']!,
          _lastMessageTimestampMeta,
        ),
      );
    }
    if (data.containsKey('last_message_type')) {
      context.handle(
        _lastMessageTypeMeta,
        lastMessageType.isAcceptableOrUnknown(
          data['last_message_type']!,
          _lastMessageTypeMeta,
        ),
      );
    }
    if (data.containsKey('last_message_translations')) {
      context.handle(
        _lastMessageTranslationsMeta,
        lastMessageTranslations.isAcceptableOrUnknown(
          data['last_message_translations']!,
          _lastMessageTranslationsMeta,
        ),
      );
    }
    if (data.containsKey('last_updated_at')) {
      context.handle(
        _lastUpdatedAtMeta,
        lastUpdatedAt.isAcceptableOrUnknown(
          data['last_updated_at']!,
          _lastUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUpdatedAtMeta);
    }
    if (data.containsKey('initiated_at')) {
      context.handle(
        _initiatedAtMeta,
        initiatedAt.isAcceptableOrUnknown(
          data['initiated_at']!,
          _initiatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_initiatedAtMeta);
    }
    if (data.containsKey('unread_count')) {
      context.handle(
        _unreadCountMeta,
        unreadCount.isAcceptableOrUnknown(
          data['unread_count']!,
          _unreadCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unreadCountMeta);
    }
    if (data.containsKey('translation_enabled')) {
      context.handle(
        _translationEnabledMeta,
        translationEnabled.isAcceptableOrUnknown(
          data['translation_enabled']!,
          _translationEnabledMeta,
        ),
      );
    }
    if (data.containsKey('auto_detect_language')) {
      context.handle(
        _autoDetectLanguageMeta,
        autoDetectLanguage.isAcceptableOrUnknown(
          data['auto_detect_language']!,
          _autoDetectLanguageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documentId};
  @override
  ConversationEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConversationEntity(
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      conversationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_type'],
      )!,
      groupName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_name'],
      ),
      groupImage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_image'],
      ),
      participantIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}participant_ids'],
      )!,
      participants: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}participants'],
      )!,
      adminIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}admin_ids'],
      ),
      lastMessageText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_text'],
      ),
      lastMessageSenderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_sender_id'],
      ),
      lastMessageSenderName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_sender_name'],
      ),
      lastMessageTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_message_timestamp'],
      ),
      lastMessageType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_type'],
      ),
      lastMessageTranslations: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_translations'],
      ),
      lastUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_updated_at'],
      )!,
      initiatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}initiated_at'],
      )!,
      unreadCount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unread_count'],
      )!,
      translationEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}translation_enabled'],
      )!,
      autoDetectLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_detect_language'],
      )!,
    );
  }

  @override
  $ConversationsTable createAlias(String alias) {
    return $ConversationsTable(attachedDatabase, alias);
  }
}

class ConversationEntity extends DataClass
    implements Insertable<ConversationEntity> {
  /// Unique conversation ID (matches Firestore document ID)
  final String documentId;

  /// Conversation type: 'direct' or 'group'
  final String conversationType;

  /// Group name (null for direct conversations)
  final String? groupName;

  /// Group image URL (null for direct conversations)
  final String? groupImage;

  /// Participant user IDs as JSON array
  final String participantIds;

  /// Participant details as JSON (for quick display)
  final String participants;

  /// Admin user IDs as JSON array (for group chats)
  final String? adminIds;

  /// Last message text preview
  final String? lastMessageText;

  /// Last message sender ID
  final String? lastMessageSenderId;

  /// Last message sender name
  final String? lastMessageSenderName;

  /// Last message timestamp
  final DateTime? lastMessageTimestamp;

  /// Last message type (text, image, etc.)
  final String? lastMessageType;

  /// Last message translations as JSON
  final String? lastMessageTranslations;

  /// Last update timestamp
  final DateTime lastUpdatedAt;

  /// Conversation initiated timestamp
  final DateTime initiatedAt;

  /// Unread count per user as JSON object
  final String unreadCount;

  /// Translation enabled flag
  final bool translationEnabled;

  /// Auto-detect language flag
  final bool autoDetectLanguage;
  const ConversationEntity({
    required this.documentId,
    required this.conversationType,
    this.groupName,
    this.groupImage,
    required this.participantIds,
    required this.participants,
    this.adminIds,
    this.lastMessageText,
    this.lastMessageSenderId,
    this.lastMessageSenderName,
    this.lastMessageTimestamp,
    this.lastMessageType,
    this.lastMessageTranslations,
    required this.lastUpdatedAt,
    required this.initiatedAt,
    required this.unreadCount,
    required this.translationEnabled,
    required this.autoDetectLanguage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_id'] = Variable<String>(documentId);
    map['conversation_type'] = Variable<String>(conversationType);
    if (!nullToAbsent || groupName != null) {
      map['group_name'] = Variable<String>(groupName);
    }
    if (!nullToAbsent || groupImage != null) {
      map['group_image'] = Variable<String>(groupImage);
    }
    map['participant_ids'] = Variable<String>(participantIds);
    map['participants'] = Variable<String>(participants);
    if (!nullToAbsent || adminIds != null) {
      map['admin_ids'] = Variable<String>(adminIds);
    }
    if (!nullToAbsent || lastMessageText != null) {
      map['last_message_text'] = Variable<String>(lastMessageText);
    }
    if (!nullToAbsent || lastMessageSenderId != null) {
      map['last_message_sender_id'] = Variable<String>(lastMessageSenderId);
    }
    if (!nullToAbsent || lastMessageSenderName != null) {
      map['last_message_sender_name'] = Variable<String>(lastMessageSenderName);
    }
    if (!nullToAbsent || lastMessageTimestamp != null) {
      map['last_message_timestamp'] = Variable<DateTime>(lastMessageTimestamp);
    }
    if (!nullToAbsent || lastMessageType != null) {
      map['last_message_type'] = Variable<String>(lastMessageType);
    }
    if (!nullToAbsent || lastMessageTranslations != null) {
      map['last_message_translations'] = Variable<String>(
        lastMessageTranslations,
      );
    }
    map['last_updated_at'] = Variable<DateTime>(lastUpdatedAt);
    map['initiated_at'] = Variable<DateTime>(initiatedAt);
    map['unread_count'] = Variable<String>(unreadCount);
    map['translation_enabled'] = Variable<bool>(translationEnabled);
    map['auto_detect_language'] = Variable<bool>(autoDetectLanguage);
    return map;
  }

  ConversationsCompanion toCompanion(bool nullToAbsent) {
    return ConversationsCompanion(
      documentId: Value(documentId),
      conversationType: Value(conversationType),
      groupName: groupName == null && nullToAbsent
          ? const Value.absent()
          : Value(groupName),
      groupImage: groupImage == null && nullToAbsent
          ? const Value.absent()
          : Value(groupImage),
      participantIds: Value(participantIds),
      participants: Value(participants),
      adminIds: adminIds == null && nullToAbsent
          ? const Value.absent()
          : Value(adminIds),
      lastMessageText: lastMessageText == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageText),
      lastMessageSenderId: lastMessageSenderId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageSenderId),
      lastMessageSenderName: lastMessageSenderName == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageSenderName),
      lastMessageTimestamp: lastMessageTimestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageTimestamp),
      lastMessageType: lastMessageType == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageType),
      lastMessageTranslations: lastMessageTranslations == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageTranslations),
      lastUpdatedAt: Value(lastUpdatedAt),
      initiatedAt: Value(initiatedAt),
      unreadCount: Value(unreadCount),
      translationEnabled: Value(translationEnabled),
      autoDetectLanguage: Value(autoDetectLanguage),
    );
  }

  factory ConversationEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConversationEntity(
      documentId: serializer.fromJson<String>(json['documentId']),
      conversationType: serializer.fromJson<String>(json['conversationType']),
      groupName: serializer.fromJson<String?>(json['groupName']),
      groupImage: serializer.fromJson<String?>(json['groupImage']),
      participantIds: serializer.fromJson<String>(json['participantIds']),
      participants: serializer.fromJson<String>(json['participants']),
      adminIds: serializer.fromJson<String?>(json['adminIds']),
      lastMessageText: serializer.fromJson<String?>(json['lastMessageText']),
      lastMessageSenderId: serializer.fromJson<String?>(
        json['lastMessageSenderId'],
      ),
      lastMessageSenderName: serializer.fromJson<String?>(
        json['lastMessageSenderName'],
      ),
      lastMessageTimestamp: serializer.fromJson<DateTime?>(
        json['lastMessageTimestamp'],
      ),
      lastMessageType: serializer.fromJson<String?>(json['lastMessageType']),
      lastMessageTranslations: serializer.fromJson<String?>(
        json['lastMessageTranslations'],
      ),
      lastUpdatedAt: serializer.fromJson<DateTime>(json['lastUpdatedAt']),
      initiatedAt: serializer.fromJson<DateTime>(json['initiatedAt']),
      unreadCount: serializer.fromJson<String>(json['unreadCount']),
      translationEnabled: serializer.fromJson<bool>(json['translationEnabled']),
      autoDetectLanguage: serializer.fromJson<bool>(json['autoDetectLanguage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documentId': serializer.toJson<String>(documentId),
      'conversationType': serializer.toJson<String>(conversationType),
      'groupName': serializer.toJson<String?>(groupName),
      'groupImage': serializer.toJson<String?>(groupImage),
      'participantIds': serializer.toJson<String>(participantIds),
      'participants': serializer.toJson<String>(participants),
      'adminIds': serializer.toJson<String?>(adminIds),
      'lastMessageText': serializer.toJson<String?>(lastMessageText),
      'lastMessageSenderId': serializer.toJson<String?>(lastMessageSenderId),
      'lastMessageSenderName': serializer.toJson<String?>(
        lastMessageSenderName,
      ),
      'lastMessageTimestamp': serializer.toJson<DateTime?>(
        lastMessageTimestamp,
      ),
      'lastMessageType': serializer.toJson<String?>(lastMessageType),
      'lastMessageTranslations': serializer.toJson<String?>(
        lastMessageTranslations,
      ),
      'lastUpdatedAt': serializer.toJson<DateTime>(lastUpdatedAt),
      'initiatedAt': serializer.toJson<DateTime>(initiatedAt),
      'unreadCount': serializer.toJson<String>(unreadCount),
      'translationEnabled': serializer.toJson<bool>(translationEnabled),
      'autoDetectLanguage': serializer.toJson<bool>(autoDetectLanguage),
    };
  }

  ConversationEntity copyWith({
    String? documentId,
    String? conversationType,
    Value<String?> groupName = const Value.absent(),
    Value<String?> groupImage = const Value.absent(),
    String? participantIds,
    String? participants,
    Value<String?> adminIds = const Value.absent(),
    Value<String?> lastMessageText = const Value.absent(),
    Value<String?> lastMessageSenderId = const Value.absent(),
    Value<String?> lastMessageSenderName = const Value.absent(),
    Value<DateTime?> lastMessageTimestamp = const Value.absent(),
    Value<String?> lastMessageType = const Value.absent(),
    Value<String?> lastMessageTranslations = const Value.absent(),
    DateTime? lastUpdatedAt,
    DateTime? initiatedAt,
    String? unreadCount,
    bool? translationEnabled,
    bool? autoDetectLanguage,
  }) => ConversationEntity(
    documentId: documentId ?? this.documentId,
    conversationType: conversationType ?? this.conversationType,
    groupName: groupName.present ? groupName.value : this.groupName,
    groupImage: groupImage.present ? groupImage.value : this.groupImage,
    participantIds: participantIds ?? this.participantIds,
    participants: participants ?? this.participants,
    adminIds: adminIds.present ? adminIds.value : this.adminIds,
    lastMessageText: lastMessageText.present
        ? lastMessageText.value
        : this.lastMessageText,
    lastMessageSenderId: lastMessageSenderId.present
        ? lastMessageSenderId.value
        : this.lastMessageSenderId,
    lastMessageSenderName: lastMessageSenderName.present
        ? lastMessageSenderName.value
        : this.lastMessageSenderName,
    lastMessageTimestamp: lastMessageTimestamp.present
        ? lastMessageTimestamp.value
        : this.lastMessageTimestamp,
    lastMessageType: lastMessageType.present
        ? lastMessageType.value
        : this.lastMessageType,
    lastMessageTranslations: lastMessageTranslations.present
        ? lastMessageTranslations.value
        : this.lastMessageTranslations,
    lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    initiatedAt: initiatedAt ?? this.initiatedAt,
    unreadCount: unreadCount ?? this.unreadCount,
    translationEnabled: translationEnabled ?? this.translationEnabled,
    autoDetectLanguage: autoDetectLanguage ?? this.autoDetectLanguage,
  );
  ConversationEntity copyWithCompanion(ConversationsCompanion data) {
    return ConversationEntity(
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      conversationType: data.conversationType.present
          ? data.conversationType.value
          : this.conversationType,
      groupName: data.groupName.present ? data.groupName.value : this.groupName,
      groupImage: data.groupImage.present
          ? data.groupImage.value
          : this.groupImage,
      participantIds: data.participantIds.present
          ? data.participantIds.value
          : this.participantIds,
      participants: data.participants.present
          ? data.participants.value
          : this.participants,
      adminIds: data.adminIds.present ? data.adminIds.value : this.adminIds,
      lastMessageText: data.lastMessageText.present
          ? data.lastMessageText.value
          : this.lastMessageText,
      lastMessageSenderId: data.lastMessageSenderId.present
          ? data.lastMessageSenderId.value
          : this.lastMessageSenderId,
      lastMessageSenderName: data.lastMessageSenderName.present
          ? data.lastMessageSenderName.value
          : this.lastMessageSenderName,
      lastMessageTimestamp: data.lastMessageTimestamp.present
          ? data.lastMessageTimestamp.value
          : this.lastMessageTimestamp,
      lastMessageType: data.lastMessageType.present
          ? data.lastMessageType.value
          : this.lastMessageType,
      lastMessageTranslations: data.lastMessageTranslations.present
          ? data.lastMessageTranslations.value
          : this.lastMessageTranslations,
      lastUpdatedAt: data.lastUpdatedAt.present
          ? data.lastUpdatedAt.value
          : this.lastUpdatedAt,
      initiatedAt: data.initiatedAt.present
          ? data.initiatedAt.value
          : this.initiatedAt,
      unreadCount: data.unreadCount.present
          ? data.unreadCount.value
          : this.unreadCount,
      translationEnabled: data.translationEnabled.present
          ? data.translationEnabled.value
          : this.translationEnabled,
      autoDetectLanguage: data.autoDetectLanguage.present
          ? data.autoDetectLanguage.value
          : this.autoDetectLanguage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConversationEntity(')
          ..write('documentId: $documentId, ')
          ..write('conversationType: $conversationType, ')
          ..write('groupName: $groupName, ')
          ..write('groupImage: $groupImage, ')
          ..write('participantIds: $participantIds, ')
          ..write('participants: $participants, ')
          ..write('adminIds: $adminIds, ')
          ..write('lastMessageText: $lastMessageText, ')
          ..write('lastMessageSenderId: $lastMessageSenderId, ')
          ..write('lastMessageSenderName: $lastMessageSenderName, ')
          ..write('lastMessageTimestamp: $lastMessageTimestamp, ')
          ..write('lastMessageType: $lastMessageType, ')
          ..write('lastMessageTranslations: $lastMessageTranslations, ')
          ..write('lastUpdatedAt: $lastUpdatedAt, ')
          ..write('initiatedAt: $initiatedAt, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('translationEnabled: $translationEnabled, ')
          ..write('autoDetectLanguage: $autoDetectLanguage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    documentId,
    conversationType,
    groupName,
    groupImage,
    participantIds,
    participants,
    adminIds,
    lastMessageText,
    lastMessageSenderId,
    lastMessageSenderName,
    lastMessageTimestamp,
    lastMessageType,
    lastMessageTranslations,
    lastUpdatedAt,
    initiatedAt,
    unreadCount,
    translationEnabled,
    autoDetectLanguage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConversationEntity &&
          other.documentId == this.documentId &&
          other.conversationType == this.conversationType &&
          other.groupName == this.groupName &&
          other.groupImage == this.groupImage &&
          other.participantIds == this.participantIds &&
          other.participants == this.participants &&
          other.adminIds == this.adminIds &&
          other.lastMessageText == this.lastMessageText &&
          other.lastMessageSenderId == this.lastMessageSenderId &&
          other.lastMessageSenderName == this.lastMessageSenderName &&
          other.lastMessageTimestamp == this.lastMessageTimestamp &&
          other.lastMessageType == this.lastMessageType &&
          other.lastMessageTranslations == this.lastMessageTranslations &&
          other.lastUpdatedAt == this.lastUpdatedAt &&
          other.initiatedAt == this.initiatedAt &&
          other.unreadCount == this.unreadCount &&
          other.translationEnabled == this.translationEnabled &&
          other.autoDetectLanguage == this.autoDetectLanguage);
}

class ConversationsCompanion extends UpdateCompanion<ConversationEntity> {
  final Value<String> documentId;
  final Value<String> conversationType;
  final Value<String?> groupName;
  final Value<String?> groupImage;
  final Value<String> participantIds;
  final Value<String> participants;
  final Value<String?> adminIds;
  final Value<String?> lastMessageText;
  final Value<String?> lastMessageSenderId;
  final Value<String?> lastMessageSenderName;
  final Value<DateTime?> lastMessageTimestamp;
  final Value<String?> lastMessageType;
  final Value<String?> lastMessageTranslations;
  final Value<DateTime> lastUpdatedAt;
  final Value<DateTime> initiatedAt;
  final Value<String> unreadCount;
  final Value<bool> translationEnabled;
  final Value<bool> autoDetectLanguage;
  final Value<int> rowid;
  const ConversationsCompanion({
    this.documentId = const Value.absent(),
    this.conversationType = const Value.absent(),
    this.groupName = const Value.absent(),
    this.groupImage = const Value.absent(),
    this.participantIds = const Value.absent(),
    this.participants = const Value.absent(),
    this.adminIds = const Value.absent(),
    this.lastMessageText = const Value.absent(),
    this.lastMessageSenderId = const Value.absent(),
    this.lastMessageSenderName = const Value.absent(),
    this.lastMessageTimestamp = const Value.absent(),
    this.lastMessageType = const Value.absent(),
    this.lastMessageTranslations = const Value.absent(),
    this.lastUpdatedAt = const Value.absent(),
    this.initiatedAt = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.translationEnabled = const Value.absent(),
    this.autoDetectLanguage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationsCompanion.insert({
    required String documentId,
    required String conversationType,
    this.groupName = const Value.absent(),
    this.groupImage = const Value.absent(),
    required String participantIds,
    required String participants,
    this.adminIds = const Value.absent(),
    this.lastMessageText = const Value.absent(),
    this.lastMessageSenderId = const Value.absent(),
    this.lastMessageSenderName = const Value.absent(),
    this.lastMessageTimestamp = const Value.absent(),
    this.lastMessageType = const Value.absent(),
    this.lastMessageTranslations = const Value.absent(),
    required DateTime lastUpdatedAt,
    required DateTime initiatedAt,
    required String unreadCount,
    this.translationEnabled = const Value.absent(),
    this.autoDetectLanguage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : documentId = Value(documentId),
       conversationType = Value(conversationType),
       participantIds = Value(participantIds),
       participants = Value(participants),
       lastUpdatedAt = Value(lastUpdatedAt),
       initiatedAt = Value(initiatedAt),
       unreadCount = Value(unreadCount);
  static Insertable<ConversationEntity> custom({
    Expression<String>? documentId,
    Expression<String>? conversationType,
    Expression<String>? groupName,
    Expression<String>? groupImage,
    Expression<String>? participantIds,
    Expression<String>? participants,
    Expression<String>? adminIds,
    Expression<String>? lastMessageText,
    Expression<String>? lastMessageSenderId,
    Expression<String>? lastMessageSenderName,
    Expression<DateTime>? lastMessageTimestamp,
    Expression<String>? lastMessageType,
    Expression<String>? lastMessageTranslations,
    Expression<DateTime>? lastUpdatedAt,
    Expression<DateTime>? initiatedAt,
    Expression<String>? unreadCount,
    Expression<bool>? translationEnabled,
    Expression<bool>? autoDetectLanguage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (documentId != null) 'document_id': documentId,
      if (conversationType != null) 'conversation_type': conversationType,
      if (groupName != null) 'group_name': groupName,
      if (groupImage != null) 'group_image': groupImage,
      if (participantIds != null) 'participant_ids': participantIds,
      if (participants != null) 'participants': participants,
      if (adminIds != null) 'admin_ids': adminIds,
      if (lastMessageText != null) 'last_message_text': lastMessageText,
      if (lastMessageSenderId != null)
        'last_message_sender_id': lastMessageSenderId,
      if (lastMessageSenderName != null)
        'last_message_sender_name': lastMessageSenderName,
      if (lastMessageTimestamp != null)
        'last_message_timestamp': lastMessageTimestamp,
      if (lastMessageType != null) 'last_message_type': lastMessageType,
      if (lastMessageTranslations != null)
        'last_message_translations': lastMessageTranslations,
      if (lastUpdatedAt != null) 'last_updated_at': lastUpdatedAt,
      if (initiatedAt != null) 'initiated_at': initiatedAt,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (translationEnabled != null) 'translation_enabled': translationEnabled,
      if (autoDetectLanguage != null)
        'auto_detect_language': autoDetectLanguage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationsCompanion copyWith({
    Value<String>? documentId,
    Value<String>? conversationType,
    Value<String?>? groupName,
    Value<String?>? groupImage,
    Value<String>? participantIds,
    Value<String>? participants,
    Value<String?>? adminIds,
    Value<String?>? lastMessageText,
    Value<String?>? lastMessageSenderId,
    Value<String?>? lastMessageSenderName,
    Value<DateTime?>? lastMessageTimestamp,
    Value<String?>? lastMessageType,
    Value<String?>? lastMessageTranslations,
    Value<DateTime>? lastUpdatedAt,
    Value<DateTime>? initiatedAt,
    Value<String>? unreadCount,
    Value<bool>? translationEnabled,
    Value<bool>? autoDetectLanguage,
    Value<int>? rowid,
  }) {
    return ConversationsCompanion(
      documentId: documentId ?? this.documentId,
      conversationType: conversationType ?? this.conversationType,
      groupName: groupName ?? this.groupName,
      groupImage: groupImage ?? this.groupImage,
      participantIds: participantIds ?? this.participantIds,
      participants: participants ?? this.participants,
      adminIds: adminIds ?? this.adminIds,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageSenderName:
          lastMessageSenderName ?? this.lastMessageSenderName,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageTranslations:
          lastMessageTranslations ?? this.lastMessageTranslations,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      initiatedAt: initiatedAt ?? this.initiatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
      translationEnabled: translationEnabled ?? this.translationEnabled,
      autoDetectLanguage: autoDetectLanguage ?? this.autoDetectLanguage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (conversationType.present) {
      map['conversation_type'] = Variable<String>(conversationType.value);
    }
    if (groupName.present) {
      map['group_name'] = Variable<String>(groupName.value);
    }
    if (groupImage.present) {
      map['group_image'] = Variable<String>(groupImage.value);
    }
    if (participantIds.present) {
      map['participant_ids'] = Variable<String>(participantIds.value);
    }
    if (participants.present) {
      map['participants'] = Variable<String>(participants.value);
    }
    if (adminIds.present) {
      map['admin_ids'] = Variable<String>(adminIds.value);
    }
    if (lastMessageText.present) {
      map['last_message_text'] = Variable<String>(lastMessageText.value);
    }
    if (lastMessageSenderId.present) {
      map['last_message_sender_id'] = Variable<String>(
        lastMessageSenderId.value,
      );
    }
    if (lastMessageSenderName.present) {
      map['last_message_sender_name'] = Variable<String>(
        lastMessageSenderName.value,
      );
    }
    if (lastMessageTimestamp.present) {
      map['last_message_timestamp'] = Variable<DateTime>(
        lastMessageTimestamp.value,
      );
    }
    if (lastMessageType.present) {
      map['last_message_type'] = Variable<String>(lastMessageType.value);
    }
    if (lastMessageTranslations.present) {
      map['last_message_translations'] = Variable<String>(
        lastMessageTranslations.value,
      );
    }
    if (lastUpdatedAt.present) {
      map['last_updated_at'] = Variable<DateTime>(lastUpdatedAt.value);
    }
    if (initiatedAt.present) {
      map['initiated_at'] = Variable<DateTime>(initiatedAt.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<String>(unreadCount.value);
    }
    if (translationEnabled.present) {
      map['translation_enabled'] = Variable<bool>(translationEnabled.value);
    }
    if (autoDetectLanguage.present) {
      map['auto_detect_language'] = Variable<bool>(autoDetectLanguage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationsCompanion(')
          ..write('documentId: $documentId, ')
          ..write('conversationType: $conversationType, ')
          ..write('groupName: $groupName, ')
          ..write('groupImage: $groupImage, ')
          ..write('participantIds: $participantIds, ')
          ..write('participants: $participants, ')
          ..write('adminIds: $adminIds, ')
          ..write('lastMessageText: $lastMessageText, ')
          ..write('lastMessageSenderId: $lastMessageSenderId, ')
          ..write('lastMessageSenderName: $lastMessageSenderName, ')
          ..write('lastMessageTimestamp: $lastMessageTimestamp, ')
          ..write('lastMessageType: $lastMessageType, ')
          ..write('lastMessageTranslations: $lastMessageTranslations, ')
          ..write('lastUpdatedAt: $lastUpdatedAt, ')
          ..write('initiatedAt: $initiatedAt, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('translationEnabled: $translationEnabled, ')
          ..write('autoDetectLanguage: $autoDetectLanguage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages
    with TableInfo<$MessagesTable, MessageEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageTextMeta = const VerificationMeta(
    'messageText',
  );
  @override
  late final GeneratedColumn<String> messageText = GeneratedColumn<String>(
    'message_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderIdMeta = const VerificationMeta(
    'senderId',
  );
  @override
  late final GeneratedColumn<String> senderId = GeneratedColumn<String>(
    'sender_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageTypeMeta = const VerificationMeta(
    'messageType',
  );
  @override
  late final GeneratedColumn<String> messageType = GeneratedColumn<String>(
    'message_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('text'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('sending'),
  );
  static const VerificationMeta _detectedLanguageMeta = const VerificationMeta(
    'detectedLanguage',
  );
  @override
  late final GeneratedColumn<String> detectedLanguage = GeneratedColumn<String>(
    'detected_language',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _translationsMeta = const VerificationMeta(
    'translations',
  );
  @override
  late final GeneratedColumn<String> translations = GeneratedColumn<String>(
    'translations',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _replyToMeta = const VerificationMeta(
    'replyTo',
  );
  @override
  late final GeneratedColumn<String> replyTo = GeneratedColumn<String>(
    'reply_to',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aiAnalysisMeta = const VerificationMeta(
    'aiAnalysis',
  );
  @override
  late final GeneratedColumn<String> aiAnalysis = GeneratedColumn<String>(
    'ai_analysis',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _culturalHintMeta = const VerificationMeta(
    'culturalHint',
  );
  @override
  late final GeneratedColumn<String> culturalHint = GeneratedColumn<String>(
    'cultural_hint',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _embeddingMeta = const VerificationMeta(
    'embedding',
  );
  @override
  late final GeneratedColumn<String> embedding = GeneratedColumn<String>(
    'embedding',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tempIdMeta = const VerificationMeta('tempId');
  @override
  late final GeneratedColumn<String> tempId = GeneratedColumn<String>(
    'temp_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncAttemptMeta = const VerificationMeta(
    'lastSyncAttempt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAttempt =
      GeneratedColumn<DateTime>(
        'last_sync_attempt',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    conversationId,
    messageText,
    senderId,
    timestamp,
    messageType,
    status,
    detectedLanguage,
    translations,
    replyTo,
    metadata,
    aiAnalysis,
    culturalHint,
    embedding,
    syncStatus,
    retryCount,
    tempId,
    lastSyncAttempt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessageEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('message_text')) {
      context.handle(
        _messageTextMeta,
        messageText.isAcceptableOrUnknown(
          data['message_text']!,
          _messageTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_messageTextMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(
        _senderIdMeta,
        senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_senderIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('message_type')) {
      context.handle(
        _messageTypeMeta,
        messageType.isAcceptableOrUnknown(
          data['message_type']!,
          _messageTypeMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('detected_language')) {
      context.handle(
        _detectedLanguageMeta,
        detectedLanguage.isAcceptableOrUnknown(
          data['detected_language']!,
          _detectedLanguageMeta,
        ),
      );
    }
    if (data.containsKey('translations')) {
      context.handle(
        _translationsMeta,
        translations.isAcceptableOrUnknown(
          data['translations']!,
          _translationsMeta,
        ),
      );
    }
    if (data.containsKey('reply_to')) {
      context.handle(
        _replyToMeta,
        replyTo.isAcceptableOrUnknown(data['reply_to']!, _replyToMeta),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    if (data.containsKey('ai_analysis')) {
      context.handle(
        _aiAnalysisMeta,
        aiAnalysis.isAcceptableOrUnknown(data['ai_analysis']!, _aiAnalysisMeta),
      );
    }
    if (data.containsKey('cultural_hint')) {
      context.handle(
        _culturalHintMeta,
        culturalHint.isAcceptableOrUnknown(
          data['cultural_hint']!,
          _culturalHintMeta,
        ),
      );
    }
    if (data.containsKey('embedding')) {
      context.handle(
        _embeddingMeta,
        embedding.isAcceptableOrUnknown(data['embedding']!, _embeddingMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('temp_id')) {
      context.handle(
        _tempIdMeta,
        tempId.isAcceptableOrUnknown(data['temp_id']!, _tempIdMeta),
      );
    }
    if (data.containsKey('last_sync_attempt')) {
      context.handle(
        _lastSyncAttemptMeta,
        lastSyncAttempt.isAcceptableOrUnknown(
          data['last_sync_attempt']!,
          _lastSyncAttemptMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessageEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      messageText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_text'],
      )!,
      senderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      messageType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_type'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      detectedLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detected_language'],
      ),
      translations: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translations'],
      ),
      replyTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reply_to'],
      ),
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
      aiAnalysis: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ai_analysis'],
      ),
      culturalHint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cultural_hint'],
      ),
      embedding: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}embedding'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      tempId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}temp_id'],
      ),
      lastSyncAttempt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_attempt'],
      ),
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class MessageEntity extends DataClass implements Insertable<MessageEntity> {
  /// Unique message ID (matches Firestore document ID or temp ID)
  final String id;

  /// Conversation ID this message belongs to
  final String conversationId;

  /// Message text content
  final String messageText;

  /// Sender user ID
  /// Display name is looked up dynamically via UserLookupProvider
  final String senderId;

  /// Message timestamp
  final DateTime timestamp;

  /// Message type: 'text', 'image', 'file', etc.
  final String messageType;

  /// Message status: 'sending', 'sent', 'delivered', 'read', 'failed'
  final String status;

  /// Detected language code
  final String? detectedLanguage;

  /// Translations as JSON object {lang: translation}
  final String? translations;

  /// Reply-to message ID
  final String? replyTo;

  /// Message metadata as JSON
  final String? metadata;

  /// AI analysis results as JSON
  final String? aiAnalysis;

  /// Cultural context hint explaining nuances, idioms, or formality
  final String? culturalHint;

  /// Embedding vector for RAG (stored as JSON array)
  final String? embedding;

  /// Sync status: 'pending', 'synced', 'failed'
  final String syncStatus;

  /// Retry count for failed sync attempts
  final int retryCount;

  /// Temporary ID for optimistic updates (null after sync)
  final String? tempId;

  /// Last sync attempt timestamp
  final DateTime? lastSyncAttempt;
  const MessageEntity({
    required this.id,
    required this.conversationId,
    required this.messageText,
    required this.senderId,
    required this.timestamp,
    required this.messageType,
    required this.status,
    this.detectedLanguage,
    this.translations,
    this.replyTo,
    this.metadata,
    this.aiAnalysis,
    this.culturalHint,
    this.embedding,
    required this.syncStatus,
    required this.retryCount,
    this.tempId,
    this.lastSyncAttempt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['conversation_id'] = Variable<String>(conversationId);
    map['message_text'] = Variable<String>(messageText);
    map['sender_id'] = Variable<String>(senderId);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['message_type'] = Variable<String>(messageType);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || detectedLanguage != null) {
      map['detected_language'] = Variable<String>(detectedLanguage);
    }
    if (!nullToAbsent || translations != null) {
      map['translations'] = Variable<String>(translations);
    }
    if (!nullToAbsent || replyTo != null) {
      map['reply_to'] = Variable<String>(replyTo);
    }
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    if (!nullToAbsent || aiAnalysis != null) {
      map['ai_analysis'] = Variable<String>(aiAnalysis);
    }
    if (!nullToAbsent || culturalHint != null) {
      map['cultural_hint'] = Variable<String>(culturalHint);
    }
    if (!nullToAbsent || embedding != null) {
      map['embedding'] = Variable<String>(embedding);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || tempId != null) {
      map['temp_id'] = Variable<String>(tempId);
    }
    if (!nullToAbsent || lastSyncAttempt != null) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt);
    }
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      conversationId: Value(conversationId),
      messageText: Value(messageText),
      senderId: Value(senderId),
      timestamp: Value(timestamp),
      messageType: Value(messageType),
      status: Value(status),
      detectedLanguage: detectedLanguage == null && nullToAbsent
          ? const Value.absent()
          : Value(detectedLanguage),
      translations: translations == null && nullToAbsent
          ? const Value.absent()
          : Value(translations),
      replyTo: replyTo == null && nullToAbsent
          ? const Value.absent()
          : Value(replyTo),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      aiAnalysis: aiAnalysis == null && nullToAbsent
          ? const Value.absent()
          : Value(aiAnalysis),
      culturalHint: culturalHint == null && nullToAbsent
          ? const Value.absent()
          : Value(culturalHint),
      embedding: embedding == null && nullToAbsent
          ? const Value.absent()
          : Value(embedding),
      syncStatus: Value(syncStatus),
      retryCount: Value(retryCount),
      tempId: tempId == null && nullToAbsent
          ? const Value.absent()
          : Value(tempId),
      lastSyncAttempt: lastSyncAttempt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAttempt),
    );
  }

  factory MessageEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageEntity(
      id: serializer.fromJson<String>(json['id']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      messageText: serializer.fromJson<String>(json['messageText']),
      senderId: serializer.fromJson<String>(json['senderId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      messageType: serializer.fromJson<String>(json['messageType']),
      status: serializer.fromJson<String>(json['status']),
      detectedLanguage: serializer.fromJson<String?>(json['detectedLanguage']),
      translations: serializer.fromJson<String?>(json['translations']),
      replyTo: serializer.fromJson<String?>(json['replyTo']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      aiAnalysis: serializer.fromJson<String?>(json['aiAnalysis']),
      culturalHint: serializer.fromJson<String?>(json['culturalHint']),
      embedding: serializer.fromJson<String?>(json['embedding']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      tempId: serializer.fromJson<String?>(json['tempId']),
      lastSyncAttempt: serializer.fromJson<DateTime?>(json['lastSyncAttempt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'conversationId': serializer.toJson<String>(conversationId),
      'messageText': serializer.toJson<String>(messageText),
      'senderId': serializer.toJson<String>(senderId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'messageType': serializer.toJson<String>(messageType),
      'status': serializer.toJson<String>(status),
      'detectedLanguage': serializer.toJson<String?>(detectedLanguage),
      'translations': serializer.toJson<String?>(translations),
      'replyTo': serializer.toJson<String?>(replyTo),
      'metadata': serializer.toJson<String?>(metadata),
      'aiAnalysis': serializer.toJson<String?>(aiAnalysis),
      'culturalHint': serializer.toJson<String?>(culturalHint),
      'embedding': serializer.toJson<String?>(embedding),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'retryCount': serializer.toJson<int>(retryCount),
      'tempId': serializer.toJson<String?>(tempId),
      'lastSyncAttempt': serializer.toJson<DateTime?>(lastSyncAttempt),
    };
  }

  MessageEntity copyWith({
    String? id,
    String? conversationId,
    String? messageText,
    String? senderId,
    DateTime? timestamp,
    String? messageType,
    String? status,
    Value<String?> detectedLanguage = const Value.absent(),
    Value<String?> translations = const Value.absent(),
    Value<String?> replyTo = const Value.absent(),
    Value<String?> metadata = const Value.absent(),
    Value<String?> aiAnalysis = const Value.absent(),
    Value<String?> culturalHint = const Value.absent(),
    Value<String?> embedding = const Value.absent(),
    String? syncStatus,
    int? retryCount,
    Value<String?> tempId = const Value.absent(),
    Value<DateTime?> lastSyncAttempt = const Value.absent(),
  }) => MessageEntity(
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    messageText: messageText ?? this.messageText,
    senderId: senderId ?? this.senderId,
    timestamp: timestamp ?? this.timestamp,
    messageType: messageType ?? this.messageType,
    status: status ?? this.status,
    detectedLanguage: detectedLanguage.present
        ? detectedLanguage.value
        : this.detectedLanguage,
    translations: translations.present ? translations.value : this.translations,
    replyTo: replyTo.present ? replyTo.value : this.replyTo,
    metadata: metadata.present ? metadata.value : this.metadata,
    aiAnalysis: aiAnalysis.present ? aiAnalysis.value : this.aiAnalysis,
    culturalHint: culturalHint.present ? culturalHint.value : this.culturalHint,
    embedding: embedding.present ? embedding.value : this.embedding,
    syncStatus: syncStatus ?? this.syncStatus,
    retryCount: retryCount ?? this.retryCount,
    tempId: tempId.present ? tempId.value : this.tempId,
    lastSyncAttempt: lastSyncAttempt.present
        ? lastSyncAttempt.value
        : this.lastSyncAttempt,
  );
  MessageEntity copyWithCompanion(MessagesCompanion data) {
    return MessageEntity(
      id: data.id.present ? data.id.value : this.id,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      messageText: data.messageText.present
          ? data.messageText.value
          : this.messageText,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      messageType: data.messageType.present
          ? data.messageType.value
          : this.messageType,
      status: data.status.present ? data.status.value : this.status,
      detectedLanguage: data.detectedLanguage.present
          ? data.detectedLanguage.value
          : this.detectedLanguage,
      translations: data.translations.present
          ? data.translations.value
          : this.translations,
      replyTo: data.replyTo.present ? data.replyTo.value : this.replyTo,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      aiAnalysis: data.aiAnalysis.present
          ? data.aiAnalysis.value
          : this.aiAnalysis,
      culturalHint: data.culturalHint.present
          ? data.culturalHint.value
          : this.culturalHint,
      embedding: data.embedding.present ? data.embedding.value : this.embedding,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      tempId: data.tempId.present ? data.tempId.value : this.tempId,
      lastSyncAttempt: data.lastSyncAttempt.present
          ? data.lastSyncAttempt.value
          : this.lastSyncAttempt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageEntity(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('messageText: $messageText, ')
          ..write('senderId: $senderId, ')
          ..write('timestamp: $timestamp, ')
          ..write('messageType: $messageType, ')
          ..write('status: $status, ')
          ..write('detectedLanguage: $detectedLanguage, ')
          ..write('translations: $translations, ')
          ..write('replyTo: $replyTo, ')
          ..write('metadata: $metadata, ')
          ..write('aiAnalysis: $aiAnalysis, ')
          ..write('culturalHint: $culturalHint, ')
          ..write('embedding: $embedding, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('retryCount: $retryCount, ')
          ..write('tempId: $tempId, ')
          ..write('lastSyncAttempt: $lastSyncAttempt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    conversationId,
    messageText,
    senderId,
    timestamp,
    messageType,
    status,
    detectedLanguage,
    translations,
    replyTo,
    metadata,
    aiAnalysis,
    culturalHint,
    embedding,
    syncStatus,
    retryCount,
    tempId,
    lastSyncAttempt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageEntity &&
          other.id == this.id &&
          other.conversationId == this.conversationId &&
          other.messageText == this.messageText &&
          other.senderId == this.senderId &&
          other.timestamp == this.timestamp &&
          other.messageType == this.messageType &&
          other.status == this.status &&
          other.detectedLanguage == this.detectedLanguage &&
          other.translations == this.translations &&
          other.replyTo == this.replyTo &&
          other.metadata == this.metadata &&
          other.aiAnalysis == this.aiAnalysis &&
          other.culturalHint == this.culturalHint &&
          other.embedding == this.embedding &&
          other.syncStatus == this.syncStatus &&
          other.retryCount == this.retryCount &&
          other.tempId == this.tempId &&
          other.lastSyncAttempt == this.lastSyncAttempt);
}

class MessagesCompanion extends UpdateCompanion<MessageEntity> {
  final Value<String> id;
  final Value<String> conversationId;
  final Value<String> messageText;
  final Value<String> senderId;
  final Value<DateTime> timestamp;
  final Value<String> messageType;
  final Value<String> status;
  final Value<String?> detectedLanguage;
  final Value<String?> translations;
  final Value<String?> replyTo;
  final Value<String?> metadata;
  final Value<String?> aiAnalysis;
  final Value<String?> culturalHint;
  final Value<String?> embedding;
  final Value<String> syncStatus;
  final Value<int> retryCount;
  final Value<String?> tempId;
  final Value<DateTime?> lastSyncAttempt;
  final Value<int> rowid;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.messageText = const Value.absent(),
    this.senderId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.messageType = const Value.absent(),
    this.status = const Value.absent(),
    this.detectedLanguage = const Value.absent(),
    this.translations = const Value.absent(),
    this.replyTo = const Value.absent(),
    this.metadata = const Value.absent(),
    this.aiAnalysis = const Value.absent(),
    this.culturalHint = const Value.absent(),
    this.embedding = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.tempId = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String id,
    required String conversationId,
    required String messageText,
    required String senderId,
    required DateTime timestamp,
    this.messageType = const Value.absent(),
    this.status = const Value.absent(),
    this.detectedLanguage = const Value.absent(),
    this.translations = const Value.absent(),
    this.replyTo = const Value.absent(),
    this.metadata = const Value.absent(),
    this.aiAnalysis = const Value.absent(),
    this.culturalHint = const Value.absent(),
    this.embedding = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.tempId = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       conversationId = Value(conversationId),
       messageText = Value(messageText),
       senderId = Value(senderId),
       timestamp = Value(timestamp);
  static Insertable<MessageEntity> custom({
    Expression<String>? id,
    Expression<String>? conversationId,
    Expression<String>? messageText,
    Expression<String>? senderId,
    Expression<DateTime>? timestamp,
    Expression<String>? messageType,
    Expression<String>? status,
    Expression<String>? detectedLanguage,
    Expression<String>? translations,
    Expression<String>? replyTo,
    Expression<String>? metadata,
    Expression<String>? aiAnalysis,
    Expression<String>? culturalHint,
    Expression<String>? embedding,
    Expression<String>? syncStatus,
    Expression<int>? retryCount,
    Expression<String>? tempId,
    Expression<DateTime>? lastSyncAttempt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      if (messageText != null) 'message_text': messageText,
      if (senderId != null) 'sender_id': senderId,
      if (timestamp != null) 'timestamp': timestamp,
      if (messageType != null) 'message_type': messageType,
      if (status != null) 'status': status,
      if (detectedLanguage != null) 'detected_language': detectedLanguage,
      if (translations != null) 'translations': translations,
      if (replyTo != null) 'reply_to': replyTo,
      if (metadata != null) 'metadata': metadata,
      if (aiAnalysis != null) 'ai_analysis': aiAnalysis,
      if (culturalHint != null) 'cultural_hint': culturalHint,
      if (embedding != null) 'embedding': embedding,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (retryCount != null) 'retry_count': retryCount,
      if (tempId != null) 'temp_id': tempId,
      if (lastSyncAttempt != null) 'last_sync_attempt': lastSyncAttempt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? conversationId,
    Value<String>? messageText,
    Value<String>? senderId,
    Value<DateTime>? timestamp,
    Value<String>? messageType,
    Value<String>? status,
    Value<String?>? detectedLanguage,
    Value<String?>? translations,
    Value<String?>? replyTo,
    Value<String?>? metadata,
    Value<String?>? aiAnalysis,
    Value<String?>? culturalHint,
    Value<String?>? embedding,
    Value<String>? syncStatus,
    Value<int>? retryCount,
    Value<String?>? tempId,
    Value<DateTime?>? lastSyncAttempt,
    Value<int>? rowid,
  }) {
    return MessagesCompanion(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      messageText: messageText ?? this.messageText,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
      messageType: messageType ?? this.messageType,
      status: status ?? this.status,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      translations: translations ?? this.translations,
      replyTo: replyTo ?? this.replyTo,
      metadata: metadata ?? this.metadata,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      culturalHint: culturalHint ?? this.culturalHint,
      embedding: embedding ?? this.embedding,
      syncStatus: syncStatus ?? this.syncStatus,
      retryCount: retryCount ?? this.retryCount,
      tempId: tempId ?? this.tempId,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (messageText.present) {
      map['message_text'] = Variable<String>(messageText.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<String>(senderId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (messageType.present) {
      map['message_type'] = Variable<String>(messageType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (detectedLanguage.present) {
      map['detected_language'] = Variable<String>(detectedLanguage.value);
    }
    if (translations.present) {
      map['translations'] = Variable<String>(translations.value);
    }
    if (replyTo.present) {
      map['reply_to'] = Variable<String>(replyTo.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (aiAnalysis.present) {
      map['ai_analysis'] = Variable<String>(aiAnalysis.value);
    }
    if (culturalHint.present) {
      map['cultural_hint'] = Variable<String>(culturalHint.value);
    }
    if (embedding.present) {
      map['embedding'] = Variable<String>(embedding.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (tempId.present) {
      map['temp_id'] = Variable<String>(tempId.value);
    }
    if (lastSyncAttempt.present) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('messageText: $messageText, ')
          ..write('senderId: $senderId, ')
          ..write('timestamp: $timestamp, ')
          ..write('messageType: $messageType, ')
          ..write('status: $status, ')
          ..write('detectedLanguage: $detectedLanguage, ')
          ..write('translations: $translations, ')
          ..write('replyTo: $replyTo, ')
          ..write('metadata: $metadata, ')
          ..write('aiAnalysis: $aiAnalysis, ')
          ..write('culturalHint: $culturalHint, ')
          ..write('embedding: $embedding, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('retryCount: $retryCount, ')
          ..write('tempId: $tempId, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $ConversationsTable conversations = $ConversationsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final MessageDao messageDao = MessageDao(this as AppDatabase);
  late final ConversationDao conversationDao = ConversationDao(
    this as AppDatabase,
  );
  late final UserDao userDao = UserDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    users,
    conversations,
    messages,
  ];
}

typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      required String uid,
      Value<String?> email,
      Value<String?> phoneNumber,
      required String name,
      Value<String?> imageUrl,
      Value<String?> fcmToken,
      Value<String> preferredLanguage,
      required DateTime createdAt,
      required DateTime lastSeen,
      Value<bool> isOnline,
      Value<int> rowid,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<String> uid,
      Value<String?> email,
      Value<String?> phoneNumber,
      Value<String> name,
      Value<String?> imageUrl,
      Value<String?> fcmToken,
      Value<String> preferredLanguage,
      Value<DateTime> createdAt,
      Value<DateTime> lastSeen,
      Value<bool> isOnline,
      Value<int> rowid,
    });

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fcmToken => $composableBuilder(
    column: $table.fcmToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredLanguage => $composableBuilder(
    column: $table.preferredLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSeen => $composableBuilder(
    column: $table.lastSeen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOnline => $composableBuilder(
    column: $table.isOnline,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fcmToken => $composableBuilder(
    column: $table.fcmToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredLanguage => $composableBuilder(
    column: $table.preferredLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeen => $composableBuilder(
    column: $table.lastSeen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOnline => $composableBuilder(
    column: $table.isOnline,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get fcmToken =>
      $composableBuilder(column: $table.fcmToken, builder: (column) => column);

  GeneratedColumn<String> get preferredLanguage => $composableBuilder(
    column: $table.preferredLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSeen =>
      $composableBuilder(column: $table.lastSeen, builder: (column) => column);

  GeneratedColumn<bool> get isOnline =>
      $composableBuilder(column: $table.isOnline, builder: (column) => column);
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          UserEntity,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (UserEntity, BaseReferences<_$AppDatabase, $UsersTable, UserEntity>),
          UserEntity,
          PrefetchHooks Function()
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uid = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> phoneNumber = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> fcmToken = const Value.absent(),
                Value<String> preferredLanguage = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastSeen = const Value.absent(),
                Value<bool> isOnline = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion(
                uid: uid,
                email: email,
                phoneNumber: phoneNumber,
                name: name,
                imageUrl: imageUrl,
                fcmToken: fcmToken,
                preferredLanguage: preferredLanguage,
                createdAt: createdAt,
                lastSeen: lastSeen,
                isOnline: isOnline,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uid,
                Value<String?> email = const Value.absent(),
                Value<String?> phoneNumber = const Value.absent(),
                required String name,
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> fcmToken = const Value.absent(),
                Value<String> preferredLanguage = const Value.absent(),
                required DateTime createdAt,
                required DateTime lastSeen,
                Value<bool> isOnline = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion.insert(
                uid: uid,
                email: email,
                phoneNumber: phoneNumber,
                name: name,
                imageUrl: imageUrl,
                fcmToken: fcmToken,
                preferredLanguage: preferredLanguage,
                createdAt: createdAt,
                lastSeen: lastSeen,
                isOnline: isOnline,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      UserEntity,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (UserEntity, BaseReferences<_$AppDatabase, $UsersTable, UserEntity>),
      UserEntity,
      PrefetchHooks Function()
    >;
typedef $$ConversationsTableCreateCompanionBuilder =
    ConversationsCompanion Function({
      required String documentId,
      required String conversationType,
      Value<String?> groupName,
      Value<String?> groupImage,
      required String participantIds,
      required String participants,
      Value<String?> adminIds,
      Value<String?> lastMessageText,
      Value<String?> lastMessageSenderId,
      Value<String?> lastMessageSenderName,
      Value<DateTime?> lastMessageTimestamp,
      Value<String?> lastMessageType,
      Value<String?> lastMessageTranslations,
      required DateTime lastUpdatedAt,
      required DateTime initiatedAt,
      required String unreadCount,
      Value<bool> translationEnabled,
      Value<bool> autoDetectLanguage,
      Value<int> rowid,
    });
typedef $$ConversationsTableUpdateCompanionBuilder =
    ConversationsCompanion Function({
      Value<String> documentId,
      Value<String> conversationType,
      Value<String?> groupName,
      Value<String?> groupImage,
      Value<String> participantIds,
      Value<String> participants,
      Value<String?> adminIds,
      Value<String?> lastMessageText,
      Value<String?> lastMessageSenderId,
      Value<String?> lastMessageSenderName,
      Value<DateTime?> lastMessageTimestamp,
      Value<String?> lastMessageType,
      Value<String?> lastMessageTranslations,
      Value<DateTime> lastUpdatedAt,
      Value<DateTime> initiatedAt,
      Value<String> unreadCount,
      Value<bool> translationEnabled,
      Value<bool> autoDetectLanguage,
      Value<int> rowid,
    });

class $$ConversationsTableFilterComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conversationType => $composableBuilder(
    column: $table.conversationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupImage => $composableBuilder(
    column: $table.groupImage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get participantIds => $composableBuilder(
    column: $table.participantIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get participants => $composableBuilder(
    column: $table.participants,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get adminIds => $composableBuilder(
    column: $table.adminIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessageText => $composableBuilder(
    column: $table.lastMessageText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessageSenderId => $composableBuilder(
    column: $table.lastMessageSenderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessageSenderName => $composableBuilder(
    column: $table.lastMessageSenderName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastMessageTimestamp => $composableBuilder(
    column: $table.lastMessageTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessageType => $composableBuilder(
    column: $table.lastMessageType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessageTranslations => $composableBuilder(
    column: $table.lastMessageTranslations,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get initiatedAt => $composableBuilder(
    column: $table.initiatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get translationEnabled => $composableBuilder(
    column: $table.translationEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoDetectLanguage => $composableBuilder(
    column: $table.autoDetectLanguage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConversationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conversationType => $composableBuilder(
    column: $table.conversationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupImage => $composableBuilder(
    column: $table.groupImage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get participantIds => $composableBuilder(
    column: $table.participantIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get participants => $composableBuilder(
    column: $table.participants,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get adminIds => $composableBuilder(
    column: $table.adminIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessageText => $composableBuilder(
    column: $table.lastMessageText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessageSenderId => $composableBuilder(
    column: $table.lastMessageSenderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessageSenderName => $composableBuilder(
    column: $table.lastMessageSenderName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastMessageTimestamp => $composableBuilder(
    column: $table.lastMessageTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessageType => $composableBuilder(
    column: $table.lastMessageType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessageTranslations => $composableBuilder(
    column: $table.lastMessageTranslations,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get initiatedAt => $composableBuilder(
    column: $table.initiatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get translationEnabled => $composableBuilder(
    column: $table.translationEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoDetectLanguage => $composableBuilder(
    column: $table.autoDetectLanguage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConversationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get conversationType => $composableBuilder(
    column: $table.conversationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get groupName =>
      $composableBuilder(column: $table.groupName, builder: (column) => column);

  GeneratedColumn<String> get groupImage => $composableBuilder(
    column: $table.groupImage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get participantIds => $composableBuilder(
    column: $table.participantIds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get participants => $composableBuilder(
    column: $table.participants,
    builder: (column) => column,
  );

  GeneratedColumn<String> get adminIds =>
      $composableBuilder(column: $table.adminIds, builder: (column) => column);

  GeneratedColumn<String> get lastMessageText => $composableBuilder(
    column: $table.lastMessageText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessageSenderId => $composableBuilder(
    column: $table.lastMessageSenderId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessageSenderName => $composableBuilder(
    column: $table.lastMessageSenderName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastMessageTimestamp => $composableBuilder(
    column: $table.lastMessageTimestamp,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessageType => $composableBuilder(
    column: $table.lastMessageType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessageTranslations => $composableBuilder(
    column: $table.lastMessageTranslations,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get initiatedAt => $composableBuilder(
    column: $table.initiatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get translationEnabled => $composableBuilder(
    column: $table.translationEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoDetectLanguage => $composableBuilder(
    column: $table.autoDetectLanguage,
    builder: (column) => column,
  );
}

class $$ConversationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConversationsTable,
          ConversationEntity,
          $$ConversationsTableFilterComposer,
          $$ConversationsTableOrderingComposer,
          $$ConversationsTableAnnotationComposer,
          $$ConversationsTableCreateCompanionBuilder,
          $$ConversationsTableUpdateCompanionBuilder,
          (
            ConversationEntity,
            BaseReferences<
              _$AppDatabase,
              $ConversationsTable,
              ConversationEntity
            >,
          ),
          ConversationEntity,
          PrefetchHooks Function()
        > {
  $$ConversationsTableTableManager(_$AppDatabase db, $ConversationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConversationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> documentId = const Value.absent(),
                Value<String> conversationType = const Value.absent(),
                Value<String?> groupName = const Value.absent(),
                Value<String?> groupImage = const Value.absent(),
                Value<String> participantIds = const Value.absent(),
                Value<String> participants = const Value.absent(),
                Value<String?> adminIds = const Value.absent(),
                Value<String?> lastMessageText = const Value.absent(),
                Value<String?> lastMessageSenderId = const Value.absent(),
                Value<String?> lastMessageSenderName = const Value.absent(),
                Value<DateTime?> lastMessageTimestamp = const Value.absent(),
                Value<String?> lastMessageType = const Value.absent(),
                Value<String?> lastMessageTranslations = const Value.absent(),
                Value<DateTime> lastUpdatedAt = const Value.absent(),
                Value<DateTime> initiatedAt = const Value.absent(),
                Value<String> unreadCount = const Value.absent(),
                Value<bool> translationEnabled = const Value.absent(),
                Value<bool> autoDetectLanguage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationsCompanion(
                documentId: documentId,
                conversationType: conversationType,
                groupName: groupName,
                groupImage: groupImage,
                participantIds: participantIds,
                participants: participants,
                adminIds: adminIds,
                lastMessageText: lastMessageText,
                lastMessageSenderId: lastMessageSenderId,
                lastMessageSenderName: lastMessageSenderName,
                lastMessageTimestamp: lastMessageTimestamp,
                lastMessageType: lastMessageType,
                lastMessageTranslations: lastMessageTranslations,
                lastUpdatedAt: lastUpdatedAt,
                initiatedAt: initiatedAt,
                unreadCount: unreadCount,
                translationEnabled: translationEnabled,
                autoDetectLanguage: autoDetectLanguage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String documentId,
                required String conversationType,
                Value<String?> groupName = const Value.absent(),
                Value<String?> groupImage = const Value.absent(),
                required String participantIds,
                required String participants,
                Value<String?> adminIds = const Value.absent(),
                Value<String?> lastMessageText = const Value.absent(),
                Value<String?> lastMessageSenderId = const Value.absent(),
                Value<String?> lastMessageSenderName = const Value.absent(),
                Value<DateTime?> lastMessageTimestamp = const Value.absent(),
                Value<String?> lastMessageType = const Value.absent(),
                Value<String?> lastMessageTranslations = const Value.absent(),
                required DateTime lastUpdatedAt,
                required DateTime initiatedAt,
                required String unreadCount,
                Value<bool> translationEnabled = const Value.absent(),
                Value<bool> autoDetectLanguage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationsCompanion.insert(
                documentId: documentId,
                conversationType: conversationType,
                groupName: groupName,
                groupImage: groupImage,
                participantIds: participantIds,
                participants: participants,
                adminIds: adminIds,
                lastMessageText: lastMessageText,
                lastMessageSenderId: lastMessageSenderId,
                lastMessageSenderName: lastMessageSenderName,
                lastMessageTimestamp: lastMessageTimestamp,
                lastMessageType: lastMessageType,
                lastMessageTranslations: lastMessageTranslations,
                lastUpdatedAt: lastUpdatedAt,
                initiatedAt: initiatedAt,
                unreadCount: unreadCount,
                translationEnabled: translationEnabled,
                autoDetectLanguage: autoDetectLanguage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConversationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConversationsTable,
      ConversationEntity,
      $$ConversationsTableFilterComposer,
      $$ConversationsTableOrderingComposer,
      $$ConversationsTableAnnotationComposer,
      $$ConversationsTableCreateCompanionBuilder,
      $$ConversationsTableUpdateCompanionBuilder,
      (
        ConversationEntity,
        BaseReferences<_$AppDatabase, $ConversationsTable, ConversationEntity>,
      ),
      ConversationEntity,
      PrefetchHooks Function()
    >;
typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({
      required String id,
      required String conversationId,
      required String messageText,
      required String senderId,
      required DateTime timestamp,
      Value<String> messageType,
      Value<String> status,
      Value<String?> detectedLanguage,
      Value<String?> translations,
      Value<String?> replyTo,
      Value<String?> metadata,
      Value<String?> aiAnalysis,
      Value<String?> culturalHint,
      Value<String?> embedding,
      Value<String> syncStatus,
      Value<int> retryCount,
      Value<String?> tempId,
      Value<DateTime?> lastSyncAttempt,
      Value<int> rowid,
    });
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({
      Value<String> id,
      Value<String> conversationId,
      Value<String> messageText,
      Value<String> senderId,
      Value<DateTime> timestamp,
      Value<String> messageType,
      Value<String> status,
      Value<String?> detectedLanguage,
      Value<String?> translations,
      Value<String?> replyTo,
      Value<String?> metadata,
      Value<String?> aiAnalysis,
      Value<String?> culturalHint,
      Value<String?> embedding,
      Value<String> syncStatus,
      Value<int> retryCount,
      Value<String?> tempId,
      Value<DateTime?> lastSyncAttempt,
      Value<int> rowid,
    });

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageText => $composableBuilder(
    column: $table.messageText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageType => $composableBuilder(
    column: $table.messageType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detectedLanguage => $composableBuilder(
    column: $table.detectedLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get translations => $composableBuilder(
    column: $table.translations,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replyTo => $composableBuilder(
    column: $table.replyTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aiAnalysis => $composableBuilder(
    column: $table.aiAnalysis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get culturalHint => $composableBuilder(
    column: $table.culturalHint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get embedding => $composableBuilder(
    column: $table.embedding,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tempId => $composableBuilder(
    column: $table.tempId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageText => $composableBuilder(
    column: $table.messageText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageType => $composableBuilder(
    column: $table.messageType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detectedLanguage => $composableBuilder(
    column: $table.detectedLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get translations => $composableBuilder(
    column: $table.translations,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replyTo => $composableBuilder(
    column: $table.replyTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aiAnalysis => $composableBuilder(
    column: $table.aiAnalysis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get culturalHint => $composableBuilder(
    column: $table.culturalHint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get embedding => $composableBuilder(
    column: $table.embedding,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tempId => $composableBuilder(
    column: $table.tempId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get messageText => $composableBuilder(
    column: $table.messageText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get senderId =>
      $composableBuilder(column: $table.senderId, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get messageType => $composableBuilder(
    column: $table.messageType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get detectedLanguage => $composableBuilder(
    column: $table.detectedLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get translations => $composableBuilder(
    column: $table.translations,
    builder: (column) => column,
  );

  GeneratedColumn<String> get replyTo =>
      $composableBuilder(column: $table.replyTo, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<String> get aiAnalysis => $composableBuilder(
    column: $table.aiAnalysis,
    builder: (column) => column,
  );

  GeneratedColumn<String> get culturalHint => $composableBuilder(
    column: $table.culturalHint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get embedding =>
      $composableBuilder(column: $table.embedding, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tempId =>
      $composableBuilder(column: $table.tempId, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => column,
  );
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTable,
          MessageEntity,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (
            MessageEntity,
            BaseReferences<_$AppDatabase, $MessagesTable, MessageEntity>,
          ),
          MessageEntity,
          PrefetchHooks Function()
        > {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<String> messageText = const Value.absent(),
                Value<String> senderId = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String> messageType = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> detectedLanguage = const Value.absent(),
                Value<String?> translations = const Value.absent(),
                Value<String?> replyTo = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<String?> aiAnalysis = const Value.absent(),
                Value<String?> culturalHint = const Value.absent(),
                Value<String?> embedding = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> tempId = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion(
                id: id,
                conversationId: conversationId,
                messageText: messageText,
                senderId: senderId,
                timestamp: timestamp,
                messageType: messageType,
                status: status,
                detectedLanguage: detectedLanguage,
                translations: translations,
                replyTo: replyTo,
                metadata: metadata,
                aiAnalysis: aiAnalysis,
                culturalHint: culturalHint,
                embedding: embedding,
                syncStatus: syncStatus,
                retryCount: retryCount,
                tempId: tempId,
                lastSyncAttempt: lastSyncAttempt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String conversationId,
                required String messageText,
                required String senderId,
                required DateTime timestamp,
                Value<String> messageType = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> detectedLanguage = const Value.absent(),
                Value<String?> translations = const Value.absent(),
                Value<String?> replyTo = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<String?> aiAnalysis = const Value.absent(),
                Value<String?> culturalHint = const Value.absent(),
                Value<String?> embedding = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> tempId = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion.insert(
                id: id,
                conversationId: conversationId,
                messageText: messageText,
                senderId: senderId,
                timestamp: timestamp,
                messageType: messageType,
                status: status,
                detectedLanguage: detectedLanguage,
                translations: translations,
                replyTo: replyTo,
                metadata: metadata,
                aiAnalysis: aiAnalysis,
                culturalHint: culturalHint,
                embedding: embedding,
                syncStatus: syncStatus,
                retryCount: retryCount,
                tempId: tempId,
                lastSyncAttempt: lastSyncAttempt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTable,
      MessageEntity,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (
        MessageEntity,
        BaseReferences<_$AppDatabase, $MessagesTable, MessageEntity>,
      ),
      MessageEntity,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db, _db.conversations);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
}
