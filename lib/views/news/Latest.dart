import 'dart:convert';

import 'package:covidtracker/analytics/FirebaseAnalyticsHelper.dart';
import 'package:covidtracker/models/News.dart';
import 'package:covidtracker/util/Constant.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:loading/indicator/ball_pulse_indicator.dart';
import 'package:loading/loading.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/browser_timeago.dart';

class Latest extends StatefulWidget {
  Future<List<News>> _globalNews;
  Future<List<News>> _localNews;

  Latest(Future<List<News>> global, Future<List<News>> local) {
    this._localNews = local;
    this._globalNews = global;
  }

  @override
  _LatestState createState() => _LatestState();
}

class _LatestState extends State<Latest> {
  @override
  void initState() {
    super.initState();
    FirebaseAnalyticsHelper.setCurrentScreen("LatestNewsPage", "LatestNewsPag"
        "e");
    _whatNewsShouldLoad();
  }

  Future<String> getCountry() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var country = prefs.getString('country_iso');
    return country;
  }

  Future<void> _whatNewsShouldLoad() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var _ = prefs.getBool('should_load_alternative_news');
    setState(() {
      _
          ? widget._localNews = _fetchGlobalNewsIfNoLocal()
          : widget._localNews = _fetchLocalNews();
    });
  }

  Future<void> loadAlternativeNews(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('should_load_alternative_news', value);
  }

  Future<List<News>> _fetchLocalNews() async {
    var country = await getCountry();
    print(country);
    var response =
        await http.get(Constant.createLocalNewsUrl(country.substring(0, 2)));
    if (response.statusCode == 200) {
      final List parsed = json.decode(response.body)['articles'];
      return parsed.map((val) => News.fromJson(val)).toList();
    }
    return List();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            color: Colors.white,
            child: SingleChildScrollView(
                child: Column(
              children: <Widget>[
                Padding(
                    padding: const EdgeInsets.only(
                        left: 16.0, right: 16.0, top: 8.0, bottom: 16.0),
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              "Global News",
                              style: TextStyle(
                                  fontSize: 22.0,
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        _buildGlobalNews(widget._globalNews),
                        SizedBox(
                          height: 4.0,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              "Local News",
                              style: TextStyle(
                                  fontSize: 20.0,
                                  letterSpacing: 0.0,
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Source: NewsAPI",
                              style: TextStyle(
                                  fontSize: 12.0,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey),
                            ),
                          ],
                        ),
                        _buildLocalNews(widget._localNews)
                      ],
                    )),
              ],
            ))));
  }

  Widget _buildGlobalNews(Future<List<News>> news) {
    return FutureBuilder<List<News>>(
      future: news, // a Future<String> or null
      builder: (BuildContext context, AsyncSnapshot<List<News>> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return Loading(
                indicator: BallPulseIndicator(),
                size: 40.0,
                color: Colors.pink);
          default:
            if (snapshot.hasError)
              return Container(
                  height: MediaQuery.of(context).size.height * 0.1,
                  child: Center(
                      child: Text(
                    'Unable to connect to the internet. '
                    'Please check you internet connection.',
                    textAlign: TextAlign.center,
                  )));
            else
              return Container(
                  margin: EdgeInsets.symmetric(vertical: 24.0),
                  height: 180.0,
                  child: ListView.builder(
                    itemCount: snapshot.data.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (BuildContext context, int position) {
                      return Card(
                          margin: EdgeInsets.symmetric(horizontal: 8.0),
                          semanticContainer: true,
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                          child: GestureDetector(
                              onTap: () => _openDetail(position, "global"),
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.8,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: <Widget>[
                                    snapshot.data[position].urlToImage !=
                                           "null"
                                        ? Image.network(
                                            snapshot.data[position].urlToImage,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            "assets/icons/app_icon.png",
                                            fit: BoxFit.cover),
                                    Container(
                                      color: Colors.black.withOpacity(0.5),
                                    ),
                                    Positioned.fill(
                                        child: Align(
                                            alignment: Alignment.bottomLeft,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Text(
                                                snapshot.data[position].title,
                                                overflow: TextOverflow.fade,
                                                maxLines: 2,
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 22.0,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            )))
                                  ],
                                ),
                              )));
                    },
                  ));
        }
      },
    );
  }

  Widget _buildLocalNews(Future<List<News>> news) {
    return FutureBuilder<List<News>>(
      future: news, // a Future<String> or null
      builder: (BuildContext context, AsyncSnapshot<List<News>> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Center(
                child: Loading(
                    indicator: BallPulseIndicator(),
                    size: 40.0,
                    color: Colors.pink),
              ),
            );
          default:
            if (snapshot.hasError)
              return Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Center(
                      child: Text(
                    'Unable to connect to the internet. '
                    'Please check you internet connection.',
                    textAlign: TextAlign.center,
                  )));
            else if (snapshot.data.isEmpty) {
              return Container(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: Center(
                      child: GestureDetector(
                          onTap: () {
                            setState(() {
                              widget._localNews = _fetchGlobalNewsIfNoLocal();
                              loadAlternativeNews(true);
                            });
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              SizedBox(
                                  height:
                                      MediaQuery.of(context).size.width * 0.3,
                                  width:
                                      MediaQuery.of(context).size.width * 0.3,
                                  child: SvgPicture.asset(
                                      "assets/images/body_ache.svg",
                                      semanticsLabel: "No localised news")),
                              Text(
                                "Sorry we couldn't fetch you localized news.\n"
                                "Tap to see what's happening in the world now.",
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ))));
            } else {
              return Container(
                  margin: EdgeInsets.only(top: 8.0),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data.length,
                    scrollDirection: Axis.vertical,
                    itemBuilder: (BuildContext context, int position) {
                      var dateTime =
                          DateTime.parse(snapshot.data[position].publishedAt);
                      final time = TimeAgo().format(dateTime);
                      return GestureDetector(
                          onTap: () => _openDetail(position, "local"),
                          child: Container(
                            child: Column(
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Flexible(
                                      flex: 2,
                                      child: Column(
                                        children: <Widget>[
                                          Text(
                                            snapshot.data[position]
                                                        .description !=
                                                    "null"
                                                ? snapshot
                                                    .data[position].description
                                                : snapshot.data[position].title,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                TextStyle(color: Colors.black),
                                          ),
                                          SizedBox(
                                            height: 8.0,
                                          ),
                                          Row(
                                            children: <Widget>[
                                              Container(
                                                decoration: BoxDecoration(
                                                    color: Colors.deepOrange
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                4.0))),
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                          .symmetric(
                                                      horizontal: 8.0,
                                                      vertical: 4.0),
                                                  child: Text(
                                                    "Covid-19",
                                                    style: TextStyle(
                                                      color: Colors.deepOrange,
                                                      fontWeight:
                                                          FontWeight.w300,
                                                      fontSize: 12.0,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 8.0,
                                              ),
                                              Text(
                                                time,
                                                style: TextStyle(
                                                    color: Colors.grey),
                                              )
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 2.0,
                                    ),
                                    Flexible(
                                      flex: 1,
                                      child: snapshot.data[position].urlToImage !=
                                          "null"
                                          ? Image.network(
                                        snapshot.data[position].urlToImage,
                                        fit: BoxFit.cover,
                                      )
                                          : Image.asset(
                                          "assets/icons/app_icon.png",
                                          fit: BoxFit.cover),
                                    ),
                                  ],
                                ),
                                Divider()
                              ],
                            ),
                          ));
                    },
                  ));
            }
        }
      },
    );
  }

  _openDetail(int position, String path) {
    print(position);
    Navigator.pushNamed(context, '/news/' + path + "/" + position.toString());
  }
}
