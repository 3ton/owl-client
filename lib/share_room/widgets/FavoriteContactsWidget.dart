import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:owl/DIContainer.dart';
import 'package:owl/contact/events/events.dart';
import 'package:owl/contact/managers/ContactManager.dart';
import 'package:owl/share_room/models/UserModel.dart';

class FavoriteContactsWidget extends StatelessWidget {
  final ContactManager _contactManager = DIContainer.resolve<ContactManager>();

  @override
  Widget build(BuildContext context) {
    print('===== Build FavoriteContactsWidget =====');

    _contactManager.inEvent.add(GetFavoriteContactsEvent());

    return Container(
      height: 110.0,
      child: StreamBuilder<List<UserModel>>(
        stream: _contactManager.getFavoriteContacts$,
        builder: (context, snapshot) {
          List<UserModel> users = snapshot.data;

          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 10.0),
            scrollDirection: Axis.horizontal,
            itemCount: users?.length ?? 0,
            itemBuilder: (context, index) {
              var user = users[index];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 35.0,
                      backgroundImage: user.profilePicture == null
                          ? AssetImage('assets/images/profile_picture.jpg')
                          : MemoryImage(user.profilePicture),
                    ),
                    SizedBox(height: 6.0),
                    Text(
                      utf8.decode(user.username),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
