// user_model.dart

class UserModel {
  final String  id;
  final String  username;
  final String  name;
  final String  email;
  final String? image;        // base64 or URL avatar
  final String  initials;
  final List<String> privileges;
  final String? defaultDept;
  final String? personnelId;

  // ── Extended profile fields (from tblUsers) ───────────────────────────────
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
    // extended
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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final firstName = (json['firstname'] as String? ?? '');
    final lastName  = (json['lastname']  as String? ?? '');
    final computed  = '${firstName.isNotEmpty ? firstName[0] : ''}'
        '${lastName.isNotEmpty  ? lastName[0]  : ''}'
        .toUpperCase();

    return UserModel(
      id:          json['id']?.toString()       ?? '',
      username:    json['username']   as String? ?? '',
      name:        json['name']       as String? ?? '',
      email:       json['email']      as String? ?? '',
      image:       json['image']      as String?,
      initials:    json['initials']   as String? ?? computed,
      privileges:  (json['privileges'] as List<dynamic>? ?? [])
          .map((p) => p.toString())
          .toList(),
      defaultDept: json['defaultDept'] as String?
          ?? json['default_dept']   as String?,
      personnelId: json['personnelId'] as String?,
      // extended
      firstname:   json['firstname']  as String?,
      lastname:    json['lastname']   as String?,
      fullname:    json['fullname']   as String?,
      gender:      json['gender']     as String?,
      address:     json['address']    as String?,
      city:        json['city']       as String?,
      state:       json['state']      as String?,
      country:     json['country']    as String?,
      telno:       json['telno']      as String?,
      rank:        json['rank']       as String?,
      profession:  json['profession'] as String?,
      status:      json['status']     as String?,
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
  };

  bool hasPrivilege(String privilege) => privileges.contains(privilege);

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
// Only the fields the PATCH /api/users/profile endpoint accepts.

class UserProfileUpdateData {
  final String?  id;
  final String?  avatar;   // base64 string
  final String?  address;
  final String?  city;
  final String?  telno;
  final String?  state;
  final String?  country;
  final String?  password;

  const UserProfileUpdateData({
    this.id,
    this.avatar,
    this.address,
    this.city,
    this.telno,
    this.state,
    this.country,
    this.password,
  });

  /// Only sends non-null fields so we never accidentally wipe data.
  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    m['id']   = id;
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
