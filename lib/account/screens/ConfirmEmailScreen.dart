import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:owl/DIContainer.dart';
import 'package:owl/account/events/events.dart';
import 'package:owl/account/managers/AccountManager.dart';
import 'package:owl/navigator/Routes.dart';
import 'package:owl/share_room/events/events.dart';
import 'package:owl/share_room/managers/ShareRoomManager.dart';

// @@REFACTORME
final kErrorTextStyle = TextStyle(
  color: Colors.white54,
  fontFamily: 'OpenSans',
);

final kLabelStyle = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.bold,
  fontFamily: 'OpenSans',
);

final kBoxDecorationStyle = BoxDecoration(
  color: Color(0xFF6CA8F1),
  borderRadius: BorderRadius.circular(10.0),
  boxShadow: [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 6.0,
      offset: Offset(0, 2),
    ),
  ],
);

class ConfirmEmailScreen extends StatefulWidget {
  @override
  _ConfirmEmailScreenState createState() => _ConfirmEmailScreenState();
}

class _ConfirmEmailScreenState extends State<ConfirmEmailScreen> {
  final AccountManager _accountManager = DIContainer.resolve<AccountManager>();
  final ShareRoomManager _shareRoomManager =
      DIContainer.resolve<ShareRoomManager>();

  StreamSubscription<String> _confirmEmail$$;

  @override
  void initState() {
    super.initState();

    _confirmEmail$$ = _accountManager.confirmEmail$.listen((_) async {
      _shareRoomManager.inEvent.add(JoinEvent());
      await _shareRoomManager.join$.first;

      Navigator.of(context).pushReplacementNamed(Routes.HomeScreen);
    });
  }

  @override
  void dispose() {
    _accountManager.resetConfirmEmailFormSubjects();
    _confirmEmail$$.cancel();

    super.dispose();
  }

  Widget _buildConfirmationCodeTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        StreamBuilder<String>(
            stream: _accountManager.confirmationCode$,
            builder: (context, snapshot) {
              return Text(
                snapshot.error?.toString() ?? 'Code',
                style: kLabelStyle,
              );
            }),
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: kBoxDecorationStyle,
          height: 60.0,
          child: TextField(
            onChanged: (value) {
              _accountManager.inEvent.add(
                ValidateConfirmEmailFormEvent(confirmationCode: value),
              );
            },
            keyboardType: TextInputType.number,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'OpenSans',
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.verified_user,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmBtn() {
    return Container(
      // padding: EdgeInsets.symmetric(vertical: 25.0),
      width: double.infinity,
      child: StreamBuilder<bool>(
        stream: _accountManager.confirmEmailFormIsValid$,
        builder: (context, snapshot) {
          return RaisedButton(
            elevation: 5.0,
            onPressed: () {
              if (snapshot.hasData && snapshot.data) {
                _accountManager.inEvent.add(ConfirmEmailEvent());
              }

              FocusScopeNode currentFocus = FocusScope.of(context);
              if (!currentFocus.hasPrimaryFocus) {
                currentFocus.unfocus();
              }
            },
            padding: EdgeInsets.all(15.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            color: Colors.white,
            child: Text(
              'CONFIRM',
              style: TextStyle(
                color: Color(0xFF527DAA),
                letterSpacing: 1.5,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'OpenSans',
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
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
              Container(
                height: double.infinity,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: 40.0,
                    vertical: 120.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Confirmation code was sent to your email',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'OpenSans',
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 30.0),
                      _buildConfirmationCodeTF(),
                      SizedBox(height: 30.0),
                      _buildConfirmBtn(),
                      StreamBuilder<String>(
                        stream: _accountManager.confirmEmail$,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 30.0),
                              child: Text(
                                snapshot.error.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'OpenSans',
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }

                          return Text('');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
