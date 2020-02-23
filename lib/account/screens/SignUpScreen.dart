import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:owl/DIContainer.dart';
import 'package:owl/account/events/events.dart';
import 'package:owl/account/managers/AccountManager.dart';
import 'package:owl/navigator/Routes.dart';

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

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final AccountManager _accountManager = DIContainer.resolve<AccountManager>();

  StreamSubscription<String> _signUp$$;

  @override
  void initState() {
    super.initState();

    _signUp$$ = _accountManager.signUp$.listen((_) {
      Navigator.of(context).pushReplacementNamed(Routes.ConfirmEmailScreen);
    });
  }

  @override
  void dispose() {
    _accountManager.resetSignUpFormSubjects();
    _signUp$$.cancel();

    super.dispose();
  }

  Widget _buildEmailTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        StreamBuilder<String>(
            stream: _accountManager.email$,
            builder: (context, snapshot) {
              return Text(
                snapshot.error?.toString() ?? 'Email',
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
                ValidateSignUpFormEvent(email: value),
              );
            },
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'OpenSans',
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.email,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        StreamBuilder<String>(
            stream: _accountManager.username$,
            builder: (context, snapshot) {
              return Text(
                snapshot.error?.toString() ?? 'Username',
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
                ValidateSignUpFormEvent(username: value),
              );
            },
            keyboardType: TextInputType.text,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'OpenSans',
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.text_fields,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        StreamBuilder<String>(
            stream: _accountManager.password$,
            builder: (context, snapshot) {
              return Text(
                snapshot.error?.toString() ?? 'Password',
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
                ValidateSignUpFormEvent(password: value),
              );
            },
            obscureText: true,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'OpenSans',
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.lock,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Widget _buildForgotPasswordBtn() {
  //   return Container(
  //     alignment: Alignment.centerRight,
  //     child: FlatButton(
  //       onPressed: () => print('Forgot Password Button Pressed'),
  //       padding: EdgeInsets.only(right: 0.0),
  //       child: Text(
  //         'Forgot Password?',
  //         style: kLabelStyle,
  //       ),
  //     ),
  //   );
  // }

  Widget _buildSignUpBtn() {
    return Container(
      // padding: EdgeInsets.symmetric(vertical: 25.0),
      width: double.infinity,
      child: StreamBuilder<bool>(
        stream: _accountManager.signUpFormIsValid$,
        builder: (context, snapshot) {
          return RaisedButton(
            elevation: 5.0,
            onPressed: () {
              if (snapshot.hasData && snapshot.data) {
                _accountManager.inEvent.add(SignUpEvent());
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
              'SIGN UP',
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

  // Widget _buildSignupBtn() {
  //   return GestureDetector(
  //     onTap: () => print('Sign Up Button Pressed'),
  //     child: RichText(
  //       text: TextSpan(
  //         children: [
  //           TextSpan(
  //             text: 'Don\'t have an Account? ',
  //             style: TextStyle(
  //               color: Colors.white,
  //               fontSize: 18.0,
  //               fontWeight: FontWeight.w400,
  //             ),
  //           ),
  //           TextSpan(
  //             text: 'Sign Up',
  //             style: TextStyle(
  //               color: Colors.white,
  //               fontSize: 18.0,
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    print('===== Build SignUpScreen =====');

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
                    vertical: 80.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'OpenSans',
                          fontSize: 30.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 30.0),
                      _buildEmailTF(),
                      SizedBox(height: 30.0),
                      _buildUsernameTF(),
                      SizedBox(height: 30.0),
                      _buildPasswordTF(),
                      SizedBox(height: 30.0),
                      _buildSignUpBtn(),
                      StreamBuilder<String>(
                        stream: _accountManager.signUp$,
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
