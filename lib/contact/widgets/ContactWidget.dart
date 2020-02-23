import 'package:flutter/material.dart';
import 'package:owl/contact/widgets/MyContactsWidget.dart';
import 'package:owl/contact/widgets/SearchUsersWidget.dart';
import 'package:owl/general/screens/HomeScreen.dart';

class ContactWidget extends StatefulWidget {
  @override
  _ContactWidgetState createState() => _ContactWidgetState();
}

class _ContactWidgetState extends State<ContactWidget> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    print('===== Build ContactWidget =====');

    return Container(
      color: primaryColor,
      child: Stack(
        children: <Widget>[
          Container(
            margin: const EdgeInsets.fromLTRB(10.0, 30.0, 10.0, 10.0),
            padding: EdgeInsets.only(top: 20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xff4b6cb7),
                  Color(0xff182848),
                ],
              ),
              borderRadius: BorderRadius.all(Radius.circular(20.0)),
            ),
            child: IndexedStack(
              index: _currentIndex,
              children: <Widget>[
                MyContactsWidget(),
                SearchUsersWidget(),
              ],
            ),
          ),
          Positioned(
            top: 12.0,
            right: 10.0,
            child: Container(
              width: 90.0,
              height: 36.0,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentIndex = 0;
                      });
                    },
                    child: Icon(
                      Icons.import_contacts,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentIndex = 1;
                      });
                    },
                    child: Icon(
                      Icons.search,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
