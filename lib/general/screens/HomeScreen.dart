import 'dart:async';

import 'package:flutter/material.dart';
import 'package:owl/DIContainer.dart';
import 'package:owl/account/widgets/ProfileWidget.dart';
import 'package:owl/call/CallInfo.dart';
import 'package:owl/call/managers/CallManager.dart';
import 'package:owl/contact/widgets/ContactWidget.dart';
import 'package:owl/logging/widgets/LoggingWidget.dart';
import 'package:owl/navigator/Routes.dart';
import 'package:owl/share_room/widgets/ShareRoomWidget.dart';

Color primaryColor = Color(0xFF25274d);

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CallManager _callManager = DIContainer.resolve<CallManager>();

  StreamSubscription<CallInfo> _incomingCall$$;

  @override
  void initState() {
    super.initState();

    _incomingCall$$ = _callManager.incomingCall$.listen((callInfo) {
      Navigator.of(context).pushNamed(Routes.CallScreen, arguments: callInfo);
    });
  }

  @override
  void dispose() {
    _incomingCall$$.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('===== Build HomeScreen =====');

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'assets/images/owl.png',
                color: Colors.white70,
                width: 140,
              ),
            ],
          ),
          bottom: TabBar(
            tabs: [
              Tab(
                child: Text(
                  'CHATS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                  ),
                ),
              ),
              Tab(
                child: Text(
                  'CONTACTS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                  ),
                ),
              ),
              Tab(
                child: Text(
                  'PROFILE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                  ),
                ),
              ),
              Tab(
                child: Text(
                  'LOGS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: primaryColor,
          elevation: 5.0,
        ),
        body: TabBarView(
          children: [
            ShareRoomWidget(),
            ContactWidget(),
            ProfileWidget(),
            LoggingWidget(),
          ],
        ),
      ),
    );
  }
}
