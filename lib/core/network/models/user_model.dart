// user_model.dart
//
// Aligned with the tblUsers / qryUsers schema (profile_schema).

class Country {
  final String name;
  final String iso2;
  final List<String> states;

  const Country({required this.name, required this.iso2, required this.states});

  factory Country.fromJson(Map<String, dynamic> json) {
    final rawStates = (json['states'] as List<dynamic>? ?? []);
    return Country(
      name: json['name'] as String? ?? '',
      iso2: json['iso2'] as String? ?? '',
      states: rawStates
          .map((s) => (s as Map<String, dynamic>)['name'] as String? ?? '')
          .where((s) => s.isNotEmpty)
          .toList()
        ..sort(),
    );
  }
}

class UserModel {
  final String  id;
  final String  username;
  final String  name;        // computed display name (fullname fallback)
  final String  email;
  final String? image;       // avatar — base64 or URL
  final String  initials;
  final List<String> privileges;
  final String? defaultDept;
  final String? personnelId;

  // ── tblUsers fields ────────────────────────────────────────────────────────
  final String? firstname;
  final String? lastname;
  final String? fullname;
  final String? gender;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? telno;
  final String? rank;
  final String? profession;
  final String? status;
  final String? environment;
  final String? invitingDept;
  final bool?   doNotDisturb;
  final bool?   pseudonymised;
  final bool?   protectAccount;
  final bool?   active;
  final bool?   isSystemUser;
  final bool?   isDoc;
  final bool?   isAnaest;
  final bool?   isPhysio;
  final bool?   isNurse;
  final bool?   isMidwife;
  final bool?   isPharmacist;
  final bool?   isClinician;
  final String? notes;

  // ── qryUsers extended (joined) fields ─────────────────────────────────────
  final String? countryName;
  final String? stateName;
  final bool?   isActive;
  final String? deptName;
  final String? privilege;
  final bool?   hasPassword;
  final int?    deptUserCount;

  const UserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    this.image,
    required this.initials,
    required this.privileges,
    this.defaultDept,
    this.personnelId,
    this.firstname,
    this.lastname,
    this.fullname,
    this.gender,
    this.address,
    this.city,
    this.state,
    this.country,
    this.telno,
    this.rank,
    this.profession,
    this.status,
    this.environment,
    this.invitingDept,
    this.doNotDisturb,
    this.pseudonymised,
    this.protectAccount,
    this.active,
    this.isSystemUser,
    this.isDoc,
    this.isAnaest,
    this.isPhysio,
    this.isNurse,
    this.isMidwife,
    this.isPharmacist,
    this.isClinician,
    this.notes,
    this.countryName,
    this.stateName,
    this.isActive,
    this.deptName,
    this.privilege,
    this.hasPassword,
    this.deptUserCount,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final firstName = (json['firstname'] as String? ?? '');
    final lastName  = (json['lastname']  as String? ?? '');
    final computedInitials = '${firstName.isNotEmpty ? firstName[0] : ''}'
        '${lastName.isNotEmpty  ? lastName[0]  : ''}'
        .toUpperCase();

    final computedFullname = json['fullname'] as String? ??
        ('$firstName $lastName').trim();

    bool? toBool(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      if (v is int)  return v == 1;
      if (v is String) return v == '1' || v.toLowerCase() == 'true';
      return null;
    }

    return UserModel(
      id:          json['id']?.toString()       ?? '',
      username:    json['username']   as String? ?? '',
      name:        json['name']       as String? ?? computedFullname,
      email:       json['email']      as String? ?? '',
      image:       json['image']      as String?  ?? json['avatar'] as String?,
      initials:    json['initials']   as String?  ?? computedInitials,
      privileges:  (json['privileges'] as List<dynamic>? ?? [])
          .map((p) => p.toString())
          .toList(),
      defaultDept: json['defaultDept'] as String?
          ?? json['default_dept']   as String?,
      personnelId: json['personnelId'] as String?,

      firstname:   json['firstname']  as String?,
      lastname:    json['lastname']   as String?,
      fullname:    json['fullname']   as String? ?? computedFullname,
      gender:      json['gender']     as String?,
      address:     json['address']    as String?,
      city:        json['city']       as String?,
      state:       json['state']      as String?,
      country:     json['country']    as String?,
      telno:       json['telno']      as String?,
      rank:        json['rank']       as String?,
      profession:  json['profession'] as String?,
      status:      json['status']     as String?,
      environment: json['environment'] as String?,
      invitingDept: json['invitingDept'] as String?,
      doNotDisturb:   toBool(json['doNotDisturb']),
      pseudonymised:  toBool(json['pseudonymised']),
      protectAccount: toBool(json['protectAccount']),
      active:         toBool(json['active']),
      isSystemUser:   toBool(json['isSystemUser']),
      isDoc:          toBool(json['isDoc']),
      isAnaest:       toBool(json['isAnaest']),
      isPhysio:       toBool(json['isPhysio']),
      isNurse:        toBool(json['isNurse']),
      isMidwife:      toBool(json['isMidwife']),
      isPharmacist:   toBool(json['isPharmacist']),
      isClinician:    toBool(json['isClinician']),
      notes:          json['notes'] as String?,

      countryName:    json['countryName'] as String?,
      stateName:      json['stateName']   as String?,
      isActive:       toBool(json['isActive']),
      deptName:       json['deptName']    as String?,
      privilege:      json['privilege']   as String?,
      hasPassword:    json['hasPassword'] as bool?,
      deptUserCount:  json['deptUserCount'] is int
          ? json['deptUserCount'] as int
          : int.tryParse(json['deptUserCount']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id':          id,
    'username':    username,
    'name':        name,
    'email':       email,
    'image':       image,
    'initials':    initials,
    'privileges':  privileges,
    'defaultDept': defaultDept,
    'personnelId': personnelId,
    'firstname':   firstname,
    'lastname':    lastname,
    'fullname':    fullname,
    'gender':      gender,
    'address':     address,
    'city':        city,
    'state':       state,
    'country':     country,
    'telno':       telno,
    'rank':        rank,
    'profession':  profession,
    'status':      status,
    'environment': environment,
    'invitingDept': invitingDept,
    'doNotDisturb':   doNotDisturb,
    'pseudonymised':  pseudonymised,
    'protectAccount': protectAccount,
    'active':         active,
    'isSystemUser':   isSystemUser,
    'isDoc':          isDoc,
    'isAnaest':       isAnaest,
    'isPhysio':       isPhysio,
    'isNurse':        isNurse,
    'isMidwife':      isMidwife,
    'isPharmacist':   isPharmacist,
    'isClinician':    isClinician,
    'notes':          notes,
    'countryName':    countryName,
    'stateName':      stateName,
    'isActive':       isActive,
    'deptName':       deptName,
    'privilege':      privilege,
    'hasPassword':    hasPassword,
    'deptUserCount':  deptUserCount,
  };

  bool hasPrivilege(String privilege) => privileges.contains(privilege);

  /// Human-friendly clinical role label derived from the boolean role flags.
  String get clinicalRoleLabel {
    if (isDoc == true)        return 'Doctor';
    if (isAnaest == true)     return 'Anaesthetist';
    if (isPhysio == true)     return 'Physiotherapist';
    if (isNurse == true)      return 'Nurse';
    if (isMidwife == true)    return 'Midwife';
    if (isPharmacist == true) return 'Pharmacist';
    if (isClinician == true)  return 'Clinician';
    return profession ?? '';
  }

  UserModel copyWith({
    String?       id,
    String?       username,
    String?       name,
    String?       email,
    String?       image,
    String?       initials,
    List<String>? privileges,
    String?       defaultDept,
    String?       personnelId,
    String?       firstname,
    String?       lastname,
    String?       fullname,
    String?       gender,
    String?       address,
    String?       city,
    String?       state,
    String?       country,
    String?       telno,
    String?       rank,
    String?       profession,
    String?       status,
  }) =>
      UserModel(
        id:          id          ?? this.id,
        username:    username    ?? this.username,
        name:        name        ?? this.name,
        email:       email       ?? this.email,
        image:       image       ?? this.image,
        initials:    initials    ?? this.initials,
        privileges:  privileges  ?? this.privileges,
        defaultDept: defaultDept ?? this.defaultDept,
        personnelId: personnelId ?? this.personnelId,
        firstname:   firstname   ?? this.firstname,
        lastname:    lastname    ?? this.lastname,
        fullname:    fullname    ?? this.fullname,
        gender:      gender      ?? this.gender,
        address:     address     ?? this.address,
        city:        city        ?? this.city,
        state:       state       ?? this.state,
        country:     country     ?? this.country,
        telno:       telno       ?? this.telno,
        rank:        rank        ?? this.rank,
        profession:  profession  ?? this.profession,
        status:      status      ?? this.status,
        // pass-through unmutable extras
        environment:    environment,
        invitingDept:   invitingDept,
        doNotDisturb:   doNotDisturb,
        pseudonymised:  pseudonymised,
        protectAccount: protectAccount,
        active:         active,
        isSystemUser:   isSystemUser,
        isDoc:          isDoc,
        isAnaest:       isAnaest,
        isPhysio:       isPhysio,
        isNurse:        isNurse,
        isMidwife:      isMidwife,
        isPharmacist:   isPharmacist,
        isClinician:    isClinician,
        notes:          notes,
        countryName:    countryName,
        stateName:      stateName,
        isActive:       isActive,
        deptName:       deptName,
        privilege:      privilege,
        hasPassword:    hasPassword,
        deptUserCount:  deptUserCount,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UserModel && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'UserModel(id: $id, username: $username, name: $name, '
          'initials: $initials, defaultDept: $defaultDept)';
}

// ── Profile update form data ──────────────────────────────────────────────────
// PATCH /api/users/profile — { id, avatar, address, city, telno, state, country, password }

class UserProfileUpdateData {
  final String   id;        // required — identifies which user to update
  final String?  avatar;    // base64 string
  final String?  address;
  final String?  city;
  final String?  telno;
  final String?  state;
  final String?  country;
  final String?  password;

  const UserProfileUpdateData({
    required this.id,
    this.avatar,
    this.address,
    this.city,
    this.telno,
    this.state,
    this.country,
    this.password,
  });

  /// `id` is always sent. Other fields are only sent when non-null/non-empty
  /// so a partial save never wipes existing data on the server.
  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{'id': id};
    if (avatar   != null && avatar!.isNotEmpty)   m['avatar']   = avatar;
    if (address  != null && address!.isNotEmpty)  m['address']  = address;
    if (city     != null && city!.isNotEmpty)     m['city']     = city;
    if (telno    != null && telno!.isNotEmpty)    m['telno']    = telno;
    if (state    != null && state!.isNotEmpty)    m['state']    = state;
    if (country  != null && country!.isNotEmpty)  m['country']  = country;
    if (password != null && password!.isNotEmpty) m['password'] = password;
    return m;
  }
}
