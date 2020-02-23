import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:owl/DIContainer.dart';
import 'package:owl/general/screens/HomeScreen.dart';
import 'package:owl/share_room/enums/ShareItemStatus.dart';
import 'package:owl/share_room/events/events.dart';
import 'package:owl/share_room/managers/ShareRoomManager.dart';
import 'package:owl/share_room/models/ShareItemModel.dart';
import 'package:owl/share_room/models/ShareRoomModel.dart';
import 'package:owl/share_room/models/UserModel.dart';

class ShareRoomDetailScreen extends StatefulWidget {
  final ShareRoomModel shareRoom;

  ShareRoomDetailScreen({Key key, @required this.shareRoom}) : super(key: key);

  @override
  _ShareRoomDetailScreenState createState() => _ShareRoomDetailScreenState();
}

class _ShareRoomDetailScreenState extends State<ShareRoomDetailScreen> {
  final ShareRoomManager _shareRoomManager =
      DIContainer.resolve<ShareRoomManager>();

  TextEditingController _textController;
  String _message;

  ScrollController _scrollController;
  bool _isFetchingShareItems;
  int _offset;

  @override
  void initState() {
    super.initState();

    _textController = TextEditingController();

    _shareRoomManager.inEvent.add(
      InitializeRoomEvent(
        roomIdentifier: widget.shareRoom.identifier,
      ),
    );

    _scrollController = ScrollController();
    _isFetchingShareItems = false;
    _offset = 0;

    _scrollController.addListener(
      () async {
        if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent) {
          if (!_isFetchingShareItems) {
            setState(() {
              _isFetchingShareItems = true;
            });

            int prevOffset = _offset;

            _shareRoomManager.inEvent.add(
              GetShareItemsFromRoomEvent(offset: _offset),
            );

            List<ShareItemModel> shareItems =
                await _shareRoomManager.getShareItemsFromRoom$.first;

            if (shareItems.length == prevOffset) {
              double edge = 50.0;
              double margin = _scrollController.position.maxScrollExtent -
                  _scrollController.position.pixels;
              if (margin < edge) {
                _scrollController.animateTo(
                  _scrollController.offset - (edge - margin),
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                );
              }
            }

            setState(() {
              _isFetchingShareItems = false;
            });
          }
        }
      },
    );
  }

  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _shareRoomManager.inEvent.add(CloseRoomEvent());

    super.dispose();
  }

  Widget _buildShareItem(BuildContext context, ShareItemModel shareItem) {
    bool isFromMe = shareItem.status != null;

    Widget statusWidget;
    if (isFromMe) {
      switch (shareItem.status) {
        case ShareItemStatus.NotReceived:
          statusWidget = Icon(Icons.check);
          break;
        case ShareItemStatus.ReceivedNotRead:
          statusWidget = Icon(Icons.check_circle_outline);
          break;
        case ShareItemStatus.Read:
          statusWidget = Icon(
            Icons.check_circle_outline,
            color: Colors.green,
          );
          break;
      }
    }

    List<Widget> contentWidgets = [];
    if (!isFromMe) {
      contentWidgets.addAll([
        Text(
          shareItem.creator != null
              ? utf8.decode(shareItem.creator.username)
              : shareItem.creatorId.toString(),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.0),
      ]);
    }

    if (shareItem.content != null) {
      contentWidgets.add(
        Text(
          utf8.decode(shareItem.content),
          style: TextStyle(
            color: Colors.blueGrey,
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (shareItem.thumbnails != null) {
      contentWidgets.addAll(
        shareItem.thumbnails.map((thumbnail) => Image.memory(thumbnail)),
      );
    }

    var time = DateTime.fromMillisecondsSinceEpoch(shareItem.timeOfCreation);
    var minutes = time.minute < 10 ? '0${time.minute}' : '${time.minute}';

    return Row(
      mainAxisAlignment:
          isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: <Widget>[
        if (isFromMe)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: statusWidget,
          ),
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: EdgeInsets.symmetric(vertical: 8.0),
          padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
          decoration: BoxDecoration(
            color: isFromMe ? Colors.amber[200] : Color(0xFFFFEFEE),
            borderRadius: isFromMe
                ? BorderRadius.only(
                    topLeft: Radius.circular(15.0),
                    bottomLeft: Radius.circular(15.0),
                  )
                : BorderRadius.only(
                    topRight: Radius.circular(15.0),
                    bottomRight: Radius.circular(15.0),
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${time.hour}:$minutes',
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.0),
              ...contentWidgets,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      constraints: BoxConstraints(minHeight: 70.0),
      color: Colors.white,
      child: Row(
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.photo),
            iconSize: 25.0,
            color: primaryColor,
            onPressed: () async {
              List<Asset> imageAssets =
                  await MultiImagePicker.pickImages(maxImages: 10);

              if (imageAssets != null && imageAssets.isNotEmpty) {
                _shareRoomManager.inEvent.add(
                  AttachImagesEvent(imageAssets: imageAssets),
                );
              }
            },
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              onChanged: (value) {
                _message = value;
                _shareRoomManager.inEvent.add(IsTypingEvent());
              },
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.all(8.0),
                hintText: 'Type your message here',
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            iconSize: 25.0,
            color: primaryColor,
            onPressed: () {
              _shareRoomManager.inEvent.add(
                CreateShareItemEvent(text: _message),
              );
              _textController.clear();
              _message = null;
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('===== Build ShareRoomDetailScreen =====');

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: Text(
          widget.shareRoom.name,
          style: TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.more_horiz),
            iconSize: 30.0,
            color: Colors.white,
            onPressed: () {},
          ),
        ],
        elevation: 0.0,
        backgroundColor: primaryColor,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(30.0),
                    topLeft: Radius.circular(30.0),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(30.0),
                    topLeft: Radius.circular(30.0),
                  ),
                  child: StreamBuilder<List<ShareItemModel>>(
                    stream: _shareRoomManager.getShareItemsFromRoom$,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      List<ShareItemModel> shareItems = snapshot.data;
                      _offset = shareItems.length;

                      return ListView.builder(
                        padding: EdgeInsets.only(top: 15.0),
                        reverse: true,
                        itemCount: shareItems.length + 2, // 0..4 | 0..6
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return StreamBuilder<List<UserModel>>(
                              stream: _shareRoomManager.notifyTyping$,
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return Text('');
                                }

                                List<Widget> widgets = [];
                                snapshot.data.forEach(
                                  (user) => {
                                    widgets.add(
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8.0,
                                        ),
                                        child: Text(
                                          user.username != null
                                              ? '${utf8.decode(user.username)} is typing...'
                                              : '${user.id} is typing...',
                                        ),
                                      ),
                                    )
                                  },
                                );

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: widgets,
                                    ),
                                  ],
                                );
                              },
                            );
                          }

                          if (index == shareItems.length + 1) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                child: Opacity(
                                  opacity: _isFetchingShareItems ? 1.0 : 0.0,
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            );
                          }

                          return _buildShareItem(
                            context,
                            shareItems[shareItems.length - index],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            _buildMessageComposer(),
          ],
        ),
      ),
    );
  }
}
