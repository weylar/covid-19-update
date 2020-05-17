

import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseAnalyticsHelper{
  static FirebaseAnalytics analytics = FirebaseAnalytics();

 static Future<void>  setCurrentScreen(String screenName, String
  screenClassOverride) async {
    await analytics.setCurrentScreen(
      screenName: screenName,
      screenClassOverride: screenClassOverride,
    );
  }

  static Future<void> appOpen() async {
    return await analytics.logAppOpen();
  }

}