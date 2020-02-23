import 'dart:convert';

import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:owl/DIContainer.dart';
import 'package:owl/contact/events/events.dart';
import 'package:owl/contact/managers/ContactManager.dart';
import 'package:owl/share_room/models/UserModel.dart';

class SearchUsersWidget extends StatelessWidget {
  final ContactManager _contactManager = DIContainer.resolve<ContactManager>();

  @override
  Widget build(BuildContext context) {
    print('===== Build SearchUsersWidget =====');

    return Column(
      children: <Widget>[
        ExpandablePanel(
          header: Container(
            margin: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0.0),
            height: 50.0,
            padding: EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.all(Radius.circular(30.0)),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.expand_more,
                  color: Colors.white,
                ),
                SizedBox(width: 5.0),
                Text(
                  'SEARCH',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          expanded: Column(
            children: <Widget>[
              Container(
                margin: EdgeInsets.fromLTRB(30.0, 10.0, 30.0, 0.0),
                height: 50.0,
                padding: EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.all(Radius.circular(30.0)),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.alternate_email,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8.0),
                    Expanded(
                      child: StreamBuilder<String>(
                        stream: _contactManager.emailUsernameId$,
                        builder: (context, snapshot) {
                          return TextField( // @@TODO: Show error
                            onChanged: (value) {
                              _contactManager.inEvent.add(
                                ValidateSearchUsersFormEvent(
                                  emailUsernameId: value,
                                ),
                              );
                            },
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Email / Username / Id',
                              hintStyle: TextStyle(
                                color: Colors.white,
                                fontSize: 14.0,
                                fontStyle: FontStyle.italic,
                              ),
                              suffixIcon: StreamBuilder<bool>(
                                // @@TODO: Make icon not nested
                                stream: _contactManager.searchUsersFormIsValid$,
                                builder: (context, snapshot) {
                                  return GestureDetector(
                                    onTap: () {
                                      if (snapshot.hasData && snapshot.data) {
                                        _contactManager.inEvent.add(
                                          SearchUsersEvent(),
                                        );
                                      }
                                    },
                                    child: Icon(
                                      Icons.search,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.fromLTRB(30.0, 10.0, 30.0, 0.0),
                height: 50.0,
                padding: EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.all(Radius.circular(30.0)),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8.0),
                    Text(
                      'Scan QR-code',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.0,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          theme: ExpandableThemeData(hasIcon: false),
        ),
        SizedBox(height: 15.0),
        Expanded(
          child: Container(
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(20.0)),
              child: StreamBuilder<List<UserModel>>(
                stream: _contactManager.searchUsers$,
                builder: (context, snapshot) {
                  List<UserModel> users = snapshot.data;

                  return ListView.builder(
                    itemCount: users?.length ?? 0,
                    itemBuilder: (context, index) {
                      var user = users[index];

                      return Container(
                        margin: EdgeInsets.only(
                          bottom: index == users.length - 1 ? 0.0 : 10.0,
                          right: 40.0,
                        ),
                        padding: EdgeInsets.fromLTRB(25, 10, 20, 10),
                        decoration: BoxDecoration(
                          color: Color(0xff464866),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(20.0),
                            bottomRight: Radius.circular(20.0),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                CircleAvatar(
                                  radius: 35.0,
                                  backgroundImage: user.profilePicture == null
                                      ? AssetImage(
                                          'assets/images/profile_picture.jpg',
                                        )
                                      : MemoryImage(user.profilePicture),
                                ),
                                SizedBox(width: 15.0),
                                Text(
                                  utf8.decode(user.username),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                GestureDetector(
                                  onTap: () {
                                    _contactManager.inEvent.add(
                                      AddContactEvent(userId: user.id),
                                    );
                                  },
                                  child: Icon(
                                    Icons.person_add,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
