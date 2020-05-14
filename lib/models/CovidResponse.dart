


class CovidResponse {


  double _fatalityRate;
  int _confirmed;
  int _confirmedDiff;
  int _deaths;
  int _deathsDiff;
  int _recovered;
  int _recoveredDiff;
  int _active;
  int _activeDiff;
  String _date;
  String _lastUpdated;

  CovidResponse(
      {
      int confirmed,
      int confirmedDiff,
      int deaths,
      int deathsDiff,
      int recovered,
      int recoveredDiff,
      int active,
      int activeDiff,
      double fatalityRate,
      String lastUpdated,
      String date}) {

    this._confirmed = confirmed;
    this._confirmedDiff = confirmedDiff;
    this._deaths = deaths;
    this._deathsDiff = deathsDiff;
    this._recovered = recovered;
    this._recoveredDiff = recoveredDiff;
    this._active = active;
    this._activeDiff = activeDiff;
    this._fatalityRate = fatalityRate;
    this._lastUpdated = lastUpdated;
    this._date = date;
  }

  factory CovidResponse.fromJson(Map<String, dynamic> parsedJson) {
    return CovidResponse(
        confirmed: parsedJson['confirmed'],
        confirmedDiff: parsedJson['confirmed_diff'],
        deaths: parsedJson['deaths'],
        deathsDiff: parsedJson['deaths_diff'],
        recovered: parsedJson['recovered'],
        recoveredDiff: parsedJson['recovered_diff'],
        active: parsedJson['active'],
        activeDiff: parsedJson['active_diff'],
        fatalityRate: parsedJson['fatality_rate'].toDouble(),
        lastUpdated: parsedJson['last_updated'].toString(),
        date: parsedJson['date'].toString());
  }



  String get date => _date;

  int get active => _active;

  int get recovered => _recovered;

  int get deaths => _deaths;

  int get confirmed => _confirmed;

  double get fatalityRate => _fatalityRate;

  String get lastUpdated => _lastUpdated;

  int get activeDiff => _activeDiff;

  int get recoveredDiff => _recoveredDiff;

  int get deathsDiff => _deathsDiff;

  int get confirmedDiff => _confirmedDiff;

}


