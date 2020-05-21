import 'package:covidtracker/analytics/FirebaseAnalyticsHelper.dart';
import 'package:covidtracker/helper/Common.dart';
import 'package:covidtracker/models/News.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:loading/indicator/ball_pulse_indicator.dart';
import 'package:loading/loading.dart';
import 'package:timeago/browser_timeago.dart';

class Details extends StatefulWidget {
  Future<News> _news;

  Details(Future<News> news) {
    this._news = news;
  }


  @override
  _Details createState() => _Details();
}



class _Details extends State<Details> {

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance
        .addPostFrameCallback((_) => Common.showNoNetworkDialog(context));
    FirebaseAnalyticsHelper.setCurrentScreen("DetailsNewsPage", "Details News"
        " Class");

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FutureBuilder<News>(
            future: widget._news,
            builder: (BuildContext context, AsyncSnapshot<News> snapshot) {
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
                  else {
                    var dateTime = DateTime.parse(snapshot.data.publishedAt);
                    final time = TimeAgo().format(dateTime);
                    return Container(
                        child: SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          SizedBox(
                            height: 30.0,
                          ),
                          Row(
                            children: <Widget>[
                              BackButton(),
                              SizedBox(
                                width: 8.0,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    "Source",
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                        fontSize: 12.0, color: Colors.grey),
                                  ),
                                  Text(
                                    snapshot.data.source,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.left,
                                  ),
                                ],
                              )
                            ],
                          ),
                          Padding(
                              padding: const EdgeInsets.only(
                                  left: 16.0,
                                  right: 16.0,
                                  top: 8.0,
                                  bottom: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    snapshot.data.title,
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.w900),
                                  ),
                                  SizedBox(
                                    height: 32.0,
                                  ),
                                  Card(
                                      semanticContainer: true,
                                      clipBehavior: Clip.antiAliasWithSaveLayer,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(24.0),
                                      ),
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        child: snapshot.data.urlToImage !=
                                            "null"
                                            ? Image.network(
                                          snapshot.data.urlToImage,)
                                            : Image.asset(
                                            "assets/icons/app_icon.png",
                                            fit: BoxFit.cover),
                                      )),
                                  SizedBox(
                                    height: 12.0,
                                  ),
                                  Text(
                                    time,
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12.0,
                                        letterSpacing: 2.0),
                                  )
                                ],
                              )),
                          Divider(),
                          SizedBox(
                            height: 12.0,
                          ),
                          Container(
                            margin: EdgeInsets.only(left: 32.0, bottom: 8.0),
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(4.0),
                                  bottomLeft: Radius.circular(4.0),
                                ),
                                color: Colors.orange),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 12.0, top: 4.0, bottom: 4.0),
                              child: Text(
                                "Covid-19",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 16.0, right: 16.0, top: 8.0, bottom: 8.0),
                            child: Column(
                              children: <Widget>[
                                Linkify(
                                  onOpen: (link) async {
                                      _launchURL(link.url);
                                  },
                                  text: snapshot.data.content == "null"
                                      ? snapshot.data.description == "null"
                                          ? "No content"
                                          : snapshot.data.description
                                      : _cleanContent(snapshot.data.content),
                                  linkStyle: TextStyle(color: Colors.red),
                                ),
                                SizedBox(
                                  height: 8.0,
                                ),
                                Container(
                                  height: 35.0,
                                  width: MediaQuery.of(context).size.width,
                                  decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.grey.withOpacity(0.8),
                                          Colors.blueGrey
                                        ],
                                        stops: [0.0, 0.7],
                                      ),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(8.0))),
                                  child: FlatButton.icon(
                                    onPressed: () =>
                                        _launchURL(snapshot.data.url),
                                    icon: Icon(
                                      Icons.open_in_new,
                                      color: Colors.white,
                                    ),
                                    label: Container(
                                      child: Text(
                                        snapshot.data.source == "Youtube.com"
                                            ? "Watch on " + snapshot.data.source
                                            : snapshot.data.source.length > 10
                                                ? "Continue reading on " +
                                                    snapshot.data.source
                                                        .substring(0, 10) +
                                                    "..."
                                                : "Continue reading on " +
                                                    snapshot.data.source,
                                        //maxLines: 1,
                                        //softWrap: true,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ));
                  }
              }
            }));
  }

  String _cleanContent(String content) {
    return content.contains(RegExp(r"]")) //&& content.conta
        ? content.replaceRange(
            content.indexOf("["), content.indexOf("]") + 1, "")
        : content;
  }

  _launchURL(String url) async {
    await FlutterWebBrowser.openWebPage(url: url);

  }
}
