import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:owl/DIContainer.dart';
import 'package:owl/call/CallInfo.dart';
import 'package:owl/call/enums/MediaType.dart';
import 'package:owl/contact/events/events.dart';
import 'package:owl/contact/managers/ContactManager.dart';
import 'package:owl/navigator/Routes.dart';
import 'package:owl/share_room/events/events.dart';
import 'package:owl/share_room/managers/ShareRoomManager.dart';
import 'package:owl/share_room/models/UserModel.dart';

// @@REFACTORME
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

class MyContactsWidget extends StatefulWidget {
  @override
  _MyContactsWidgetState createState() => _MyContactsWidgetState();
}

class _MyContactsWidgetState extends State<MyContactsWidget> {
  final ContactManager _contactManager = DIContainer.resolve<ContactManager>();
  final ShareRoomManager _shareRoomManager =
      DIContainer.resolve<ShareRoomManager>();

  bool _chooseUsersMode;
  Set<int> _chosenUsers;
  String _roomName;

  @override
  void initState() {
    super.initState();
    _chooseUsersMode = false;
    _chosenUsers = Set<int>();
    _roomName = null;
  }

  @override
  Widget build(BuildContext context) {
    print('===== Build MyContactsWidget =====');

    _contactManager.inEvent.add(GetMyContactsEvent());

    return Column(
      children: <Widget>[
        Container(
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
                Icons.import_contacts,
                color: Colors.white,
              ),
              SizedBox(width: 5.0),
              Text(
                'MY CONTACTS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              !_chooseUsersMode
                  ? GestureDetector(
                      onTap: () {
                        setState(() {
                          _chooseUsersMode = true;
                          _chosenUsers.clear();
                        });
                      },
                      child: Icon(
                        Icons.group,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _chooseUsersMode = false;
                            });
                          },
                          child: Icon(
                            Icons.cancel,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10.0),
                        GestureDetector(
                          onTap: () async {
                            if (_chosenUsers.isNotEmpty) {
                              await showDialog<String>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text('Room Name'),
                                        SizedBox(height: 10.0),
                                        Container(
                                          alignment: Alignment.centerLeft,
                                          decoration: kBoxDecorationStyle,
                                          height: 60.0,
                                          child: TextField(
                                            onChanged: (value) {
                                              _roomName = value;
                                            },
                                            keyboardType: TextInputType.text,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontFamily: 'OpenSans',
                                            ),
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding:
                                                  EdgeInsets.only(top: 14.0),
                                              prefixIcon: Icon(
                                                Icons.text_fields,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: <Widget>[
                                      FlatButton(
                                        child: Text('Ok'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (_roomName != null && _roomName.isNotEmpty) {
                                _shareRoomManager.inEvent.add(
                                  CreateShareRoomEvent(
                                    users: _chosenUsers,
                                    roomName: _roomName,
                                  ),
                                );
                              }
                            }

                            setState(() {
                              _chooseUsersMode = false;
                            });
                          },
                          child: Icon(
                            Icons.forward,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
              // SizedBox(width: 40.0),
              // Expanded(
              //   child: TextField(
              //     style: TextStyle(
              //       fontSize: 14.0,
              //       color: Colors.white,
              //     ),
              //     decoration: InputDecoration(
              //       enabledBorder: OutlineInputBorder(
              //         borderRadius: BorderRadius.all(
              //           Radius.circular(20.0),
              //         ),
              //         borderSide: BorderSide(color: Colors.white),
              //       ),
              //       focusedBorder: OutlineInputBorder(
              //         borderRadius: BorderRadius.all(
              //           Radius.circular(20.0),
              //         ),
              //         borderSide: BorderSide(color: Colors.white),
              //       ),
              //       contentPadding: EdgeInsets.only(left: 10.0),
              //       hintText: 'Search...',
              //       hintStyle: TextStyle(
              //         color: Colors.white,
              //         fontSize: 14.0,
              //       ),
              //       suffixIcon: Icon(
              //         Icons.search,
              //         color: Colors.white,
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
        SizedBox(height: 15.0),
        Expanded(
          child: Container(
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(20.0)),
              child: StreamBuilder<List<UserModel>>(
                stream: _contactManager.getMyContacts$,
                builder: (context, snapshot) {
                  List<UserModel> users = snapshot.data;

                  return ListView.builder(
                    itemCount: users?.length ?? 0,
                    itemBuilder: (context, index) {
                      var user = users[index];

                      return GestureDetector(
                        onTap: () {
                          if (_chooseUsersMode) {
                            if (_chosenUsers.contains(user.id)) {
                              _chosenUsers.remove(user.id);
                            } else {
                              _chosenUsers.add(user.id);
                            }

                            setState(() {});
                          }
                        },
                        child: Container(
                          margin: EdgeInsets.only(
                            bottom: index == users.length - 1 ? 0.0 : 10.0,
                            right: 40.0,
                          ),
                          padding: EdgeInsets.fromLTRB(25, 10, 20, 10),
                          decoration: BoxDecoration(
                            color: _chooseUsersMode &&
                                    _chosenUsers.contains(user.id)
                                ? Colors.red
                                : Color(0xff464866),
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
                                  // user.isFavorite
                                  //     ? Icon(
                                  //         Icons.star,
                                  //         color: Colors.white,
                                  //       )
                                  //     : Icon(
                                  //         Icons.star_border,
                                  //         color: Colors.white,
                                  //       ),
                                  // SizedBox(width: 15.0),
                                  GestureDetector(
                                    onTap: () {
                                      _shareRoomManager.inEvent.add(
                                        CreateShareRoomEvent(
                                          users: Set<int>()..add(user.id),
                                        ),
                                      );
                                    },
                                    child: Icon(
                                      Icons.chat,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 15.0),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).pushNamed(
                                        Routes.CallScreen,
                                        arguments: CallInfo(
                                          user: user,
                                          isCaller: true,
                                          media: MediaType.Audio,
                                        ),
                                      );
                                    },
                                    child: Icon(
                                      Icons.call,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 15.0),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).pushNamed(
                                        Routes.CallScreen,
                                        arguments: CallInfo(
                                          user: user,
                                          isCaller: true,
                                          media: MediaType.Video,
                                          screenShare: false,
                                        ),
                                      );
                                    },
                                    child: Icon(
                                      Icons.video_call,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
