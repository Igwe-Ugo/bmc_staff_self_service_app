class UserModel {
  final String id;
  final String username;
  final String name;
  final String email;
  final String? image;
  final String initials;
  final List<String> privileges;
  final String? defaultDept;
  final String? personnelId;

  const UserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    this.image,
    required this.initials,
    required this.privileges,
    this.defaultDept,
    this.personnelId
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final firstName = (json['firstname'] as String? ?? '');
    final lastName  = (json['lastname']  as String? ?? '');
    final computed  = '${firstName.isNotEmpty ? firstName[0] : ''}'
        '${lastName.isNotEmpty  ? lastName[0]  : ''}'
        .toUpperCase();

    return UserModel(
      id:          json['id']?.toString()      ?? '',
      username:    json['username']  as String? ?? '',
      name:        json['name']      as String? ?? '',
      email:       json['email']     as String? ?? '',
      image:       json['image']     as String?,
      initials:    json['initials']  as String? ?? computed,
      privileges:  (json['privileges'] as List<dynamic>? ?? [])
          .map((p) => p.toString())
          .toList(),
      defaultDept: json['defaultDept'] as String?   // ← from API
          ?? json['default_dept']  as String?,
      personnelId: json['personnelId'] as String? ?? json['personnelId'] as String?
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
    'personnelId': personnelId
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
    String? personnelId,
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
        personnelId: personnelId ?? this.personnelId
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
