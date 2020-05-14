import 'package:covidtracker/models/Question.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:loading/indicator/ball_pulse_indicator.dart';
import 'package:loading/loading.dart';
import 'package:url_launcher/url_launcher.dart';

class CovidTest extends StatefulWidget {
  CovidTest({Key key}) : super(key: key);

  @override
  _CovidTest createState() => _CovidTest();
}

class _CovidTest extends State<CovidTest> with SingleTickerProviderStateMixin {
  List<Question> _questions;
  int _currentState = 0;
  int _result = 0;
  ResultKey _key;

  @override
  void initState() {
    super.initState();
    _questions = [
      Question("Do you have cold?", "assets/images/cold.svg", ["Yes", "No"]),
      Question("Do you have cough?", "assets/images/cough.svg", ["Yes", "No"]),
      Question("Are you having diarrhea?", "assets/images/diarrhea.svg",
          ["Yes", "No"]),
      Question("Are you having sorethroat?", "assets/images/sore_throat.svg",
          ["Yes", "No"]),
      Question("Are you having body aches?", "assets/images/body_ache.svg",
          ["Yes", "No"]),
      Question("Are you having headache?", "assets/images/body_ache.svg",
          ["Yes", "No"]),
      Question("Do you have fever (Temperature 37.8°C and above)?",
          "assets/images/body_ache.svg", ["Yes", "No"]),
      Question("Are you having difficulty breathing?",
          "assets/images/difficult_breathing.svg", ["Yes", "No"]),
      Question("Are you experiencing fatigue?", "assets/images/fatigue.svg",
          ["Yes", "No"]),
      Question("Have you traveled recently during the past 14 days?",
          "assets/images/travel.svg", ["Yes", "No"]),
      Question(
          "Do you have a history of traveling to an area infected "
              "with COVID-19 ?",
          "assets/images/infected_person.svg",
          ["Yes", "No", "I don't know"]),
      Question(
          "Do you have direct contact with or are you taking care of a "
              "positive COVID-19 patient?",
          "assets/images/patient.svg",
          ["Yes", "No", "I don't know"]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: BottomAppBar(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Note: This is a COVID-19 self assessment tool that" +
                  " was calibrated based on WHO guidelines." +
                  "It is not a diagnostic tool.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.0),
            ),
          ),
          elevation: 0,
        ),
        body: Container(
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.1,
                  child:  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        BackButton(),
                      ],
                    ),
                  ),
                ),

                Padding(
                    padding: const EdgeInsets.only(
                        left: 16.0, right: 16.0, top: 8.0, bottom: 16.0),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.75,
                      child: Column(
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                "Covid-19 Self Test",
                                style: TextStyle(
                                    fontSize: 22.0,
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 24.0,
                          ),
                           Expanded(
                             child: Align(
                               alignment: Alignment.center,
                               child:
                                 _currentState < 12 ?
                                   _buildQuestionWidget(_questions[_currentState]):
                                      _buildResultContentWidget(),

                             ),
                           ),

                        ],
                      ),
                    )),
              ],
            )));
  }

  Widget _buildResultContentWidget(){
    return  _key == ResultKey.SEVERE
    ? _buildResultWidget(Result(
    "Your risk of having COVID-19 is",
    "assets/images/result.svg",
    "Severe",
    "Do not panic, isolate yourself from "
    "friends and family. Make sure you call for help."))
        : _key == ResultKey.HIGH
    ? _buildResultWidget(Result(
    "Your risk of having COVID-19 is",
    "assets/images/result.svg",
    "High",
    "Do not panic, isolate yourself from "
    "friends and family. Make sure you call for help."))
        : _key == ResultKey.MEDIUM
    ? _buildResultWidget(Result(
    "Your risk of having COVID-19 is",
    "assets/images/result.svg",
    "Medium",
    "Do not panic, isolate yourself from "
    "friends and family. Make sure you call for help."))
        : _key == ResultKey.LOW
    ? _buildResultWidget(Result(
    "Your risk of having COVID-19 is",
    "assets/images/result.svg",
    "Low",
    "Don't forget, maintain social distance and keep good hygiene always.")):
    _buildResultWidget(null);
  }

  Widget _buildQuestionWidget(Question question) {
    return Card(
        elevation: 10.0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16.0))),
        child: Align(
          alignment: Alignment.center,
          child: Container(
            padding: EdgeInsets.all(32.0),
            child: Column(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    SizedBox(
                        height: MediaQuery.of(context).size.width * 0.3,
                        width: MediaQuery.of(context).size.width * 0.3,
                        child: SvgPicture.asset(question.image,
                            semanticsLabel: question.questionText,
                            placeholderBuilder: (BuildContext context){
                              return Loading(
                                  indicator: BallPulseIndicator(),
                                  size: 40.0,color: Colors.pink);
                            })),
                    SizedBox(
                      height: 8.0,
                    ),
                    Text(
                      question.questionText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 22.0, fontWeight: FontWeight.w300),
                    )
                  ],
                ),
                SizedBox(
                  height: 30.0,
                ),
                Column(
                  children: question.response.map((String value) {
                    return _buildButton(value);
                  }).toList(),
                )
              ],
            ),
          ),
        ));
  }

  Widget _buildResultWidget(Result result) {
    return Card(
        elevation: 10.0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16.0))),
        child: Align(
          alignment: Alignment.center,
          child: Container(
            padding: EdgeInsets.all(32.0),
            child: Column(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    SizedBox(
                        height: MediaQuery.of(context).size.width * 0.3,
                        width: MediaQuery.of(context).size.width * 0.3,
                        child: SvgPicture.asset(result.image,
                            semanticsLabel: result.key)),
                    SizedBox(
                      height: 8.0,
                    ),
                    Text(
                      result.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 18.0, fontWeight: FontWeight.w300),
                    ),
                    Text(
                      result.key,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _key == ResultKey.SEVERE
                              ? Colors.red
                              : _key == ResultKey.HIGH
                                  ? Colors.redAccent
                                  : _key == ResultKey.MEDIUM
                                      ? Colors.deepPurple
                                      : _key == ResultKey.LOW
                                          ? Colors.green
                                          : Colors.black,
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 16.0,
                    ),
                    Text(
                      result.moreText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16.0, fontWeight: FontWeight.w300),
                    ),
                    SizedBox(
                      height: 12.0,
                    ),
                    _key == ResultKey.HIGH ||
                            _key == ResultKey.SEVERE ||
                            _key == ResultKey.MEDIUM
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                  child: Container(
                                decoration: ShapeDecoration(
                                    color: Colors.deepOrange,
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(
                                          width: 0.0, style: BorderStyle.none),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(50.0)),
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
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(50.0)),
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
                        : Row(),
                    SizedBox(
                      height: 12.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                            child: Container(
                          decoration: ShapeDecoration(
                              color: Colors.deepPurple,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                    width: 0.0, style: BorderStyle.none),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(50.0)),
                              )),
                          child: FlatButton.icon(
                              onPressed: () {
                                setState(() {
                                  _currentState = 0;
                                  _result = 0;
                                });
                              },
                              icon: Icon(
                                Icons.refresh,
                                color: Colors.white,
                              ),
                              label: Text(
                                "Restart Test",
                                style: TextStyle(color: Colors.white),
                              )),
                        )),
                      ],
                    )
                  ],
                ),
                SizedBox(
                  height: 30.0,
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildButton(String type) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      margin: EdgeInsets.only(bottom: 8.0),
      child: Container(
        decoration: ShapeDecoration(
            color: type == "Yes"
                ? Colors.deepPurple
                : type == "No" ? Colors.deepOrange : Colors.blueGrey,
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 0.0, style: BorderStyle.none),
              borderRadius: BorderRadius.all(Radius.circular(50.0)),
            )),
        child: FlatButton.icon(
            onPressed: () {
              _moveToNextQuestion();
              print(_result);
              if (_result >= 10 && _result <= 12) {
                _key = ResultKey.SEVERE;
              } else if (_result >= 6 && _result <= 9) {
                _key = ResultKey.HIGH;
              } else if (_result >= 3 && _result <= 5) {
                _key = ResultKey.MEDIUM;
              } else {
                _key = ResultKey.LOW;
              }
              switch (type) {
                case "Yes":
                  _result++;
                  break;
                case "No":
                  _result--;
                  break;
                case "I don't know":
                  break;
              }
            },
            icon: type == "Yes"
                ? Icon(
                    Icons.check_circle,
                    color: Colors.white,
                  )
                : type == "No"
                    ? Icon(
                        Icons.cancel,
                        color: Colors.white,
                      )
                    : Icon(
                        Icons.remove_circle,
                        color: Colors.white,
                      ),
            label: Text(
              type,
              style: TextStyle(color: Colors.white),
            )),
      ),
    );
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
  void _moveToNextQuestion() {
    setState(() {
      _currentState++;
    });
  }
}
