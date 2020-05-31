import 'dart:async';
import 'dart:convert';

import 'package:covidtracker/Jobs/WorkScheduler.dart';
import 'package:covidtracker/analytics/FirebaseAnalyticsHelper.dart';
import 'package:covidtracker/util/Constant.dart';
import 'package:covidtracker/views/CovidTest.dart';
import 'package:covidtracker/views/MainActivity.dart';
import 'package:covidtracker/views/news/Details.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_crashlytics/flutter_crashlytics.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_money_formatter/flutter_money_formatter.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'models/News.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
NotificationAppLaunchDetails notificationAppLaunchDetails;
final BehaviorSubject<String> selectNotificationSubject =
    BehaviorSubject<String>();
final BehaviorSubject<String> selectNotificationFirebaseSubject =
    BehaviorSubject<String>();

void callbackDispatcher() async {
  Workmanager.executeTask((task, inputData) async {
    switch (task) {
      case localReportPeriodicTask:
        var data = WorkScheduler.checkNewDailyLocalReport();
        var datum = await data;
        if (datum != null) {
          var confirmedDiff =
              datum.fold(0, (value, element) => value + element.confirmedDiff);
          SharedPreferences prefs = await SharedPreferences.getInstance();
          var country = prefs.getString('country');

          var data = WorkScheduler.checkNewDailyGlobalReport();
          var datumG = await data;
          if (datumG != null) {
            var headers = {
              'global':
                  FlutterMoneyFormatter(amount: datumG.confirmedDiff.toDouble())
                          .output
                          .withoutFractionDigits +
                      ' new cases were reported in the world. See update',
              'local': FlutterMoneyFormatter(amount: confirmedDiff.toDouble())
                      .output
                      .withoutFractionDigits +
                  ' new cases were reported in ' +
                  country +
                  '. See update.'
            };
            var titles = {
              'local': 'Local Covid-19 Case Report',
              'global': 'Global Covid-19 Case Report'
            };

            await displayReportNotification(
                titles, headers, datumG.date, {'local': 0, 'global': 1});
          }
        }
        break;
      case localNewsPeriodicTask:
        var data = WorkScheduler.checkNewDailyLocalNews();

        var datum = await data;
        if (datum != null) {
          datum.forEach((el) {
            displayNewsNotification(
                el,
                datum.indexOf(el),
                datum.indexWhere(
                    (element) => element.publishedAt == el.publishedAt),
                'local');
          });
        }
        break;
      case globalNewsPeriodicTask:
        var data = WorkScheduler.checkNewDailyGlobalNews();
        var datum = await data;
        if (datum != null) {
          datum.forEach((el) {
            displayNewsNotification(
                el,
                100 + datum.indexOf(el),
                datum.indexWhere(
                    (element) => element.publishedAt == el.publishedAt),
                'global');
          });
        }
        break;
    }
    return Future.value(true);
  });
}

Future displayNewsNotification(
    News news, int uniqueId, int id, String type) async {
  var inboxStyleInformation = InboxStyleInformation([],
      summaryText: type == 'local'
          ? 'Local Covid News Update'
          : 'Global Covid News Update');
  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      type == 'local' ? '100' : '102', 'News', 'News update',
      importance: Importance.High,
      ticker: 'ticker',
      styleInformation: inboxStyleInformation,
      priority: Priority.High);
  var notificationDetails =
      NotificationDetails(androidPlatformChannelSpecifics, null);
  await flutterLocalNotificationsPlugin.show(
      uniqueId, news.title, news.description, notificationDetails,
      payload: type == 'local'
          ? 'local/' + id.toString()
          : 'global/' + id.toString());
}

Future displayReportNotification(Map<String, dynamic> titles,
    Map<String, dynamic> headers, String date, Map<String, int> id) async {
  var groupKey = 'com.weylar.covidtracker';
  var groupChannelId = 'grouped channel id';
  var groupChannelName = 'grouped channel name';
  var groupChannelDescription = 'grouped channel description';

  var firstNotificationAndroidSpecifics = AndroidNotificationDetails(
      groupChannelId, groupChannelName, groupChannelDescription,
      importance: Importance.Max,
      priority: Priority.High,
      ticker: 'ticker',
      groupKey: groupKey);
  var firstNotificationPlatformSpecifics =
      NotificationDetails(firstNotificationAndroidSpecifics, null);
  await flutterLocalNotificationsPlugin.show(id['local'], titles['local'],
      headers['local'], firstNotificationPlatformSpecifics,
      payload: "report");

  var secondNotificationAndroidSpecifics = AndroidNotificationDetails(
      groupChannelId, groupChannelName, groupChannelDescription,
      importance: Importance.Max,
      priority: Priority.High,
      ticker: 'ticker',
      groupKey: groupKey);

  var secondNotificationPlatformSpecifics =
      NotificationDetails(secondNotificationAndroidSpecifics, null);
  await flutterLocalNotificationsPlugin.show(id['global'], titles['global'],
      headers['global'], secondNotificationPlatformSpecifics,
      payload: "report");

  var lines = List<String>();
  lines.add(headers['local']);
  lines.add(headers['global']);
  var inboxStyleInformation = InboxStyleInformation(lines,
      contentTitle: '2 messages', summaryText: 'Case update for ' + date);
  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      groupChannelId, groupChannelName, groupChannelDescription,
      styleInformation: inboxStyleInformation,
      groupKey: groupKey,
      setAsGroupSummary: true);
  var platformChannelSpecifics =
      NotificationDetails(androidPlatformChannelSpecifics, null);
  await flutterLocalNotificationsPlugin.show(
      3, 'Covid-19 Update', 'Two messages', platformChannelSpecifics,
      payload: "report");
}

Future initiateWorker() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (prefs.containsKey("last_day_fetched")) {
    await WorkScheduler.callbackFetchLocalReport();
    await WorkScheduler.callbackFetchGlobalReport();
  }
  if (prefs.containsKey('last_local_time')) {
    await WorkScheduler.callbackFetchLocalNews();
  }
  if (prefs.containsKey('last_global_time')) {
    await WorkScheduler.callbackFetchGlobalNews();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterCrashlytics().initialize();
  await Workmanager.initialize(callbackDispatcher, isInDebugMode: false);
  await initializeNotificationConfiguration();
  await initiateWorker();

  FlutterError.onError = (FlutterErrorDetails details) {
    if (!kReleaseMode) {
      FlutterError.dumpErrorToConsole(details);
    } else {
      Zone.current.handleUncaughtError(details.exception, details.stack);
    }
  };
  runZoned<Future<Null>>(() async {
    runApp(MyApp());
  }, onError: (error, stackTrace) async {
    await FlutterCrashlytics()
        .reportCrash(error, stackTrace, forceCrash: false);
  });
}

Future initializeNotificationConfiguration() async {
  notificationAppLaunchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
  var initializationSettingsIOS = IOSInitializationSettings();
  var initializationSettings = InitializationSettings(
      initializationSettingsAndroid, initializationSettingsIOS);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (String payload) async {
    selectNotificationSubject.add(payload);
  });
}

class MyApp extends StatefulWidget {
  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  Future<List<News>> _globalNews;
  Future<List<News>> _localNews;

  @override
  initState() {
    super.initState();
    FirebaseAnalyticsHelper.appOpen();
    _globalNews = _fetchGlobalNews();
    _whatNewsShouldLoad();
    _configureSelectNotificationNews();
    _firebaseNotificationAction();
    _clearAllNotification();
  }

  Future<void> _clearAllNotification() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  void _firebaseNotificationAction() {
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        _navigateToWebView(message);
      },
      onLaunch: (Map<String, dynamic> message) async {
        _navigateToWebView(message);
      },
      onResume: (Map<String, dynamic> message) async {
        _navigateToWebView(message);
      },
    );
  }

  void _navigateToWebView(Map<String, dynamic> message) async {
    var data = message['data'];
    if (data != null) {
      await FlutterWebBrowser.openWebPage(url: data['url']);
    }
  }

  void _configureSelectNotificationNews() {
    selectNotificationSubject.stream.listen((String payload) async {
      if (payload == 'report') {
        /* MyApp.navigatorKey.currentState
            .push(MaterialPageRoute(builder: (context) => Statistics()));*/
      } else if (payload.contains('local')) {
        MyApp.navigatorKey.currentState
            .pushNamed('/news/' + 'local' + "/" + payload.split('/')[1]);
      } else if (payload.contains('global')) {
        MyApp.navigatorKey.currentState
            .pushNamed('/news/' + 'global' + "/" + payload.split('/')[1]);
      }
    });
  }

  Future<void> _whatNewsShouldLoad() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var value = prefs.get('should_load_alternative_news');
    if (prefs.containsKey('should_load_alternative_news')) {
      setState(() {
        _localNews = value ? _fetchGlobalNewsIfNoLocal() : _fetchLocalNews();
      });
    } else {
      setState(() {
        _localNews = _fetchLocalNews();
      });
    }
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
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var result = parsed.map((val) => News.fromJson(val)).toList();
      prefs.setString('last_global_time', result.first.publishedAt);
      return result;
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
      debugShowCheckedModeBanner: true,
      navigatorKey: MyApp.navigatorKey,
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
