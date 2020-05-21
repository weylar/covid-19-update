import 'dart:convert';

import 'package:covidtracker/models/CovidResponse.dart';
import 'package:covidtracker/models/News.dart';
import 'package:covidtracker/util/Constant.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

const localReportPeriodicTask = "fetchDailyReportPeriodicTask";
const globalReportPeriodicTask = "fetchGlobalReportPeriodicTask";
const localNewsPeriodicTask = "fetchLocalNewsPeriodicTask";
const localReportPeriodicUniqueName = "1";
const globalReportPeriodicUniqueName = "2";
const localNewsPeriodicUniqueName = "3";

class WorkScheduler {
  static Future<String> getCountry() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var country = prefs.getString('country');
    return country;
  }

  static Future<void> callbackFetchLocalReport() {
    return Workmanager.registerPeriodicTask(
        localReportPeriodicUniqueName, localReportPeriodicTask,
        frequency: Duration(hours: 1),
        existingWorkPolicy: ExistingWorkPolicy.keep,
        constraints: Constraints(networkType: NetworkType.connected));
  }

  static Future<void> callbackFetchGlobalReport() {
    return Workmanager.registerPeriodicTask(
        globalReportPeriodicUniqueName, globalReportPeriodicTask,
        frequency: Duration(hours: 1),
        existingWorkPolicy: ExistingWorkPolicy.keep,
        constraints: Constraints(networkType: NetworkType.connected));
  }

  static Future<void> callbackFetchLocalNews() {
    return Workmanager.registerPeriodicTask(
        localNewsPeriodicUniqueName, localNewsPeriodicTask,
        frequency: Duration(hours: 1),
        existingWorkPolicy: ExistingWorkPolicy.keep,
        constraints: Constraints(networkType: NetworkType.connected));
  }

  static Future<List<News>> checkNewDailyLocalNews() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var country = prefs.getString('country_iso');
    var response =
        await http.get(Constant.createLocalNewsUrl(country.substring(0, 2)));
    if (response.statusCode == 200) {
      final List parsed = json.decode(response.body)['articles'];
      var result = parsed.map((val) => News.fromJson(val)).toList();
      var lastFetchedTime = result.first.publishedAt;
      var previousTime = prefs.getString('last_local_time');
      if (DateTime.parse(previousTime)
          .isBefore(DateTime.parse(lastFetchedTime))) {
        prefs.setString("last_local_time", lastFetchedTime);
        return result.where((element) => DateTime.parse(element.publishedAt)
            .isAfter(DateTime.parse(lastFetchedTime))).toList();
      }
      return null;
    }
    return null;
  }

  static Future<List<CovidResponse>> checkNewDailyLocalReport() async {
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
      var lastFetchedDate = result.first.date;
      var previousDate = prefs.getString("last_day_fetched");
      if (DateTime.parse(previousDate)
          .isBefore(DateTime.parse(lastFetchedDate))) {
        prefs.setString("last_day_fetched", lastFetchedDate);
        return result;
      }
      return null;
    }
    return null;
  }

  static Future<CovidResponse> checkNewDailyGlobalReport() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var response = await http.get(Constant.GLOBAL_COVID_API, headers: {
      "x-rapidapi-key": Constant.API_KEY_STATISTICS,
      "x-rapidapi-host": Constant.HOST_STATISTICS
    });
    if (response.statusCode == 200) {
      var result = CovidResponse.fromJson(json.decode(response.body)['data']);
      var lastFetchedDate = result.date;
      var previousDate = prefs.getString("last_day_global_fetched");
      if (DateTime.parse(previousDate)
          .isBefore(DateTime.parse(lastFetchedDate))) {
        prefs.setString("last_day_global_fetched", lastFetchedDate);
        return result;
      }
      return null;
    }
    return null;
  }
}
