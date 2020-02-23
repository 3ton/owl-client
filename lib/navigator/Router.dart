import 'package:flutter/material.dart';
import 'package:owl/SplashScreen.dart';
import 'package:owl/account/screens/ConfirmEmailScreen.dart';
import 'package:owl/account/screens/SignUpScreen.dart';
import 'package:owl/call/CallInfo.dart';
import 'package:owl/call/screens/CallScreen.dart';
import 'package:owl/general/screens/HomeScreen.dart';
import 'package:owl/navigator/Routes.dart';
import 'package:owl/share_room/models/ShareRoomModel.dart';
import 'package:owl/share_room/screens/ShareRoomDetailScreen.dart';

class Router {
  Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.SplashScreen:
        return MaterialPageRoute(
          builder: (context) => SplashScreen(),
          settings: RouteSettings(name: Routes.SplashScreen),
        );
      case Routes.SignUpScreen:
        return MaterialPageRoute(
          builder: (context) => SignUpScreen(),
          settings: RouteSettings(name: Routes.SignUpScreen),
        );
      case Routes.ConfirmEmailScreen:
        return MaterialPageRoute(
          builder: (context) => ConfirmEmailScreen(),
          settings: RouteSettings(name: Routes.ConfirmEmailScreen),
        );
      case Routes.HomeScreen:
        return MaterialPageRoute(
          builder: (context) => HomeScreen(),
          settings: RouteSettings(name: Routes.HomeScreen),
        );
      case Routes.ShareRoomDetailScreen:
        return MaterialPageRoute(
          builder: (context) => ShareRoomDetailScreen(
            shareRoom: settings.arguments as ShareRoomModel,
          ),
          settings: RouteSettings(name: Routes.ShareRoomDetailScreen),
        );
      case Routes.CallScreen:
        return MaterialPageRoute(
          builder: (context) => CallScreen(
            callInfo: settings.arguments as CallInfo,
          ),
          settings: RouteSettings(name: Routes.CallScreen),
        );
    }
  }
}
