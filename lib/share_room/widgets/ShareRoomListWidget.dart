import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:owl/DIContainer.dart';
import 'package:owl/general/screens/HomeScreen.dart';
import 'package:owl/navigator/Routes.dart';
import 'package:owl/share_room/enums/ShareItemAckedStatus.dart';
import 'package:owl/share_room/enums/ShareItemType.dart';
import 'package:owl/share_room/events/events.dart';
import 'package:owl/share_room/managers/ShareRoomManager.dart';
import 'package:owl/share_room/models/ShareItemModel.dart';
import 'package:owl/share_room/models/ShareRoomModel.dart';

class ShareRoomListWidget extends StatelessWidget {
  final ShareRoomManager _shareRoomManager =
      DIContainer.resolve<ShareRoomManager>();

  @override
  Widget build(BuildContext context) {
    print('===== Build ShareRoomListWidget =====');

    _shareRoomManager.inEvent.add(GetShareRoomsWithLatestItemEvent());

    return Expanded(
      child: Container(
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
          child: StreamBuilder<List<ShareRoomModel>>(
            stream: _shareRoomManager.getShareRoomsWithLatestItem$,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              List<ShareRoomModel> shareRooms = snapshot.data;

              return ListView.builder(
                itemCount: shareRooms.length,
                itemBuilder: (context, index) {
                  var shareRoom = shareRooms[index];
                  ShareItemModel latestShareItem = shareRoom.latestItem;

                  Widget contentWidget;
                  if (shareRoom.currentlyTypingGuy != null) {
                    contentWidget = Text(
                      shareRoom.currentlyTypingGuy.username != null
                          ? '${utf8.decode(shareRoom.currentlyTypingGuy.username)} is typing...'
                          : '${shareRoom.currentlyTypingGuy.id} is typing...',
                    );
                  } else {
                    if (latestShareItem == null) {
                      contentWidget = Text('');
                    } else {
                      switch (latestShareItem.type) {
                        case ShareItemType.Text:
                          contentWidget = Text(
                            utf8.decode(latestShareItem.content),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.0,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          );
                          break;
                        default:
                          contentWidget = Icon(
                            Icons.image,
                            color: Colors.white,
                          );
                          break;
                      }
                    }
                  }

                  Widget timeWidget;
                  if (latestShareItem == null) {
                    timeWidget = Text('');
                  } else {
                    var time = DateTime.fromMillisecondsSinceEpoch(
                      latestShareItem.timeOfCreation,
                    );

                    timeWidget = Text(
                      '${time.hour}:${time.minute}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }

                  bool isRead = latestShareItem == null ||
                      latestShareItem.ackedStatus == null ||
                      latestShareItem.ackedStatus ==
                          ShareItemAckedStatus.AckedRead;

                  return GestureDetector(
                    onTap: () async {
                      await Navigator.of(context).pushNamed(
                        Routes.ShareRoomDetailScreen,
                        arguments: shareRoom,
                      );

                      _shareRoomManager.inEvent.add(
                        GetShareRoomsWithLatestItemEvent(),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.only(
                        bottom: index == shareRooms.length - 1 ? 0.0 : 10.0,
                        right: 20.0,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10.0,
                      ),
                      decoration: BoxDecoration(
                        color: isRead ? Color(0xff464866) : Color(0xFFe7717d),
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
                                backgroundImage:
                                    shareRoom.otherGuy?.profilePicture == null
                                        ? AssetImage('assets/images/chat.png')
                                        : MemoryImage(
                                            shareRoom.otherGuy.profilePicture,
                                          ),
                              ),
                              SizedBox(width: 10.0),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    shareRoom.name,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 5.0),
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.4,
                                    child: contentWidget,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            children: <Widget>[
                              timeWidget,
                              SizedBox(height: 5.0),
                              if (shareRoom.unreadCount > 0)
                                Container(
                                  width: 40.0,
                                  height: 20.0,
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    shareRoom.unreadCount.toString(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          )
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
    );
  }
}
