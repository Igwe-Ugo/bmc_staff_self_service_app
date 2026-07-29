// ─── country_model.dart ────────────────────────────────────────────────────
//
// Models the response from GET /api/system-apis/world-countries:
//   { data: { countries: tblCountries[], states: tblStates[], lgas: tblLgas[] } }
//
// The backend sends inconsistent key casing depending on which query built
// each row (raw column name vs. DB alias), so every field is read
// defensively with a fallback chain, e.g. countryName ?? Country_Name.

class Country {
  final String name;
  final String iso2;
  final List<String> states;

  const Country({required this.name, required this.iso2, required this.states});

  /// Builds a single [Country] from one raw `tblCountries` row.
  /// Pass in the already-joined, sorted state names for this country —
  /// use [Country.buildDirectory] to construct the full list in one pass
  /// rather than calling this directly per-row.
  factory Country.fromApiRow(Map<String, dynamic> json, {List<String> states = const []}) {
    return Country(
      name: (json['countryName'] ?? json['Country_Name'] ?? '').toString().trim(),
      iso2: (json['countryIsoCode2'] ?? json['Country_ISOCode2'] ?? '').toString().trim(),
      states: states,
    );
  }

  /// Legacy/cache shape — some cached data may still be the old nested
  /// { name, iso2, states: [{name}] } format. Kept for backward compatibility
  /// so existing cached data doesn't crash on the next app launch.
  factory Country.fromJson(Map<String, dynamic> json) {
    final rawStates = (json['states'] as List<dynamic>? ?? []);
    return Country(
      name: (json['name'] ?? json['countryName'] ?? '').toString(),
      iso2: (json['iso2'] ?? json['countryIsoCode2'] ?? '').toString(),
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
      states: (json['states'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toCacheJson() => {
    'name': name,
    'iso2': iso2,
    'states': states,
  };

  /// Builds the full picker-ready country list — each with its states
  /// already joined, deduped, and sorted — from the raw
  /// `/api/system-apis/world-countries` payload:
  ///   { countries: tblCountries[], states: tblStates[], lgas: tblLgas[] }
  ///
  /// `lgas` isn't needed for a country/state picker and is intentionally
  /// ignored here — join it separately if you later add an LGA picker.
  static List<Country> buildDirectory(Map<String, dynamic> payload) {
    final rawCountries = (payload['countries'] as List<dynamic>? ?? []);
    final rawStates = (payload['states'] as List<dynamic>? ?? []);

    // Group state names by country ISO2 code first — O(1) lookup per
    // country afterward, instead of re-scanning the full states list
    // once per country.
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
