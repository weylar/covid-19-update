import 'dart:math';

import 'package:covidtracker/analytics/FirebaseAnalyticsHelper.dart';
import 'package:covidtracker/helper/ViewType.dart';
import 'package:covidtracker/models/News.dart';
import 'package:covidtracker/views/Home.dart';
import 'package:covidtracker/views/Statistics.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';

import 'news/Latest.dart';

class MainActivity extends StatefulWidget {
  Future<List<News>> _globalNews;
  Future<List<News>> _localNews;

  MainActivity(Future<List<News>> global, Future<List<News>> local) {
    this._localNews = local;
    this._globalNews = global;
  }

  @override
  _MainActivity createState() => _MainActivity();
}

class _MainActivity extends State<MainActivity> {
  ViewType viewType;
  GlobalKey _bottomNavigationKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            viewType == ViewType.UPDATES ? Colors.white : Colors.deepPurple,
        elevation: 0.0,
        actions: <Widget>[
          GestureDetector(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Icon(
                Icons.help_outline,
                color: viewType == ViewType.UPDATES
                    ? Colors.deepPurple
                    : Colors.white,
                size: 28.0,
              ),
            ),
            onTap: () async {
              var websites = [
                "https://www.who.int/health-topics/coronavirus",
                "https://www.unicef.org/coronavirus/covid-19"
              ];
              await FlutterWebBrowser.openWebPage(
                  url: websites[Random.secure().nextInt(websites.length)]);
            },
          )
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        backgroundColor: Colors.deepPurple.withOpacity(0.8),
        height: 50.0,
        items: <Widget>[
          Icon(
            Icons.home,
            size: 25,
            color: Colors.blueGrey,
          ),
          Icon(
            Icons.poll,
            size: 25,
            color: Colors.blueGrey,
          ),
          Icon(
            Icons.whatshot,
            size: 25,
            color: Colors.blueGrey,
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              setState(() {
                viewType = ViewType.HOME;
              });
              break;
            case 1:
              setState(() {
                viewType = ViewType.STATISTICS;
              });
              break;
            case 2:
              setState(() {
                viewType = ViewType.UPDATES;
              });
              break;
            default:
              setState(() {
                viewType = ViewType.HOME;
              });
          }
        },
      ),
      body: _buildPageToShow(viewType),
    );
  }

  Widget _buildPageToShow(ViewType viewType) {
    FirebaseAnalyticsHelper.setCurrentScreen(
        "MainActivity",
        "MainActivity "
            "Class");
    switch (viewType) {
      case ViewType.HOME:
        return MyHomePage.instance;
        break;
      case ViewType.STATISTICS:
        return Statistics();
        break;
      case ViewType.UPDATES:
        return Latest(widget._globalNews, widget._localNews);
        break;
      default:
        return MyHomePage.instance;
    }
  }
}
