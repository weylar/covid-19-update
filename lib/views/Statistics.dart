import 'dart:convert';

import 'package:covidtracker/analytics/FirebaseAnalyticsHelper.dart';
import 'package:covidtracker/helper/Common.dart';
import 'package:covidtracker/models/CovidResponse.dart';
import 'package:covidtracker/util/Constant.dart';
import 'package:covidtracker/views/widgets/BucketingAxisScatterPlotChart.dart';
import 'package:covidtracker/views/widgets/TimeSeriesBar.dart';
import 'package:cupertino_tabbar/cupertino_tabbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_money_formatter/flutter_money_formatter.dart';
import 'package:http/http.dart' as http;
import 'package:loading/indicator/ball_pulse_indicator.dart';
import 'package:loading/loading.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Statistics extends StatefulWidget {
  Statistics({Key key}) : super(key: key);

  @override
  _Statistics createState() => _Statistics();
}

class _Statistics extends State<Statistics> {
  int countryPosition = 0;
  int timePosition = 0;

  int _getCountryPosition() => countryPosition;

  int _getTimePosition() => timePosition;
  Future<List<CovidResponse>> _responseTotalLocal;
  Future<CovidResponse> _responseTotalGlobal;
  Future<List<Map<String, dynamic>>> _responseConfirmed7DaysDiff;

  @override
  void initState() {
    super.initState();
    FirebaseAnalyticsHelper.setCurrentScreen("Statistics", "Statistics class");
    _responseTotalLocal = fetchStatisticsTotalLocal();
    _responseTotalGlobal = _fetchStatisticsTotalGlobal();
    _responseConfirmed7DaysDiff = _fetchStatisticsTotalLocal7daysBack();
    SchedulerBinding.instance
        .addPostFrameCallback((_) => Common.showNoNetworkDialog(context));
  }

  Future<List<CovidResponse>> fetchStatisticsTotalLocal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String country = await getCountry();
    var response =
        await http.get(Constant.COUNTRY_COVID_API + country, headers: {
      "x-rapidapi-key": Constant.API_KEY_STATISTICS,
      "x-rapidapi-host": Constant.HOST_STATISTICS
    });
    if (response.statusCode == 200) {
      final List parsed = json.decode(response.body)['data'];
      var result = parsed.map((val) => CovidResponse.fromJson(val)).toList();
      prefs.setString("last_day_fetched", result[0].date);
      return result;
    } else {
      return List();
    }
  }

  static Future<String> getCountry() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var country = prefs.getString('country');
    return country;
  }

  _saveGraphData(String data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("graph_data", data);
  }

  Future<String> _getGraphData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var graphData = prefs.getString('graph_data');

    return graphData;
  }

  Future<List<Map<String, dynamic>>>
      _fetchStatisticsTotalLocal7daysBack() async {
    String country = await getCountry();
    var header = {
      "x-rapidapi-key": Constant.API_KEY_STATISTICS,
      "x-rapidapi-host": Constant.HOST_STATISTICS
    };

    if (await _getGraphData() != null) {
      var data = await _getGraphData();
      var list = jsonDecode(data);
      var dayDiff = DateTime.now().day - DateTime.parse(list.first["date"]).day;
      for (int i = 1; i < dayDiff; i++) {
        var date = DateTime.now().subtract(Duration(days: i)).toIso8601String();
        var response = await http.get(
            Constant.COUNTRY_COVID_API +
                country +
                "&date=" +
                date.split("T")[0],
            headers: header);
        if (response.statusCode == 200) {
          final List parsed = json.decode(response.body)['data'];
          if (parsed.isNotEmpty) {
            var result = CovidResponse.fromJson(parsed.first);
            if (DateTime.parse(result.date)
                .isAfter(DateTime.parse(list.first["date"]))) {
              list.insert(0,
                  {"date": result.date, "confirmedDiff": result.confirmedDiff});
              list.removeLast();
              _saveGraphData(json.encode(list));
            }
          }
        } else {
          list.add({});
        }
      }

      return list.cast<Map<String, dynamic>>();
    } else {
      var list = List<Map<String, dynamic>>();
      for (int i = 1; i < 16; i++) {
        var date = DateTime.now().subtract(Duration(days: i)).toIso8601String();
        var response = await http.get(
            Constant.COUNTRY_COVID_API +
                country +
                "&date=" +
                date.split("T")[0],
            headers: header);
        if (response.statusCode == 200) {
          final List parsed = json.decode(response.body)['data'];
          if (parsed.isNotEmpty) {
            var result = CovidResponse.fromJson(parsed.first);
            list.add(
                {"date": result.date, "confirmedDiff": result.confirmedDiff});
          }
        } else {
          list.add({});
        }
      }
      _saveGraphData(json.encode(list));
      print(list.toString());
      return list;
    }
  }

  Future<CovidResponse> _fetchStatisticsTotalGlobal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var response = await http.get(Constant.GLOBAL_COVID_API, headers: {
      "x-rapidapi-key": Constant.API_KEY_STATISTICS,
      "x-rapidapi-host": Constant.HOST_STATISTICS
    });
    if (response.statusCode == 200) {
      var result = CovidResponse.fromJson(json.decode(response.body)['data']);
      prefs.setString("last_day_global_fetched", result.date);
      return result;
    } else {
      return CovidResponse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            color: Colors.deepPurple,
            child: SingleChildScrollView(
                child: Column(
              children: <Widget>[
                Padding(
                    padding: const EdgeInsets.only(
                        left: 16.0, right: 16.0, bottom: 32.0),
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              "Statistics",
                              style: TextStyle(
                                  fontSize: 24.0,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.0),
                        _buildCountryTab(),
                        SizedBox(height: 8.0),
                        _buildTimeTab(),
                        SizedBox(height: 8.0),
                        _getTimePosition() == 0
                            ? _buildResultBlock(0, _responseTotalLocal)
                            : _getTimePosition() == 1
                                ? _buildResultBlock(1, _responseTotalLocal)
                                : _buildResultBlock(2, _responseTotalLocal),
                        SizedBox(
                          height: 4.0,
                        ),
                      ],
                    )),
                _getCountryPosition() == 0
                    ? _buildGraphReportLocal(_responseConfirmed7DaysDiff)
                    : _buildGraphReportGlobal(_responseTotalLocal),
              ],
            ))));
  }

  Widget _buildGraphReportLocal(Future<List<Map<String, dynamic>>> response) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.0), topRight: Radius.circular(16.0))),
      child: Padding(
        padding: const EdgeInsets.only(
            top: 32.0, left: 16.0, right: 16.0, bottom: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      "Daily New Cases",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Last 2 Weeks",
                      textAlign: TextAlign.left,
                      style: TextStyle(),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
                height: MediaQuery.of(context).size.height * 0.3,
                width: MediaQuery.of(context).size.width,
                child: Container(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: response, // a Future<String> or null
                    builder: (BuildContext context,
                        AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.waiting:
                          return Center(
                              child:
                                  Text("Please wait while computing graph..."));
                        default:
                          if (snapshot.hasError) {
                            return TimeSeriesBar.withSampleData(
                                new List<CovidUpdate>());
                          } else {
                            var data = snapshot.data.reversed.toList();
                            var result = data
                                .asMap()
                                .map((index, response) => MapEntry(
                                    index,
                                    CovidUpdate(
                                        DateTime.parse(response['date']),
                                        response["confirmedDiff"])))
                                .values
                                .toList();
                            return TimeSeriesBar.withSampleData(result);
                          }
                      }
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphReportGlobal(Future<List<CovidResponse>> response) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.0), topRight: Radius.circular(16.0))),
      child: Padding(
        padding: const EdgeInsets.only(
            top: 32.0, left: 16.0, right: 16.0, bottom: 16.0),
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      "Global Population Impact (%)",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getTimePosition() == 0
                          ? "All Time"
                          : _getTimePosition() == 1 ? "Today" : "Yesterday",
                      textAlign: TextAlign.left,
                      style: TextStyle(),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
                height: MediaQuery.of(context).size.height * 0.3,
                width: MediaQuery.of(context).size.width,
                child: FutureBuilder<CovidResponse>(
                  future: _responseTotalGlobal, // a Future<String> or null
                  builder: (BuildContext context,
                      AsyncSnapshot<CovidResponse> snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                        return TimeSeriesBar.withSampleData(
                            new List<CovidUpdate>());
                      default:
                        if (snapshot.hasError) {
                          return TimeSeriesBar.withSampleData(
                              new List<CovidUpdate>());
                        } else {
                          return BucketingAxisScatterPlotChart.withSampleData(
                              _getTimePosition() == 0
                                  ? snapshot.data.confirmed
                                  : snapshot.data.confirmedDiff,
                              _getTimePosition() == 0
                                  ? snapshot.data.deaths
                                  : snapshot.data.deathsDiff,
                              _getTimePosition() == 0
                                  ? snapshot.data.recovered
                                  : snapshot.data.recoveredDiff,
                              _getTimePosition() == 0
                                  ? snapshot.data.active
                                  : snapshot.data.activeDiff);
                        }
                    }
                  },
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildResultBlock(int pos, Future<List<CovidResponse>> response) {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width * 0.43,
              decoration: BoxDecoration(
                  color: Colors.orangeAccent,
                  borderRadius: BorderRadius.all(Radius.circular(8.0))),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        child: Text(
                          "Affected",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 30.0,
                    ),
                    _getCountryPosition() == 0
                        ? FutureBuilder<List<CovidResponse>>(
                            future: response, // a Future<String> or null
                            builder: (BuildContext context,
                                AsyncSnapshot<List<CovidResponse>> snapshot) {
                              switch (snapshot.connectionState) {
                                case ConnectionState.waiting:
                                  return Loading(
                                      indicator: BallPulseIndicator(),
                                      size: 40.0,
                                      color: Colors.white);
                                default:
                                  if (snapshot.hasError ||
                                      snapshot.data.length < 1) {
                                    return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                            child: Text('0',
                                                style: TextStyle(
                                                    fontSize: 22.0,
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                                textAlign: TextAlign.left)));
                                  } else {
                                    var fmf = FlutterMoneyFormatter(
                                        amount: pos == 0
                                            ? snapshot.data.fold(
                                                0,
                                                (value, element) =>
                                                    value +
                                                    element.confirmed
                                                        .toDouble())
                                            : pos == 1
                                                ? -1
                                                : (snapshot.data.fold(
                                                    0,
                                                    (value, element) =>
                                                        value +
                                                        element.confirmedDiff
                                                            .toDouble())));

                                    return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                            child: Text(_processTextResult(fmf),
                                                style: TextStyle(
                                                    fontSize:
                                                        _processFontSize(fmf),
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                                textAlign: TextAlign.left)));
                                  }
                              }
                            },
                          )
                        : FutureBuilder<CovidResponse>(
                            future: _responseTotalGlobal,
                            builder: (BuildContext context,
                                AsyncSnapshot<CovidResponse> snapshot) {
                              switch (snapshot.connectionState) {
                                case ConnectionState.waiting:
                                  return Loading(
                                      indicator: BallPulseIndicator(),
                                      size: 40.0,
                                      color: Colors.white);
                                default:
                                  if (snapshot.hasError) {
                                    return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                            child: Text('0',
                                                style: TextStyle(
                                                    fontSize: 22.0,
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                                textAlign: TextAlign.left)));
                                  } else {
                                    var fmf = FlutterMoneyFormatter(
                                        amount: pos == 0
                                            ? snapshot.data.confirmed.toDouble()
                                            : pos == 1
                                                ? -1
                                                : snapshot.data.confirmedDiff
                                                    .toDouble());
                                    return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                            child: Text(_processTextResult(fmf),
                                                style: TextStyle(
                                                    fontSize:
                                                        _processFontSize(fmf),
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                                textAlign: TextAlign.left)));
                                  }
                              }
                            },
                          )
                  ],
                ),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width * 0.43,
              decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.all(Radius.circular(8.0))),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        child: Text(
                          "Death",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 30.0,
                    ),
                    _getCountryPosition() == 0
                        ? FutureBuilder<List<CovidResponse>>(
                            future: response, // a Future<String> or null
                            builder: (BuildContext context,
                                AsyncSnapshot<List<CovidResponse>> snapshot) {
                              switch (snapshot.connectionState) {
                                case ConnectionState.waiting:
                                  return Loading(
                                      indicator: BallPulseIndicator(),
                                      size: 40.0,
                                      color: Colors.white);
                                default:
                                  if (snapshot.hasError ||
                                      snapshot.data.length < 1) {
                                    return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                            child: Text('0',
                                                style: TextStyle(
                                                    fontSize: 22.0,
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                                textAlign: TextAlign.left)));
                                  } else {
                                    var fmf = FlutterMoneyFormatter(
                                        amount: pos == 0
                                            ? snapshot.data.fold(
                                                0,
                                                (value, element) =>
                                                    value +
                                                    element.deaths.toDouble())
                                            : pos == 1
                                                ? -1
                                                : snapshot.data.fold(
                                                    0,
                                                    (value, element) =>
                                                        value +
                                                        element.deathsDiff
                                                            .toDouble()));
                                    return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                            child: Text(_processTextResult(fmf),
                                                style: TextStyle(
                                                    fontSize:
                                                        _processFontSize(fmf),
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                                textAlign: TextAlign.left)));
                                  }
                              }
                            },
                          )
                        : FutureBuilder<CovidResponse>(
                            future: _responseTotalGlobal,
                            // a Future<String> or null
                            builder: (BuildContext context,
                                AsyncSnapshot<CovidResponse> snapshot) {
                              switch (snapshot.connectionState) {
                                case ConnectionState.waiting:
                                  return Loading(
                                      indicator: BallPulseIndicator(),
                                      size: 40.0,
                                      color: Colors.white);
                                default:
                                  if (snapshot.hasError) {
                                    return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                            child: Text('0',
                                                style: TextStyle(
                                                    fontSize: 22.0,
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                                textAlign: TextAlign.left)));
                                  } else {
                                    var fmf = FlutterMoneyFormatter(
                                        amount: pos == 0
                                            ? snapshot.data.deaths.toDouble()
                                            : pos == 1
                                                ? -1
                                                : snapshot.data.deathsDiff
                                                    .toDouble());
                                    return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                            child: Text(_processTextResult(fmf),
                                                style: TextStyle(
                                                    fontSize:
                                                        _processFontSize(fmf),
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                                textAlign: TextAlign.left)));
                                  }
                              }
                            },
                          )
                  ],
                ),
              ),
            )
          ],
        ),
        SizedBox(
          height: 12.0,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width * 0.28,
              decoration: BoxDecoration(
                  color: Colors.lightGreen,
                  borderRadius: BorderRadius.all(Radius.circular(8.0))),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        child: Text(
                          "Recovered",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 30.0,
                    ),
                    _getCountryPosition() == 0
                        ? FutureBuilder<List<CovidResponse>>(
                            future: response, // a Future<String> or null
                            builder: (BuildContext context,
                                AsyncSnapshot<List<CovidResponse>> snapshot) {
                              switch (snapshot.connectionState) {
                                case ConnectionState.waiting:
                                  return Loading(
                                      indicator: BallPulseIndicator(),
                                      size: 40.0,
                                      color: Colors.white);
                                default:
                                  if (snapshot.hasError ||
                                      snapshot.data.length < 1) {
                                    return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                            child: Text('0',
                                                style: TextStyle(
                                                    fontSize: 22.0,
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                                textAlign: TextAlign.left)));
                                  } else {
                                    var fmf = FlutterMoneyFormatter(
                                        amount: pos == 0
                                            ? snapshot.data.fold(
                                                0,
                                                (value, element) =>
                                                    value +
                                                    element.recovered
                                                        .toDouble())
                                            : pos == 1
                                                ? -1
                                                : (snapshot.data.fold(
                                                    0,
                                                    (value, element) =>
                                                        value +
                                                        element.recoveredDiff
                                                            .toDouble())));
                                    return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                            child: Text(_processTextResult(fmf),
                                                style: TextStyle(
                                                    fontSize:
                                                        _processFontSize(fmf),
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                                textAlign: TextAlign.left)));
                                  }
                              }
                            },
                          )
                        : FutureBuilder<CovidResponse>(
                            future: _responseTotalGlobal,
                            // a Future<String> or null
                            builder: (BuildContext context,
                                AsyncSnapshot<CovidResponse> snapshot) {
                              switch (snapshot.connectionState) {
                                case ConnectionState.waiting:
                                  return Loading(
                                      indicator: BallPulseIndicator(),
                                      size: 40.0,
                                      color: Colors.white);
                                default:
                                  if (snapshot.hasError) {
                                    return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                            child: Text('0',
                                                style: TextStyle(
                                                    fontSize: 22.0,
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                                textAlign: TextAlign.left)));
                                  } else {
                                    var fmf = FlutterMoneyFormatter(
                                        amount: pos == 0
                                            ? snapshot.data.recovered.toDouble()
                                            : pos == 1
                                                ? -1
                                                : (snapshot.data.recoveredDiff
                                                    .toDouble()));
                                    return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                            child: Text(_processTextResult(fmf),
                                                style: TextStyle(
                                                    fontSize:
                                                        _processFontSize(fmf),
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                                textAlign: TextAlign.left)));
                                  }
                              }
                            },
                          )
                  ],
                ),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width * 0.28,
              decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.all(Radius.circular(8.0))),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        child: Text(
                          "Active",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 30.0,
                    ),
                    _getCountryPosition() == 0
                        ? FutureBuilder<List<CovidResponse>>(
                            future: response, // a Future<String> or null
                            builder: (BuildContext context,
                                AsyncSnapshot<List<CovidResponse>> snapshot) {
                              switch (snapshot.connectionState) {
                                case ConnectionState.waiting:
                                  return Loading(
                                      indicator: BallPulseIndicator(),
                                      size: 40.0,
                                      color: Colors.white);
                                default:
                                  if (snapshot.hasError ||
                                      snapshot.data.length < 1) {
                                    return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                            child: Text('0',
                                                style: TextStyle(
                                                    fontSize: 22.0,
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                                textAlign: TextAlign.left)));
                                  } else {
                                    var fmf = FlutterMoneyFormatter(
                                        amount: pos == 0
                                            ? snapshot.data.fold(
                                                0,
                                                (value, element) =>
                                                    value +
                                                    element.active.toDouble())
                                            : pos == 1
                                                ? -1
                                                : snapshot.data.fold(
                                                    0,
                                                    (value, element) =>
                                                        value +
                                                        element.activeDiff
                                                            .toDouble()));
                                    return snapshot.data.length > 0
                                        ? Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                                child: Text(
                                                    _processTextResult(fmf),
                                                    style: TextStyle(
                                                        fontSize:
                                                            _processFontSize(
                                                                fmf),
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                    textAlign: TextAlign.left)))
                                        : Align();
                                  }
                              }
                            },
                          )
                        : FutureBuilder<CovidResponse>(
                            future: _responseTotalGlobal,
                            // a Future<String> or null
                            builder: (BuildContext context,
                                AsyncSnapshot<CovidResponse> snapshot) {
                              switch (snapshot.connectionState) {
                                case ConnectionState.waiting:
                                  return Loading(
                                      indicator: BallPulseIndicator(),
                                      size: 40.0,
                                      color: Colors.white);
                                default:
                                  if (snapshot.hasError) {
                                    return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                            child: Text('0',
                                                style: TextStyle(
                                                    fontSize: 22.0,
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                                textAlign: TextAlign.left)));
                                  } else {
                                    var fmf = FlutterMoneyFormatter(
                                        amount: pos == 0
                                            ? snapshot.data.active.toDouble()
                                            : pos == 1
                                                ? -1
                                                : snapshot.data.activeDiff
                                                    .toDouble());
                                    return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                            child: Text(_processTextResult(fmf),
                                                style: TextStyle(
                                                    fontSize:
                                                        _processFontSize(fmf),
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                                textAlign: TextAlign.left)));
                                  }
                              }
                            },
                          )
                  ],
                ),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width * 0.28,
              decoration: BoxDecoration(
                  color: Colors.purpleAccent,
                  borderRadius: BorderRadius.all(Radius.circular(8.0))),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        child: Text(
                          "Fatality Rate",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 30.0,
                    ),
                    _getCountryPosition() == 0
                        ? FutureBuilder<List<CovidResponse>>(
                            future: response, // a Future<String> or null
                            builder: (BuildContext context,
                                AsyncSnapshot<List<CovidResponse>> snapshot) {
                              switch (snapshot.connectionState) {
                                case ConnectionState.waiting:
                                  return Loading(
                                      indicator: BallPulseIndicator(),
                                      size: 40.0,
                                      color: Colors.white);
                                default:
                                  if (snapshot.hasError ||
                                      snapshot.data.length < 1) {
                                    return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                            child: Text('0',
                                                style: TextStyle(
                                                    fontSize: 22.0,
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                                textAlign: TextAlign.left)));
                                  } else {
                                    return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                            child: Text(
                                                (snapshot.data.fold(
                                                            0,
                                                            (value, element) =>
                                                                value +
                                                                element
                                                                    .fatalityRate) /
                                                        (snapshot.data.length))
                                                    .toStringAsFixed(4),
                                                style: TextStyle(
                                                    fontSize: 16.0,
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                                textAlign: TextAlign.left)));
                                  }
                              }
                            },
                          )
                        : FutureBuilder<CovidResponse>(
                            future:
                                _responseTotalGlobal, // a Future<String> or null
                            builder: (BuildContext context,
                                AsyncSnapshot<CovidResponse> snapshot) {
                              switch (snapshot.connectionState) {
                                case ConnectionState.waiting:
                                  return Loading(
                                      indicator: BallPulseIndicator(),
                                      size: 40.0,
                                      color: Colors.white);
                                default:
                                  if (snapshot.hasError) {
                                    return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                            child: Text('0',
                                                style: TextStyle(
                                                    fontSize: 22.0,
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                                textAlign: TextAlign.left)));
                                  } else {
                                    return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                            child: Text(
                                                snapshot.data.fatalityRate
                                                    .toString(),
                                                style: TextStyle(
                                                    fontSize: 16.0,
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                                textAlign: TextAlign.left)));
                                  }
                              }
                            },
                          )
                  ],
                ),
              ),
            )
          ],
        )
      ],
    );
  }

  String _processTextResult(FlutterMoneyFormatter fmf) {
    return fmf.output.withoutFractionDigits == "-1"
        ? "Processing..."
        : fmf.output.withoutFractionDigits;
  }

  double _processFontSize(FlutterMoneyFormatter fmf) {
    return fmf.output.withoutFractionDigits == "-1" ? 16.0 : 18.0;
  }

  Widget _buildCountryTab() {
    return CupertinoTabBar(
      Colors.white10,
      Colors.white,
      [
        Text(
          "My Country",
          style: TextStyle(
            color: countryPosition == 0 ? Colors.black : Colors.white,
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          "Global",
          style: TextStyle(
            color: countryPosition == 1 ? Colors.black : Colors.white,
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
      _getCountryPosition,
      (int index) {
        setState(() {
          countryPosition = index;
        });
      },
      horizontalPadding: 16,
      borderRadius: BorderRadius.all(Radius.circular(25.0)),
    );
  }

  Widget _buildTimeTab() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.5,
      child: Center(
        child: CupertinoTabBar(
          Colors.transparent,
          Colors.transparent,
          [
            Text(
              "Total",
              style: TextStyle(
                color: timePosition == 0 ? Colors.white : Colors.white60,
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              "Today",
              style: TextStyle(
                color: timePosition == 1 ? Colors.white : Colors.white60,
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              "Yesterday",
              style: TextStyle(
                color: timePosition == 2 ? Colors.white : Colors.white60,
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          _getTimePosition,
          (int index) {
            setState(() {
              timePosition = index;
            });
          },
        ),
      ),
    );
  }
}
