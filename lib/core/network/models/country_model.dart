class Country {
  final String name;
  final String iso2;
  final String dialCode;
  final List<String> states;

  const Country({
    required this.name,
    required this.iso2,
    required this.dialCode,
    required this.states,
  });

  /// Builds a single [Country] from one raw `tblCountries` row.
  factory Country.fromApiRow(Map<String, dynamic> json, {List<String> states = const []}) {
    // Standardize dial code with a leading '+' sign
    final rawCode = (json['intTelCode1'] ?? json['IntTelCode1'] ?? '').toString().trim();
    final formattedDialCode = rawCode.isNotEmpty
        ? (rawCode.startsWith('+') ? rawCode : '+$rawCode')
        : '';

    return Country(
      name: (json['countryName'] ?? json['Country_Name'] ?? '').toString().trim(),
      iso2: (json['countryIsoCode2'] ?? json['Country_ISOCode2'] ?? '').toString().trim(),
      dialCode: formattedDialCode,
      states: states,
    );
  }

  factory Country.fromJson(Map<String, dynamic> json) {
    final rawStates = (json['states'] as List<dynamic>? ?? []);
    final rawCode = (json['dialCode'] ?? json['intTelCode1'] ?? '').toString().trim();
    final formattedDialCode = rawCode.isNotEmpty
        ? (rawCode.startsWith('+') ? rawCode : '+$rawCode')
        : '';

    return Country(
      name: (json['name'] ?? json['countryName'] ?? '').toString(),
      iso2: (json['iso2'] ?? json['countryIsoCode2'] ?? '').toString(),
      dialCode: formattedDialCode,
      states: rawStates
          .map((s) => s is Map<String, dynamic> ? (s['name'] as String? ?? '') : s.toString())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList()
        ..sort(),
    );
  }

  factory Country.fromCache(Map<String, dynamic> json) {
    return Country(
      name: json['name'] as String? ?? '',
      iso2: json['iso2'] as String? ?? '',
      dialCode: json['dialCode'] as String? ?? '',
      states: (json['states'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toCacheJson() => {
    'name': name,
    'iso2': iso2,
    'dialCode': dialCode,
    'states': states,
  };

  static List<Country> buildDirectory(Map<String, dynamic> payload) {
    final rawCountries = (payload['countries'] as List<dynamic>? ?? []);
    final rawStates = (payload['states'] as List<dynamic>? ?? []);

    final statesByCountryCode = <String, Set<String>>{};
    for (final s in rawStates) {
      final row = s as Map<String, dynamic>;
      final code = (row['countryCd'] ?? row['CountryCd'] ?? row['country'] ?? '')
          .toString()
          .trim()
          .toUpperCase();
      final stateName = (row['stateName'] ?? row['StateName'] ?? row['state'] ?? '')
          .toString()
          .trim();
      if (code.isEmpty || stateName.isEmpty) continue;
      statesByCountryCode.putIfAbsent(code, () => <String>{}).add(stateName);
    }

    final countries = rawCountries.map((c) {
      final row = c as Map<String, dynamic>;
      final iso2 = (row['countryIsoCode2'] ?? row['Country_ISOCode2'] ?? '')
          .toString()
          .trim()
          .toUpperCase();
      final states = (statesByCountryCode[iso2] ?? <String>{}).toList()..sort();
      return Country.fromApiRow(row, states: states);
    }).where((c) => c.name.isNotEmpty).toList();

    countries.sort((a, b) => a.name.compareTo(b.name));
    return countries;
  }
}
