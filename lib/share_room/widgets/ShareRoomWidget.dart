import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:owl/general/screens/HomeScreen.dart';
import 'package:owl/share_room/widgets/FavoriteContactsWidget.dart';
import 'package:owl/share_room/widgets/ShareRoomListWidget.dart';

class ShareRoomWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('===== Build ShareRoomWidget =====');

    return Container(
      padding: const EdgeInsets.fromLTRB(10.0, 30.0, 10.0, 10.0),
      color: primaryColor,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xff000428),
              Color(0xff004e92),
            ],
          ),
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
        ),
        child: Column(
          children: <Widget>[
            ExpandablePanel(
              header: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.expand_more,
                      color: Colors.white,
                    ),
                    SizedBox(width: 5.0),
                    Text(
                      'FAVORITE CONTACTS',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              expanded: FavoriteContactsWidget(),
              theme: ExpandableThemeData(hasIcon: false),
              // controller: ExpandableController(initialExpanded: true),
            ),
            ShareRoomListWidget(),
          ],
        ),
      ),
    );
  }
}
