class Country {

  String _name;
  String _iso;


  Country({
    String name,
    String iso,
  }) {
    this._name = name;
    this._iso = iso;
  }

  factory Country.fromJson(Map<String, dynamic> parsedJson) {
    return Country(
      name: parsedJson['name'].toString(),
      iso: parsedJson['iso'].toString(),
    );
  }

  String get name => _name;

  String get iso => _iso;


}
