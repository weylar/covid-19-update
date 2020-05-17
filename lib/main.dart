import 'dart:async';
import 'dart:convert';

import 'package:covidtracker/analytics/FirebaseAnalyticsHelper.dart';
import 'package:covidtracker/util/Constant.dart';
import 'package:covidtracker/views/CovidTest.dart';
import 'package:covidtracker/views/MainActivity.dart';
import 'package:covidtracker/views/news/Details.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_crashlytics/flutter_crashlytics.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models/News.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) {
    //bool isInDebugMode = false;
    if (!kReleaseMode) {
      FlutterError.dumpErrorToConsole(details);
    } else {
      Zone.current.handleUncaughtError(details.exception, details.stack);
    }
  };

  await FlutterCrashlytics().initialize();
  runZoned<Future<Null>>(() async {

    runApp(MyApp());
  }, onError: (error, stackTrace) async {
    await FlutterCrashlytics()
        .reportCrash(error, stackTrace, forceCrash: false);
  });
}

class MyApp extends StatefulWidget {

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<List<News>> _globalNews;
  Future<List<News>> _localNews;


  @override
  initState() {
    super.initState();
    _globalNews = _fetchGlobalNews();
    _whatNewsShouldLoad();
    FirebaseAnalyticsHelper.appOpen();
  }

  Future<void> _whatNewsShouldLoad() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var _ = prefs.getBool('should_load_alternative_news');
    setState(() {
      _
          ? _localNews = _fetchGlobalNewsIfNoLocal()
          : _localNews = _fetchLocalNews();
    });
  }

  Future<List<News>> _fetchGlobalNewsIfNoLocal() async {
    var response = await http.get(Constant.createLocalNewsUrl(""));
    if (response.statusCode == 200) {
      final List parsed2 = json.decode(response.body)['articles'];
      return parsed2.map((val) => News.fromJson(val)).toList();
    } else {
      return List();
    }
  }

  Future<List<News>> _fetchGlobalNews() async {
    var response = await http.get(Constant.GLOBAL_NEWS_URL);
    if (response.statusCode == 200) {
      final List parsed = json.decode(response.body)['articles'];
      return parsed.map((val) => News.fromJson(val)).toList();
    } else {
      return List();
    }
  }

  Future<String> getCountry() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var country = prefs.getString('country_iso');
    return country;
  }

  Future<List<News>> _fetchLocalNews() async {
    var country = await getCountry();
    var response =
        await http.get(Constant.createLocalNewsUrl(country.substring(0, 2)));
    if (response.statusCode == 200) {
      final List parsed = json.decode(response.body)['articles'];
      return parsed.map((val) => News.fromJson(val)).toList();
    }
    return List();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      //showSemanticsDebugger: true,
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalyticsHelper.analytics),
      ],
      title: 'Covid Tracker',
      theme: ThemeData(
        fontFamily: 'Poppins',
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      routes: {
        '/': (BuildContext context) => MainActivity(_globalNews, _localNews),
        '/covid-test': (BuildContext context) => CovidTest()
      },
      onGenerateRoute: (RouteSettings settings) {
        final List<String> pathElements = settings.name.split('/');
        if (pathElements[0] != '') {
          return null;
        }
        if (pathElements[2] == 'global') {
          return MaterialPageRoute<bool>(
            builder: (BuildContext context) => Details(
                _globalNews.then((news) => news[int.parse(pathElements[3])])),
          );
        } else if (pathElements[2] == 'local') {
          _whatNewsShouldLoad();
          return MaterialPageRoute<bool>(
            builder: (BuildContext context) => Details(
                _localNews.then((news) => news[int.parse(pathElements[3])])),
          );
        }
        return null;
      },
    );
  }
}
