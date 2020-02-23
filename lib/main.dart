import 'package:flutter/material.dart';
import 'package:owl/DIContainer.dart';
import 'package:owl/navigator/Router.dart';
import 'package:owl/navigator/Routes.dart';

void main() async {
  DIContainer.setup();
  runApp(OwlApp());
}

class OwlApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Owl',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        accentColor: Color(0xFF4056a1),
      ),
      initialRoute: Routes.SplashScreen,
      onGenerateRoute: DIContainer.resolve<Router>().generateRoute,
    );
  }
}
