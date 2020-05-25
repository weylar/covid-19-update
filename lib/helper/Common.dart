import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Common {
  static Future<bool> isInternetDisabled() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.mobile &&
        connectivityResult != ConnectivityResult.wifi;

  }

  static showNoNetworkDialog(BuildContext context) async{
    print(await isInternetDisabled());
    if (await isInternetDisabled()) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.0)), //this right here
              child: Container(
                height: 150,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Oops!\nNo Internet Connection',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18.0),
                      ),
                      SizedBox(
                        height: 16.0,
                      ),
                      Text(
                          "Your internet connection seem to be off, please "
                          "check and retry.",
                          textAlign: TextAlign.center)
                    ],
                  ),
                ),
              ),
            );
          });
    }
  }
}
