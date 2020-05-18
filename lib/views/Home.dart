import 'dart:convert';

import 'package:covidtracker/analytics/FirebaseAnalyticsHelper.dart';
import 'package:covidtracker/helper/Common.dart';
import 'package:covidtracker/models/Country.dart';
import 'package:covidtracker/util/Constant.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:loading/indicator/ball_pulse_indicator.dart';
import 'package:loading/loading.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage._privateConstructor();

  static final MyHomePage instance = MyHomePage._privateConstructor();

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<List<Country>> _countries;
  String _selectedCountry;

  @override
  void initState() {
    super.initState();
    FirebaseAnalyticsHelper.setCurrentScreen("Home", "Home class");
    _getSavedCountry();
    _countries = _fetchAllCountries();
    SchedulerBinding.instance
        .addPostFrameCallback((_) => Common.showNoNetworkDialog(context));
  }

  _getSavedCountry() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var country = prefs.getString('country');
    var countryIso = prefs.getString('country_iso');
    if (!prefs.containsKey('country')) {
      _saveCountry("Nigeria", "NGA");
      _selectedCountry = "Nigeria";
    } else {
      _saveCountry(country, countryIso);
      _selectedCountry = country;
    }
  }

  _saveCountry(String country, String iso) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('country', country);
    await prefs.setString('country_iso', iso);
  }

  _cacheAllCountries(String allCountries) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('all_country', allCountries);
  }

  Future<String> _readCachedCountries() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('all_country');
  }

  Future<List<Country>> _fetchAllCountries() async {
    var allCountries = await _readCachedCountries();
    if (allCountries != null) {
      var result = json.decode(allCountries) as List;
      var raw = result.map((val) => Country.fromJson(val)).toList();
      raw.sort((a, b) {
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return raw;
    } else {
      var response = await http.get(Constant.ALL_COUNTRY_API, headers: {
        "x-rapidapi-key": Constant.API_KEY_STATISTICS,
        "x-rapidapi-host": Constant.HOST_STATISTICS
      });
      if (response.statusCode == 200) {
        final List parsed = json.decode(response.body)['data'];
        _cacheAllCountries(json.encode(parsed));
        var raw = parsed.map((val) => Country.fromJson(val)).toList();
        raw.sort((a, b) {
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        return raw;
      } else {
        return List();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            child: SingleChildScrollView(
                child: Column(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            color: Colors.deepPurple,
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40.0),
                bottomRight: Radius.circular(40.0)),
          ),
          child: Column(
            children: <Widget>[
              Padding(
                  padding: const EdgeInsets.only(
                      left: 16.0, right: 16.0, bottom: 32.0),
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        height: 8.0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            "Covid-19",
                            style: TextStyle(
                                fontSize: 28.0,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          _buildDropDownCountry(_countries)
                        ],
                      ),
                      SizedBox(
                        height: 28.0,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          child: Text(
                            "Are you feeling sick?",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                                color: Colors.white,
                                letterSpacing: 1.0,
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 8.0,
                      ),
                      Text(
                          "If you feel sick with any of covid-19 symptoms,"
                          " please call or SMS your country's health body "
                          "for help.",
                          style: TextStyle(
                            letterSpacing: 0.4,
                            color: Colors.white,
                          )),
                      SizedBox(
                        height: 24.0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                              child: Container(
                            decoration: ShapeDecoration(
                                color: Colors.deepOrange,
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                      width: 0.0, style: BorderStyle.none),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50.0)),
                                )),
                            child: FlatButton.icon(
                                onPressed: () => _call("tel:080097000010"),
                                icon: Icon(
                                  Icons.call,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  "Call Now",
                                  style: TextStyle(color: Colors.white),
                                )),
                          )),
                          SizedBox(
                            width: 8.0,
                          ),
                          Expanded(
                              child: Container(
                            decoration: ShapeDecoration(
                                color: Colors.blueAccent,
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                      width: 0.0, style: BorderStyle.none),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50.0)),
                                )),
                            child: FlatButton.icon(
                                onPressed: () => _sms("sms:+2348099555577"),
                                icon: Icon(
                                  Icons.textsms,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  "Send SMS",
                                  style: TextStyle(color: Colors.white),
                                )),
                          ))
                        ],
                      )
                    ],
                  )),
            ],
          ),
        ),
        _buildPrevention(),
        _buildTest(),
      ],

      // This trailing comma makes auto-formatting nicer for build methods.
    ))));
  }

  _call(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }

  _sms(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }

  Widget _buildTest() {
    return GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/covid-test');
        },
        child: Container(
          margin: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.withOpacity(0.8), Colors.deepPurple],
                stops: [0.0, 0.7],
              ),
              color: Colors.deepPurple.withOpacity(0.8),
              borderRadius: BorderRadius.all(Radius.circular(24.0))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              SizedBox(
                  height: MediaQuery.of(context).size.width * 0.3,
                  width: MediaQuery.of(context).size.width * 0.3,
                  child: SvgPicture.asset('assets/images/self_test.svg',
                      semanticsLabel: "Do your own test")),
              Container(
                width: MediaQuery.of(context).size.width * 0.6,
                child: Column(
                  children: <Widget>[
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Do your own test!",
                          textAlign: TextAlign.left,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold),
                        )),
                    SizedBox(
                      height: 4.0,
                    ),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Follow the instructions to do your own test.",
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ))
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildPrevention() {
    return Padding(
      padding:
          EdgeInsets.only(left: 16.0, right: 16.0, top: 24.0, bottom: 16.0),
      child: Column(
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Prevention",
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 16.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                children: <Widget>[
                  SizedBox(
                      height: 100.0,
                      width: 100.0,
                      child: Stack(
                        children: <Widget>[
                          Container(
                            decoration: ShapeDecoration(
                                color: Colors.pinkAccent.withOpacity(0.2),
                                shape: CircleBorder(
                                    side: BorderSide(
                                        color: Colors.pinkAccent,
                                        width: 0.0,
                                        style: BorderStyle.none))),
                          ),
                          Center(
                            child: SvgPicture.asset(
                              'assets/images/social_distance.svg',
                              semanticsLabel: "Avoid close contact",
                              placeholderBuilder: (BuildContext context) {
                                return Loading(
                                    indicator: BallPulseIndicator(),
                                    size: 40.0,
                                    color: Colors.pink);
                              },
                            ),
                          ),
                        ],
                      )),
                  Container(
                    padding: EdgeInsets.only(top: 8.0),
                    width: 100.0,
                    child: Text(
                      "Avoid close contact",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              Column(
                children: <Widget>[
                  SizedBox(
                      height: 100.0,
                      width: 100.0,
                      child: Stack(
                        children: <Widget>[
                          Container(
                            decoration: ShapeDecoration(
                                color: Colors.pinkAccent.withOpacity(0.2),
                                shape: CircleBorder(
                                    side: BorderSide(
                                        color: Colors.pinkAccent,
                                        width: 0.0,
                                        style: BorderStyle.none))),
                          ),
                          Center(
                            child: SvgPicture.asset(
                                'assets/images/hand_washing.svg',
                                semanticsLabel: "Clean your hands often",
                                placeholderBuilder: (BuildContext context) {
                              return Loading(
                                  indicator: BallPulseIndicator(),
                                  size: 40.0,
                                  color: Colors.pink);
                            }),
                          ),
                        ],
                      )),
                  Container(
                    padding: EdgeInsets.only(top: 8.0),
                    width: 100.0,
                    child: Text(
                      "Clean your hands often",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              Column(
                children: <Widget>[
                  SizedBox(
                      height: 100.0,
                      width: 100.0,
                      child: Stack(
                        children: <Widget>[
                          Container(
                            decoration: ShapeDecoration(
                                color: Colors.pinkAccent.withOpacity(0.2),
                                shape: CircleBorder(
                                    side: BorderSide(
                                        color: Colors.pinkAccent,
                                        width: 0.0,
                                        style: BorderStyle.none))),
                          ),
                          Center(
                            child: SvgPicture.asset(
                                'assets/images/face_mask.svg',
                                semanticsLabel: "Wear a facemask",
                                placeholderBuilder: (BuildContext context) {
                              return Loading(
                                  indicator: BallPulseIndicator(),
                                  size: 40.0,
                                  color: Colors.pink);
                            }),
                          ),
                        ],
                      )),
                  Container(
                    padding: EdgeInsets.only(top: 8.0),
                    width: 100.0,
                    child: Text(
                      "Wear a facemask",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropDownCountry(Future<List<Country>> countries) {
    return FutureBuilder<List<Country>>(
        future: countries, // a Future<String> or null
        builder: (BuildContext context, AsyncSnapshot<List<Country>> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Loading(
                    indicator: BallPulseIndicator(),
                    size: 30.0,
                    color: Colors.white),
              );
            default:
              if (snapshot.hasError) {
                return Text(
                  //"Error loading spinner",
                  snapshot.error.toString(),
                  style: TextStyle(color: Colors.white, fontSize: 8.0),
                );
              } else {
                return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(25.0)),
                    ),
                    child: DropdownButton<String>(
                      underline: DropdownButtonHideUnderline(
                        child: Text(""),
                      ),
                      value: _selectedCountry == null
                          ? "Nigeria"
                          : _selectedCountry,
                      items: snapshot.data.map((Country country) {
                        return DropdownMenuItem<String>(
                          value: country.name,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.3,
                            child: Container(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Text(
                                  country.name,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String newValue) {
                        setState(() {
                          var iso = snapshot.data
                              .firstWhere((country) => country.name == newValue)
                              .iso;
                          _selectedCountry = newValue;
                          _saveCountry(newValue, iso);
                          loadAlternativeNews(false);
                          _nullGraphData();
                        });
                      },
                    ));
              }
          }
        });
  }

  _nullGraphData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("graph_data", null);
  }

  Future<void> loadAlternativeNews(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('should_load_alternative_news', value);
  }
}
