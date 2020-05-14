

import 'package:shared_preferences/shared_preferences.dart';

class Constant {



  static const API_KEY_NEWS = "7cdadceaacf14019a69e71301c9ba2c8";
  static const API_KEY_STATISTICS = "0f2bc47882mshc51f2c0a7151323p1eab12jsn6152c6619ec7";
  static const HOST_STATISTICS = "covid-19-statistics.p.rapidapi.com";
  static const GLOBAL_NEWS_URL =
      "https://newsapi.org/v2/top-headlines?q=covid&sortBy=popularity&apiKey=" +
          API_KEY_NEWS;


  static createLocalNewsUrl(String country) => "https://newsapi.org/v2/top-headlines?"
      "country=" + country + "&q=covid&sortBy=popularity&apiKey=" +
      API_KEY_NEWS;


  static const COUNTRY_COVID_API =
      "https://covid-19-statistics.p.rapidapi.com/reports?region_name=";

  static const GLOBAL_COVID_API =
      "https://covid-19-statistics.p.rapidapi.com/reports/total";

  static const ALL_COUNTRY_API =
      "https://covid-19-statistics.p.rapidapi.com/regions";
}
