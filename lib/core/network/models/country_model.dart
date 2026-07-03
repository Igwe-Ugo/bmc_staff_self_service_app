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

  // add to Country class
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
}
