import 'dart:convert';

import 'package:covidtracker/models/CovidResponse.dart';
import 'package:covidtracker/util/Constant.dart';
import 'package:covidtracker/views/Statistics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;

const simplePeriodicTask = "fetchDailyReportPeriodicTask";
const simplePeriodicUniqueName = "1";

class WorkScheduler {

  static Future<String> getCountry() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var country = prefs.getString('country');
    return country;
  }

  static void callbackFetchDailyReport() {
    Workmanager.registerPeriodicTask(
        simplePeriodicUniqueName, simplePeriodicTask,
        frequency: Duration(minutes: 15),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        constraints: Constraints(
            networkType: NetworkType.connected,
            requiresBatteryNotLow: true));
  }

  static Future<List<CovidResponse>> checkNewDailyReport() async {
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
      //var presentDate = result.first.date;
      var presentDate = '2020-05-18';
      var previousDate = prefs.getString("last_day_fetched");
      print(presentDate);
      print(previousDate);
      if (DateTime.parse(previousDate).isBefore(DateTime.parse(presentDate))) {
        prefs.setString("last_day_fetched", presentDate);
        return result;
      }
      return null;
    }
    return null;
  }
}
