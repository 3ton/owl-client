import 'package:flutter/material.dart';
import 'package:owl/DIContainer.dart';
import 'package:owl/account/events/events.dart';
import 'package:owl/account/managers/AccountManager.dart';
import 'package:owl/navigator/Routes.dart';
import 'package:owl/share_room/events/events.dart';
import 'package:owl/share_room/managers/ShareRoomManager.dart';

import 'logging/managers/LoggingManager.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // final LoggingManager _loggingManager = DIContainer.resolve<LoggingManager>();

  @override
  void initState() {
    super.initState();

    var accountManager = DIContainer.resolve<AccountManager>();
    accountManager.inEvent.add(LoadAccountEvent());

    accountManager.loadAccount$.first.then((account) async {
      if (account == null) {
        Navigator.of(context).pushReplacementNamed(Routes.SignUpScreen);
      } else if (!account.isConfirmed) {
        Navigator.of(context).pushReplacementNamed(Routes.ConfirmEmailScreen);
      } else {
        accountManager.inEvent.add(SignInEvent());
        await accountManager.signIn$.first;

        var shareRoomManager = DIContainer.resolve<ShareRoomManager>();
        shareRoomManager.inEvent.add(JoinEvent());

        await shareRoomManager.join$.first;

        Navigator.of(context).pushReplacementNamed(Routes.HomeScreen);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print('===== Build SplashScreen =====');

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF73AEF5),
                  Color(0xFF61A4F1),
                  Color(0xFF478DE0),
                  Color(0xFF398AE5),
                ],
                stops: [0.1, 0.4, 0.7, 0.9],
              ),
            ),
          ),
          // GestureDetector(
          //   onTap: () {
          //     _loggingManager.getLogs();
          //   },
          //   child: Container(
          //     padding: const EdgeInsets.fromLTRB(10.0, 30.0, 10.0, 10.0),
          //     color: Colors.yellow,
          //     child: GestureDetector(
          //       onTap: () {
          //         _loggingManager.getLogs();
          //       },
          //       child: Container(
          //         decoration: BoxDecoration(
          //           gradient: LinearGradient(
          //             begin: Alignment.topCenter,
          //             end: Alignment.bottomCenter,
          //             colors: [
          //               Color(0xff000428),
          //               Color(0xff004e92),
          //             ],
          //           ),
          //           borderRadius: BorderRadius.all(Radius.circular(20.0)),
          //         ),
          //         child: StreamBuilder<List<String>>(
          //           stream: _loggingManager.getLogs$,
          //           builder: (context, snapshot) {
          //             List<String> logs = snapshot.data;

          //             return ListView.builder(
          //               itemCount: logs?.length ?? 0,
          //               itemBuilder: (context, index) {
          //                 String message = logs[index];

          //                 return Container(
          //                   margin: EdgeInsets.only(
          //                     bottom: index == logs.length - 1 ? 0.0 : 10.0,
          //                     right: 20.0,
          //                   ),
          //                   padding: EdgeInsets.symmetric(
          //                     horizontal: 20.0,
          //                     vertical: 10.0,
          //                   ),
          //                   decoration: BoxDecoration(
          //                     color: Color(0xFFe7717d),
          //                     borderRadius: BorderRadius.only(
          //                       topRight: Radius.circular(20.0),
          //                       bottomRight: Radius.circular(20.0),
          //                     ),
          //                   ),
          //                   child: SingleChildScrollView(
          //                     scrollDirection: Axis.horizontal,
          //                     child: Row(
          //                       children: <Widget>[
          //                         SelectableText(message),
          //                       ],
          //                     ),
          //                   ),
          //                 );
          //               },
          //             );
          //           },
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
