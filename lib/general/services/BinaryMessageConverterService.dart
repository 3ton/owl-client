import 'dart:convert';
import 'dart:typed_data';

import 'package:owl/account/messages/ConfirmEmailMessage.dart';
import 'package:owl/account/messages/SignUpMessage.dart';
import 'package:owl/account/server_messages/SuccessfulLogInServerMessage.dart';
import 'package:owl/account/server_messages/SuccessfulSignUpServerMessage.dart';
import 'package:owl/call/enums/MediaType.dart';
import 'package:owl/call/messages/WebRtcAnswerMessage.dart';
import 'package:owl/call/messages/WebRtcCandidateMessage.dart';
import 'package:owl/call/messages/WebRtcInquireMessage.dart';
import 'package:owl/call/messages/WebRtcMessage.dart';
import 'package:owl/call/messages/WebRtcOfferMessage.dart';
import 'package:owl/call/server_messages/WebRtcAnswerServerMessage.dart';
import 'package:owl/call/server_messages/WebRtcCandidateServerMessage.dart';
import 'package:owl/call/server_messages/WebRtcInquireServerMessage.dart';
import 'package:owl/call/server_messages/WebRtcOfferServerMessage.dart';
import 'package:owl/call/server_messages/WebRtcServerMessage.dart';
import 'package:owl/contact/messages/SearchUsersMessage.dart';
import 'package:owl/general/messages/Message.dart';
import 'package:owl/general/messages/MessageCode.dart';
import 'package:owl/general/server_messages/ServerMessage.dart';
import 'package:owl/general/services/IMessageConverterService.dart';
import 'package:owl/share_room/enums/RoomMembershipOperationType.dart';
import 'package:owl/share_room/enums/ShareItemType.dart';
import 'package:owl/share_room/messages/AckReadMessage.dart';
import 'package:owl/share_room/messages/AckReceiveMessage.dart';
import 'package:owl/share_room/messages/AckReceiveReadMessage.dart';
import 'package:owl/share_room/messages/AckRoomMembershipOperationMessage.dart';
import 'package:owl/share_room/messages/AddFirebaseUserMessage.dart';
import 'package:owl/share_room/messages/CreateShareItemMessage.dart';
import 'package:owl/share_room/messages/CreateShareRoomMessage.dart';
import 'package:owl/share_room/messages/DeleteAcksMessage.dart';
import 'package:owl/share_room/messages/GetUsersMessage.dart';
import 'package:owl/share_room/messages/IsTypingMessage.dart';
import 'package:owl/share_room/messages/JoinMessage.dart';
import 'package:owl/share_room/models/AckModel.dart';
import 'package:owl/share_room/models/RoomMembershipNotificationModel.dart';
import 'package:owl/share_room/models/ShareItemModel.dart';
import 'package:owl/share_room/models/ShareRoomModel.dart';
import 'package:owl/share_room/models/UserModel.dart';
import 'package:owl/share_room/server_messages/AckReadServerMessage.dart';
import 'package:owl/share_room/server_messages/AckServerMessage.dart';
import 'package:owl/share_room/server_messages/InvitedToShareRoomServerMessage.dart';
import 'package:owl/share_room/server_messages/IsTypingServerMessage.dart';
import 'package:owl/share_room/server_messages/JoinedServerMessage.dart';
import 'package:owl/share_room/server_messages/NewPalsServerMessage.dart';
import 'package:owl/share_room/server_messages/NewShareItemServerMessage.dart';
import 'package:owl/share_room/server_messages/PalLeftServerMessage.dart';
import 'package:owl/share_room/server_messages/ShareRoomInvitationServerMessage.dart';
import 'package:owl/share_room/server_messages/SuccessfulShareItemCreationServerMessage.dart';
import 'package:owl/share_room/server_messages/SuccessfulShareRoomCreationServerMessage.dart';
import 'package:owl/share_room/server_messages/UsersServerMessage.dart';
import 'package:uuid/uuid.dart';

class BinaryMessageConverterService implements IMessageConverterService {
  final Uuid _uuid;

  BinaryMessageConverterService(this._uuid);

  void _setMessageLength(List<int> message) {
    var byteData = Uint8List(4).buffer.asByteData();
    byteData.setInt32(0, message.length - 4);
    var messageLengthBytes = byteData.buffer.asUint8List();
    message[0] = messageLengthBytes[0];
    message[1] = messageLengthBytes[1];
    message[2] = messageLengthBytes[2];
    message[3] = messageLengthBytes[3];
  }

  List<int> _encodeSignUpMessage(SignUpMessage msg) {
    // XXXX SignUp Req L1 Email L1 Username Password
    var message = List<int>();
    message.addAll(List.filled(4, 0));
    message.add(MessageCode.SignUp.index);
    message.addAll(_uuid.parse(msg.requestIdentifier));
    List<int> emailBytes = utf8.encode(msg.email);
    message.add(emailBytes.length);
    message.addAll(emailBytes);
    List<int> usernameBytes = utf8.encode(msg.username);
    message.add(usernameBytes.length);
    message.addAll(usernameBytes);
    message.addAll(utf8.encode(msg.password));

    _setMessageLength(message);

    return message;
  }

  List<int> _encodeConfirmEmailMessage(ConfirmEmailMessage msg) {
    // XXXX ConfirmEmail Req UserIdentifier Code
    var message = List<int>();
    message.addAll(List.filled(4, 0));
    message.add(MessageCode.ConfirmEmail.index);
    message.addAll(_uuid.parse(msg.requestIdentifier));
    message.addAll(msg.userIdentifier);
    message.addAll([7, 7, 7, 8, 8, 8]);

    _setMessageLength(message);

    return message;
  }

  List<int> _encodeAddFirebaseUserMessage(AddFirebaseUserMessage msg) {
    // XXXX AddFirebaseUser Req Sess FirebaseUserIdentifier
    var message = List<int>();
    message.addAll(List<int>.filled(4, 0));
    message.add(MessageCode.AddFirebaseUser.index);
    message.addAll(_uuid.parse(msg.requestIdentifier));
    message.addAll(msg.sessionIdentifier);
    message.addAll(utf8.encode(msg.firebaseUserIdentifier));

    _setMessageLength(message);

    return message;
  }

  List<int> _encodeJoinMessage(JoinMessage msg) {
    /*
      XXXX Join Req Sess
      C1 [Req L1 RoomName C1 PalId [PalId ...] ...]
      C2 [Req RoomIdentifier Type L4 Content ...]
      C1 [Req ShareRoomInvitation/LeaveRoom RoomIdentifier [C1 PalId [PalId ...]] ...]
      C2 [RoomIdentifier TimeOfCreation ...]
      [RoomIdentifier TimeOfCreation ...]
    */

    var message = List<int>();
    message.addAll(List.filled(4, 0));
    message.add(MessageCode.Join.index);
    message.addAll(_uuid.parse(msg.requestIdentifier));
    message.addAll(msg.sessionIdentifier);

    var byteData = Uint8List(8).buffer.asByteData();

    message.add(msg.unconfirmedRooms.length);
    for (var shareRoom in msg.unconfirmedRooms) {
      message.addAll(_uuid.parse(shareRoom.requestIdentifier));
      List<int> roomNameBytes = utf8.encode(shareRoom.name);
      message.add(roomNameBytes.length);
      message.addAll(roomNameBytes);
      message.add(shareRoom.pals.length);
      for (int palId in shareRoom.pals) {
        byteData.setInt64(0, palId);
        message.addAll(byteData.buffer.asUint8List());
      }
    }

    byteData.setInt16(0, msg.unconfirmedItems.length);
    message.addAll(byteData.buffer.asUint8List(0, 2));
    for (var shareItem in msg.unconfirmedItems) {
      message.addAll(_uuid.parse(shareItem.requestIdentifier));
      message.addAll(shareItem.roomIdentifier);
      message.add(shareItem.type.index);
      byteData.setInt32(0, shareItem.content.length);
      message.addAll(byteData.buffer.asUint8List(0, 4));
      message.addAll(shareItem.content);
    }

    message.add(msg.unconfirmedRoomOperations.length);
    for (var operation in msg.unconfirmedRoomOperations) {
      message.addAll(_uuid.parse(operation.requestIdentifier));
      message.add(
        operation.pals != null
            ? MessageCode.ShareRoomInvitation.index
            : MessageCode.LeaveRoom.index,
      );
      message.addAll(operation.roomIdentifier);
      if (operation.pals != null) {
        message.add(operation.pals.length);
        for (int palId in operation.pals) {
          byteData.setInt64(0, palId);
          message.addAll(byteData.buffer.asUint8List());
        }
      }
    }

    byteData.setInt16(0, msg.unconfirmedAcks.length);
    message.addAll(byteData.buffer.asUint8List(0, 2));
    for (var ack in msg.unconfirmedAcks) {
      message.addAll(ack.roomIdentifier);
      byteData.setInt64(0, ack.timeOfCreation);
      message.addAll(byteData.buffer.asUint8List());
    }

    for (var shareRoom in msg.shareRoomsWithLatestItem) {
      message.addAll(shareRoom.identifier);
      byteData.setInt64(0, shareRoom.latestItem.timeOfCreation);
      message.addAll(byteData.buffer.asUint8List());
    }

    _setMessageLength(message);

    return message;
  }

  List<int> _encodeCreateShareRoomMessage(CreateShareRoomMessage msg) {
    // XXXX CreateShareRoom Req Sess L1 RoomName PalId [PalId ...]
    var message = List<int>();
    message.addAll(List<int>.filled(4, 0));
    message.add(MessageCode.CreateShareRoom.index);
    message.addAll(_uuid.parse(msg.requestIdentifier));
    message.addAll(msg.sessionIdentifier);
    List<int> roomNameBytes = utf8.encode(msg.roomName);
    message.add(roomNameBytes.length);
    message.addAll(roomNameBytes);
    var byteData = Uint8List(8).buffer.asByteData();
    for (int palId in msg.pals) {
      byteData.setInt64(0, palId);
      message.addAll(byteData.buffer.asUint8List());
    }

    _setMessageLength(message);

    return message;
  }

  List<int> _encodeCreateShareItemMessage(CreateShareItemMessage msg) {
    // XXXX CreateShareItem Req Sess RoomIdentifier Type Content
    var message = List<int>();
    message.addAll(List<int>.filled(4, 0));
    message.add(MessageCode.CreateShareItem.index);
    message.addAll(_uuid.parse(msg.requestIdentifier));
    message.addAll(msg.sessionIdentifier);
    message.addAll(msg.roomIdentifier);
    message.add(msg.itemType.index);
    message.addAll(msg.itemContent);

    _setMessageLength(message);

    return message;
  }

  @override
  List<int> encodeShareRoomInvitationMessage(
    String requestIdentifier,
    Uint8List sessionIdentifier,
    Uint8List roomIdentifier,
    List<int> pals,
  ) {
    // XXXX ShareRoomInvitation Req Sess RoomIdentifier PalId [PalId ...]
    var message = List<int>();
    message.addAll(List<int>.filled(4, 0));
    message.add(MessageCode.ShareRoomInvitation.index);
    message.addAll(_uuid.parse(requestIdentifier));
    message.addAll(sessionIdentifier);
    message.addAll(roomIdentifier);
    var byteData = Uint8List(8).buffer.asByteData();
    for (int palId in pals) {
      byteData.setInt64(0, palId);
      message.addAll(byteData.buffer.asUint8List());
    }

    _setMessageLength(message);

    return message;
  }

  @override
  List<int> encodeLeaveRoomMessage(
    String requestIdentifier,
    Uint8List sessionIdentifier,
    Uint8List roomIdentifier,
  ) {
    // XXXX LeaveRoom Req Sess RoomIdentifier
    var message = List<int>();
    message.addAll(List<int>.filled(4, 0));
    message.add(MessageCode.LeaveRoom.index);
    message.addAll(_uuid.parse(requestIdentifier));
    message.addAll(sessionIdentifier);
    message.addAll(roomIdentifier);

    _setMessageLength(message);

    return message;
  }

  List<int> _encodeAckRoomMembershipOperationMessage(
    AckRoomMembershipOperationMessage msg,
  ) {
    // XXXX AckRoomMembershipOperation Sess NotificationIdentifier
    var message = List<int>();
    message.addAll(List<int>.filled(4, 0));
    message.add(MessageCode.AckRoomMembershipOperation.index);
    message.addAll(msg.sessionIdentifier);
    message.addAll(msg.notificationIdentifier);

    _setMessageLength(message);

    return message;
  }

  @override
  List<int> encodeAckMessage(
    String requestIdentifier,
    MessageCode messageCode,
    Uint8List sessionIdentifier,
    Uint8List roomIdentifier,
    int timeOfCreation,
  ) {
    // XXXX AckReceive/AckRead Req Sess RoomIdentifier TimeOfCreation
    var message = List<int>();
    message.addAll(List<int>.filled(4, 0));
    message.add(messageCode.index);
    message.addAll(_uuid.parse(requestIdentifier));
    message.addAll(sessionIdentifier);
    message.addAll(roomIdentifier);
    var byteData = Uint8List(8).buffer.asByteData();
    byteData.setInt64(0, timeOfCreation);
    message.addAll(byteData.buffer.asUint8List());

    _setMessageLength(message);

    return message;
  }

  List<int> _encodeAckReceiveMessage(AckReceiveMessage msg) {
    // XXXX AckReceive Req Sess RoomIdentifier TimeOfCreation
    var message = List<int>();
    message.addAll(List<int>.filled(4, 0));
    message.add(MessageCode.AckReceive.index);
    message.addAll(_uuid.parse(msg.requestIdentifier));
    message.addAll(msg.sessionIdentifier);
    message.addAll(msg.roomIdentifier);
    var byteData = Uint8List(8).buffer.asByteData();
    byteData.setInt64(0, msg.timeOfCreation);
    message.addAll(byteData.buffer.asUint8List());

    _setMessageLength(message);

    return message;
  }

  List<int> _encodeAckReadMessage(AckReadMessage msg) {
    // XXXX AckRead Req Sess RoomIdentifier TimeOfCreation [TimeOfCreation ...]
    var message = List<int>();
    message.addAll(List<int>.filled(4, 0));
    message.add(MessageCode.AckRead.index);
    message.addAll(_uuid.parse(msg.requestIdentifier));
    message.addAll(msg.sessionIdentifier);
    message.addAll(msg.shareItems.first.roomIdentifier);
    var byteData = Uint8List(8).buffer.asByteData();
    for (var shareItem in msg.shareItems) {
      byteData.setInt64(0, shareItem.timeOfCreation);
      message.addAll(byteData.buffer.asUint8List());
    }

    _setMessageLength(message);

    return message;
  }

  List<int> _encodeAckReceiveReadMessage(AckReceiveReadMessage msg) {
    // XXXX AcReceiveRead Req Sess RoomIdentifier TimeOfCreation
    var message = List<int>();
    message.addAll(List<int>.filled(4, 0));
    message.add(MessageCode.AckReceiveRead.index);
    message.addAll(_uuid.parse(msg.requestIdentifier));
    message.addAll(msg.sessionIdentifier);
    message.addAll(msg.roomIdentifier);
    var byteData = Uint8List(8).buffer.asByteData();
    byteData.setInt64(0, msg.timeOfCreation);
    message.addAll(byteData.buffer.asUint8List());

    _setMessageLength(message);

    return message;
  }

  List<int> _encodeDeleteAcksMessage(DeleteAcksMessage msg) {
    // XXXX DeleteAcks Sess RoomIdentifier TimeOfCreation [RoomIdentifier TimeOfCreation ...]
    var message = List<int>();
    message.addAll(List<int>.filled(4, 0));
    message.add(MessageCode.DeleteAcks.index);
    message.addAll(msg.sessionIdentifier);
    var byteData = Uint8List(8).buffer.asByteData();
    for (var shareItem in msg.shareItems) {
      message.addAll(shareItem.roomIdentifier);
      byteData.setInt64(0, shareItem.timeOfCreation);
      message.addAll(byteData.buffer.asUint8List());
    }

    _setMessageLength(message);

    return message;
  }

  List<int> _encodeIsTypingMessage(IsTypingMessage msg) {
    // XXXX IsTyping Sess RoomIdentifier
    var message = List<int>();
    message.addAll(List<int>.filled(4, 0));
    message.add(MessageCode.IsTyping.index);
    message.addAll(msg.sessionIdentifier);
    message.addAll(msg.roomIdentifier);

    _setMessageLength(message);

    return message;
  }

  List<int> _encodeGetUsersMessage(GetUsersMessage msg) {
    // XXXX GetUsers Req Sess UserId [UserId ...]
    var message = List<int>();
    message.addAll(List<int>.filled(4, 0));
    message.add(MessageCode.GetUsers.index);
    message.addAll(_uuid.parse(msg.requestIdentifier));
    message.addAll(msg.sessionIdentifier);
    var byteData = Uint8List(8).buffer.asByteData();
    for (int userId in msg.users) {
      byteData.setInt64(0, userId);
      message.addAll(byteData.buffer.asUint8List());
    }

    _setMessageLength(message);

    return message;
  }

  List<int> _encodeSearchUsersMessage(SearchUsersMessage msg) {
    // XXXX SearchUsers Req Sess EmailUsernameId
    var message = List<int>();
    message.addAll(List<int>.filled(4, 0));
    message.add(MessageCode.SearchUsers.index);
    message.addAll(_uuid.parse(msg.requestIdentifier));
    message.addAll(msg.sessionIdentifier);
    message.addAll(utf8.encode(msg.emailUsernameId));

    _setMessageLength(message);

    return message;
  }

  List<int> _encodeWebRtcInquireMessage(WebRtcInquireMessage msg) {
    // XXXX WebRtcInquire Req Sess UserId WebRtcSess
    var message = List<int>();
    message.addAll(List<int>.filled(4, 0));
    message.add(MessageCode.WebRtcInquire.index);
    message.addAll(_uuid.parse(msg.requestIdentifier));
    message.addAll(msg.sessionIdentifier);
    var byteData = Uint8List(8).buffer.asByteData();
    byteData.setInt64(0, msg.userId);
    message.addAll(byteData.buffer.asUint8List());
    message.addAll(msg.webRtcSessionIdentifier);

    _setMessageLength(message);

    return message;
  }

  List<int> _encodeWebRtcOfferMessage(WebRtcOfferMessage msg) {
    // XXXX WebRtcOffer Req Sess WebRtcSess Media L2 Sdp Type
    var message = List<int>();
    message.addAll(List<int>.filled(4, 0));
    message.add(MessageCode.WebRtcOffer.index);
    message.addAll(_uuid.parse(msg.requestIdentifier));
    message.addAll(msg.sessionIdentifier);
    message.addAll(msg.webRtcsessionIdentifier);
    message.add(msg.media.index);
    var byteData = Uint8List(2).buffer.asByteData();
    var sdpBytes = utf8.encode(msg.sdp);
    byteData.setInt16(0, sdpBytes.length);
    message.addAll(byteData.buffer.asUint8List());
    message.addAll(sdpBytes);
    message.addAll(utf8.encode(msg.type));

    _setMessageLength(message);

    return message;
  }

  List<int> _encodeWebRtcAnswerMessage(WebRtcAnswerMessage msg) {
    // XXXX WebRtcAnswer Req Sess WebRtcSess L2 Sdp Type
    var message = List<int>();
    message.addAll(List<int>.filled(4, 0));
    message.add(MessageCode.WebRtcAnswer.index);
    message.addAll(_uuid.parse(msg.requestIdentifier));
    message.addAll(msg.sessionIdentifier);
    message.addAll(msg.webRtcSessionIdentifier);
    var byteData = Uint8List(2).buffer.asByteData();
    var sdpBytes = utf8.encode(msg.sdp);
    byteData.setInt16(0, sdpBytes.length);
    message.addAll(byteData.buffer.asUint8List());
    message.addAll(sdpBytes);
    message.addAll(utf8.encode(msg.type));

    _setMessageLength(message);

    return message;
  }

  List<int> _encodeWebRtcCandidateMessage(WebRtcCandidateMessage msg) {
    // XXXX WebRtcCandidate Req Sess WebRtcSess SdpMlineIndex L2 SdpMid Candidate
    var message = List<int>();
    message.addAll(List<int>.filled(4, 0));
    message.add(MessageCode.WebRtcCandidate.index);
    message.addAll(_uuid.parse(msg.requestIdentifier));
    message.addAll(msg.sessionIdentifier);
    message.addAll(msg.webRtcSessionIdentifier);
    var byteData = Uint8List(8).buffer.asByteData();
    byteData.setInt64(0, msg.sdpMlineIndex);
    message.addAll(byteData.buffer.asUint8List());
    var sdpMidBytes = utf8.encode(msg.sdpMid);
    byteData.setInt16(0, sdpMidBytes.length);
    message.addAll(byteData.buffer.asUint8List(0, 2));
    message.addAll(sdpMidBytes);
    message.addAll(utf8.encode(msg.candidate));

    _setMessageLength(message);

    return message;
  }

  List<int> _encodeWebRtcMessage(WebRtcMessage msg) {
    // XXXX WebRtcGrant/WebRtcRefuse/WebRtcDecline/WebRtcEndSession/WebRtcCancel Sess WebRtcSess
    var message = List<int>();
    message.addAll(List<int>.filled(4, 0));
    message.add(msg.messageCode.index);
    message.addAll(msg.sessionIdentifier);
    message.addAll(msg.webRtcSessionIdentifier);

    _setMessageLength(message);

    return message;
  }

  @override
  List<int> encodeMessage(Message msg) {
    List<int> message;
    if (msg is SignUpMessage) {
      message = _encodeSignUpMessage(msg);
    } else if (msg is ConfirmEmailMessage) {
      message = _encodeConfirmEmailMessage(msg);
    } else if (msg is AddFirebaseUserMessage) {
      message = _encodeAddFirebaseUserMessage(msg);
    } else if (msg is JoinMessage) {
      message = _encodeJoinMessage(msg);
    } else if (msg is CreateShareRoomMessage) {
      message = _encodeCreateShareRoomMessage(msg);
    } else if (msg is CreateShareItemMessage) {
      message = _encodeCreateShareItemMessage(msg);
    } else if (msg is AckRoomMembershipOperationMessage) {
      message = _encodeAckRoomMembershipOperationMessage(msg);
    } else if (msg is AckReceiveMessage) {
      message = _encodeAckReceiveMessage(msg);
    } else if (msg is AckReadMessage) {
      message = _encodeAckReadMessage(msg);
    } else if (msg is AckReceiveReadMessage) {
      message = _encodeAckReceiveReadMessage(msg);
    } else if (msg is DeleteAcksMessage) {
      message = _encodeDeleteAcksMessage(msg);
    } else if (msg is IsTypingMessage) {
      message = _encodeIsTypingMessage(msg);
    } else if (msg is GetUsersMessage) {
      message = _encodeGetUsersMessage(msg);
    } else if (msg is SearchUsersMessage) {
      message = _encodeSearchUsersMessage(msg);
    } else if (msg is WebRtcInquireMessage) {
      message = _encodeWebRtcInquireMessage(msg);
    } else if (msg is WebRtcOfferMessage) {
      message = _encodeWebRtcOfferMessage(msg);
    } else if (msg is WebRtcAnswerMessage) {
      message = _encodeWebRtcAnswerMessage(msg);
    } else if (msg is WebRtcCandidateMessage) {
      message = _encodeWebRtcCandidateMessage(msg);
    } else if (msg is WebRtcMessage) {
      message = _encodeWebRtcMessage(msg);
    }

    return message;
  }

  SuccessfulSignUpServerMessage _decodeSuccessfulSignUpMessage(
    Uint8List message,
  ) {
    // SuccessfulSignUp 1 Req UserIdentifier
    int i = 2;
    return SuccessfulSignUpServerMessage(
      requestIdentifier: _uuid.unparse(message, offset: i),
      userIdentifier: Uint8List.view(message.buffer, i += 16, 16),
    );
  }

  SuccessfulLogInServerMessage _decodeSuccessfulLogInMessage(
    Uint8List message,
  ) {
    // SuccessfulLogIn 1 Req Sess
    int i = 2;
    String requestIdentifier = _uuid.unparse(message, offset: i);
    int userId = message.buffer.asByteData().getInt64(i += 16);
    var sessionIdentifier = Uint8List.view(message.buffer, i, 40);

    return SuccessfulLogInServerMessage(
      requestIdentifier: requestIdentifier,
      sessionIdentifier: sessionIdentifier,
      userId: userId,
    );
  }

  JoinedServerMessage _decodeJoinedMessage(Uint8List message) {
    /*
        Joined 1 Req
        C1 [Req RoomIdentifier ...]
        C2 [Req TimeOfCreation ...]
        C2 [NotificationIdentifier RoomIdentifier OperationType [C1] PalId [PalId ...] ...]
        C2 [RoomIdentifier TimeOfCreation C1 [PalId ...] C1 [PalId ...] ...]
        [
            0 C2 RoomIdentifier
            [CreatorId TimeOfCreation Type L4 Content ...]
            1 00 RoomIdentifier L1 RoomName C1 PalId [PalId ...]
            1 C2 RoomIdentifier L1 RoomName C1 PalId [PalId ...]
            [CreatorId TimeOfCreation Type L4 Content ...]
            ...
        ]
    */

    int i = 2;
    String requestIdentifier = _uuid.unparse(message, offset: i);
    int roomCount = message[i += 16];
    ++i;
    List<ShareRoomModel> confirmedRooms = [];
    for (int j = 0; j < roomCount; ++j, i += 16) {
      confirmedRooms.add(
        ShareRoomModel(
          requestIdentifier: _uuid.unparse(message, offset: i),
          identifier: Uint8List.view(message.buffer, i += 16, 16),
        ),
      );
    }

    int itemCount = message.buffer.asByteData().getInt16(i);
    i += 2;
    List<ShareItemModel> confirmedItems = [];
    for (int j = 0; j < itemCount; ++j, i += 8) {
      confirmedItems.add(
        ShareItemModel(
          requestIdentifier: _uuid.unparse(message, offset: i),
          timeOfCreation: message.buffer.asByteData().getInt64(i += 16),
        ),
      );
    }

    int notificationCount = message.buffer.asByteData().getInt16(i);
    i += 2;
    List<RoomMembershipNotificationModel> notifications = [];
    for (int j = 0; j < notificationCount; ++j) {
      var notificationIdentifier = Uint8List.view(message.buffer, i, 16);
      var roomIdentifier = Uint8List.view(message.buffer, i += 16, 16);
      var operationType = RoomMembershipOperationType.values[message[i += 16]];
      ++i;
      int palCount = 1;
      if (operationType == RoomMembershipOperationType.Add) {
        palCount = message[i++];
      }
      List<int> pals = [];
      for (int k = 0; k < palCount; ++k, i += 8) {
        pals.add(message.buffer.asByteData().getInt64(i));
      }

      notifications.add(
        RoomMembershipNotificationModel(
          identifier: notificationIdentifier,
          roomIdentifier: roomIdentifier,
          operationType: operationType,
          pals: pals,
        ),
      );
    }

    int ackCount = message.buffer.asByteData().getInt16(i);
    i += 2;
    List<AckModel> acks = [];
    for (int j = 0; j < ackCount; ++j) {
      var roomIdentifier = Uint8List.view(message.buffer, i, 16);
      int timeOfCreation = message.buffer.asByteData().getInt64(i += 16);
      int palCount = message[i += 8];
      ++i;
      List<int> notReceivedPals = [];
      for (int k = 0; k < palCount; ++k, i += 8) {
        notReceivedPals.add(message.buffer.asByteData().getInt64(i));
      }
      palCount = message[i++];
      List<int> notReadPals = [];
      for (int k = 0; k < palCount; ++k, i += 8) {
        notReadPals.add(message.buffer.asByteData().getInt64(i));
      }

      acks.add(
        AckModel(
          roomIdentifier: roomIdentifier,
          timeOfCreation: timeOfCreation,
          notReceivedPals: notReceivedPals,
          notReadPals: notReadPals,
        ),
      );
    }

    List<ShareRoomModel> shareRooms = [];
    List<ShareItemModel> shareItems = [];
    while (i < message.length) {
      bool isNewRoom = message[i++] == 1;
      itemCount = message.buffer.asByteData().getInt16(i);
      var roomIdentifier = Uint8List.view(message.buffer, i += 2, 16);
      i += 16;
      if (isNewRoom) {
        int roomNameLength = message[i++];
        String roomName = utf8.decoder.convert(message, i, i += roomNameLength);
        int palCount = message[i++];
        List<int> pals = [];
        for (int j = 0; j < palCount; ++j, i += 8) {
          pals.add(message.buffer.asByteData().getInt64(i));
        }

        shareRooms.add(
          ShareRoomModel(
            identifier: roomIdentifier,
            name: roomName,
            pals: pals,
            isConfirmed: true,
          ),
        );
      }

      for (int j = 0; j < itemCount; ++j) {
        int creatorId = message.buffer.asByteData().getInt64(i);
        int timeOfCreation = message.buffer.asByteData().getInt64(i += 8);
        var type = ShareItemType.values[message[i += 8]];
        int contentLength = message.buffer.asByteData().getInt32(++i);
        var content = Uint8List.view(message.buffer, i += 4, contentLength);
        i += contentLength;

        shareItems.add(
          ShareItemModel(
            roomIdentifier: roomIdentifier,
            creatorId: creatorId,
            timeOfCreation: timeOfCreation,
            type: type,
            content: content,
          ),
        );
      }
    }

    return JoinedServerMessage(
      requestIdentifier: requestIdentifier,
      confirmedRooms: confirmedRooms,
      confirmedItems: confirmedItems,
      notifications: notifications,
      acks: acks,
      shareRooms: shareRooms,
      shareItems: shareItems,
    );
  }

  SuccessfulShareRoomCreationServerMessage
      _decodeSuccessfulShareRoomCreationMessage(
    Uint8List message,
  ) {
    // SuccessfulShareRoomCreation 1 Req RoomIdentifier
    int i = 2;
    return SuccessfulShareRoomCreationServerMessage(
      requestIdentifier: _uuid.unparse(message, offset: i),
      roomIdentifier: Uint8List.view(message.buffer, i += 16, 16),
    );
  }

  ShareRoomInvitationServerMessage _decodeShareRoomInvitationMessage(
    Uint8List message,
  ) {
    // ShareRoomInvitation 0 C1 PalId [PalId ...] RoomIdentifier CreatorId RoomName
    int i = 2;
    int palCount = message[i++];
    List<int> pals = [];
    for (int j = 0; j < palCount; ++j, i += 8) {
      pals.add(message.buffer.asByteData().getInt64(i));
    }
    var roomIdentifier = Uint8List.view(message.buffer, i, 16);
    int creatorId = message.buffer.asByteData().getInt64(i += 16);
    pals.add(creatorId);
    String roomName = utf8.decoder.convert(message, i += 8);

    return ShareRoomInvitationServerMessage(
      creatorId: creatorId,
      roomIdentifier: roomIdentifier,
      roomName: roomName,
      pals: pals,
    );
  }

  SuccessfulShareItemCreationServerMessage
      _decodeSuccessfulShareItemCreationMessage(
    Uint8List message,
  ) {
    // SuccessfulShareItemCreation 1 Req TimeOfCreation
    int i = 2;
    return SuccessfulShareItemCreationServerMessage(
      requestIdentifier: _uuid.unparse(message, offset: i),
      timeOfCreation: message.buffer.asByteData().getInt64(i += 16),
    );
  }

  UsersServerMessage _decodeUsersMessage(Uint8List message) {
    // Users 1 Req UserId L1 Username L1 FirebaseUserIdentifier
    // [UserId L1 Username L1 FirebaseUserIdentifier ...]
    int i = 2;
    String requestIdentifier = _uuid.unparse(message, offset: i);
    i += 16;
    List<UserModel> users = [];
    while (i < message.length) {
      int userId = message.buffer.asByteData().getInt64(i);
      int length = message[i += 8];
      var username = Uint8List.view(message.buffer, ++i, length);
      length = message[i += length];
      var firebaseUserIdentifier = Uint8List.view(message.buffer, ++i, length);
      i += length;

      users.add(
        UserModel(
          id: userId,
          username: username,
          firebaseUserIdentifier: firebaseUserIdentifier,
        ),
      );
    }

    return UsersServerMessage(
      requestIdentifier: requestIdentifier,
      users: users,
    );
  }

  NewShareItemServerMessage _decodeNewShareItemMessage(Uint8List message) {
    // NewShareItem 0 C1 PalId [PalId ...] RoomIdentifier CreatorId TimeOfCreation Type Content
    int i = 2;
    int palCount = message[i++];
    i += palCount * 8;
    var roomIdentifier = Uint8List.view(message.buffer, i, 16);
    int creatorId = message.buffer.asByteData().getInt64(i += 16);
    int timeOfCreation = message.buffer.asByteData().getInt64(i += 8);
    var type = ShareItemType.values[message[i += 8]];
    var content = Uint8List.view(message.buffer, ++i);

    return NewShareItemServerMessage(
      roomIdentifier: roomIdentifier,
      creatorId: creatorId,
      timeOfCreation: timeOfCreation,
      type: type,
      content: content,
    );
  }

  NewPalsServerMessage _decodeNewPalsMessage(Uint8List message) {
    // NewPals 0 C1 PalId [PalId ...] NotificationIdentifier RoomIdentifier PalId [PalId ...]
    int i = 2;
    int palCount = message[i++];
    i += palCount * 8;
    var notificationIdentifier = Uint8List.view(message.buffer, i, 16);
    var roomIdentifier = Uint8List.view(message.buffer, i += 16, 16);
    i += 16;
    List<int> pals = [];
    while (i < message.length) {
      pals.add(message.buffer.asByteData().getInt64(i));
      i += 8;
    }

    return NewPalsServerMessage(
      notificationIdentifier: notificationIdentifier,
      roomIdentifier: roomIdentifier,
      pals: pals,
    );
  }

  InvitedToShareRoomServerMessage _decodeInvitedToShareRoomMessage(
    Uint8List message,
  ) {
    // InvitedToShareRoom 0 C1 PalId [PalId ...] RoomIdentifier L1 RoomName InviterId PalId [PalId ...]
    int i = 2;
    int palCount = message[i++];
    List<int> pals = [];
    for (int j = 0; j < palCount; ++j, i += 8) {
      pals.add(message.buffer.asByteData().getInt64(i));
    }
    var roomIdentifier = Uint8List.view(message.buffer, i, 16);
    int roomNameLength = message[i += 16];
    String roomName = utf8.decoder.convert(message, ++i, i += roomNameLength);
    int inviterId = message.buffer.asByteData().getInt64(i);
    i += 8;
    pals.add(inviterId);
    while (i < message.length) {
      pals.add(message.buffer.asByteData().getInt64(i));
      i += 8;
    }

    return InvitedToShareRoomServerMessage(
      inviterId: inviterId,
      roomIdentifier: roomIdentifier,
      roomName: roomName,
      pals: pals,
    );
  }

  PalLeftServerMessage _decodePalLeftMessage(Uint8List message) {
    // PalLeft 0 C1 PalId [PalId ...] NotificationIdentifier RoomIdentifier PalId
    int i = 2;
    int palCount = message[i++];
    i += palCount * 8;
    var notificationIdentifier = Uint8List.view(message.buffer, i, 16);
    var roomIdentifier = Uint8List.view(message.buffer, i += 16, 16);
    int palId = message.buffer.asByteData().getInt64(i += 16);

    return PalLeftServerMessage(
      notificationIdentifier: notificationIdentifier,
      roomIdentifier: roomIdentifier,
      palId: palId,
    );
  }

  AckServerMessage _decodeAckMessage(Uint8List message) {
    // AckReceive/AckReceiveRead 0 1 CreatorId UserId RoomIdentifier TimeOfCreation
    int i = 0;
    return AckServerMessage(
      messageCode: MessageCode.values[message[i]],
      userId: message.buffer.asByteData().getInt64(i += 11),
      roomIdentifier: Uint8List.view(message.buffer, i += 8, 16),
      timeOfCreation: message.buffer.asByteData().getInt64(i += 16),
    );
  }

  AckReadServerMessage _decodeAckReadMessage(Uint8List message) {
    // AckRead 0 1 CreatorId UserId RoomIdentifier TimeOfCreation [TimeOfCreation ...]
    int i = 11;
    int userId = message.buffer.asByteData().getInt64(i);
    var roomIdentifier = Uint8List.view(message.buffer, i += 8, 16);
    i += 16;
    var acks = List<AckModel>();
    while (i < message.length) {
      acks.add(
        AckModel(
          messageCode: MessageCode.AckRead,
          palId: userId,
          roomIdentifier: roomIdentifier,
          timeOfCreation: message.buffer.asByteData().getInt64(i),
        ),
      );

      i += 8;
    }

    return AckReadServerMessage(acks: acks);
  }

  IsTypingServerMessage _decodeIsTypingMessage(Uint8List message) {
    // IsTyping 0 Count UserId [UserId ...] RoomIdentifier UserId
    int i = 2;
    int palCount = message[i++];
    i += palCount * 8;
    
    return IsTypingServerMessage(
      roomIdentifier: Uint8List.view(message.buffer, i, 16),
      userId: message.buffer.asByteData().getInt64(i + 16),
    );
  }

  WebRtcInquireServerMessage _decodeWebRtcInquireMessage(Uint8List message) {
    // WebRtcInquire 0 1 UserId OtherUserId WebRtcSess
    int i = 11;
    return WebRtcInquireServerMessage(
      userId: message.buffer.asByteData().getInt64(i),
      webRtcSessionIdentifier: Uint8List.view(message.buffer, i += 8, 16),
    );
  }

  WebRtcOfferServerMessage _decodeWebRtcOfferMessage(Uint8List message) {
    // WebRtcOffer 0 1 UserId WebRtcSess Media L2 Sdp Type
    int i = 11;
    var webRtcSessionIdentifier = Uint8List.view(message.buffer, i, 16);
    var media = MediaType.values[message[i += 16]];
    int length = message.buffer.asByteData().getInt16(++i);
    String sdp = utf8.decoder.convert(message, i += 2, i += length);
    String type = utf8.decoder.convert(message, i, message.length);

    return WebRtcOfferServerMessage(
      webRtcSessionIdentifier: webRtcSessionIdentifier,
      media: media,
      sdp: sdp,
      type: type,
    );
  }

  WebRtcAnswerServerMessage _decodeWebRtcAnswerMessage(Uint8List message) {
    // WebRtcAnswer 0 1 UserId WebRtcSess L2 Sdp Type
    int i = 11;
    var webRtcSessionIdentifier = Uint8List.view(message.buffer, i, 16);
    int length = message.buffer.asByteData().getInt16(i += 16);
    String sdp = utf8.decoder.convert(message, i += 2, i += length);
    String type = utf8.decoder.convert(message, i, message.length);

    return WebRtcAnswerServerMessage(
      webRtcSessionIdentifier: webRtcSessionIdentifier,
      sdp: sdp,
      type: type,
    );
  }

  WebRtcCandidateServerMessage _decodeWebRtcCandidateMessage(
    Uint8List message,
  ) {
    // WebRtcCandidate 0 1 UserId WebRtcSess SdpMlineIndex L2 SdpMid Candidate
    int i = 11;
    var webRtcSessionIdentifier = Uint8List.view(message.buffer, i, 16);
    int sdpMlineIndex = message.buffer.asByteData().getInt64(i += 16);
    int length = message.buffer.asByteData().getInt16(i += 8);
    String sdpMid = utf8.decoder.convert(message, i += 2, i += length);
    String candidate = utf8.decoder.convert(message, i, message.length);

    return WebRtcCandidateServerMessage(
      webRtcSessionIdentifier: webRtcSessionIdentifier,
      sdpMlineIndex: sdpMlineIndex,
      sdpMid: sdpMid,
      candidate: candidate,
    );
  }

  WebRtcServerMessage _decodeWebRtcMessage(Uint8List message) {
    // WebRtcGrant/WebRtcRefuse/WebRtcDecline/WebRtcCancel 0 1 UserId WebRtcSess
    int i = 0;
    return WebRtcServerMessage(
      messageCode: MessageCode.values[message[i]],
      webRtcSessionIdentifier: Uint8List.view(message.buffer, i + 11, 16),
    );
  }

  @override
  ServerMessage decodeServerMessage(Uint8List message) {
    // MessageCode 1/0 ...
    var messageCode = MessageCode.values[message[0]];
    bool isResponseToRequest = message[1] == 1;

    ServerMessage serverMessage;
    if (isResponseToRequest) {
      switch (messageCode) {
        case MessageCode.SuccessfulSignUp:
          serverMessage = _decodeSuccessfulSignUpMessage(message);
          break;
        case MessageCode.SuccessfulLogIn:
          serverMessage = _decodeSuccessfulLogInMessage(message);
          break;
        case MessageCode.Joined:
          serverMessage = _decodeJoinedMessage(message);
          break;
        case MessageCode.SuccessfulShareRoomCreation:
          serverMessage = _decodeSuccessfulShareRoomCreationMessage(message);
          break;
        case MessageCode.SuccessfulShareItemCreation:
          serverMessage = _decodeSuccessfulShareItemCreationMessage(message);
          break;
        case MessageCode.Users:
          serverMessage = _decodeUsersMessage(message);
          break;
        default:
          serverMessage = ServerMessage(
            messageCode: messageCode,
            isResponseToRequest: true,
            requestIdentifier: _uuid.unparse(message, offset: 2),
          );
          break;
      }
    } else {
      switch (messageCode) {
        case MessageCode.ShareRoomInvitation:
          serverMessage = _decodeShareRoomInvitationMessage(message);
          break;
        case MessageCode.NewShareItem:
          serverMessage = _decodeNewShareItemMessage(message);
          break;
        case MessageCode.NewPals:
          serverMessage = _decodeNewPalsMessage(message);
          break;
        case MessageCode.InvitedToShareRoom:
          serverMessage = _decodeInvitedToShareRoomMessage(message);
          break;
        case MessageCode.PalLeft:
          serverMessage = _decodePalLeftMessage(message);
          break;
        case MessageCode.AckReceive:
        case MessageCode.AckReceiveRead:
          serverMessage = _decodeAckMessage(message);
          break;
        case MessageCode.AckRead:
          serverMessage = _decodeAckReadMessage(message);
          break;
        case MessageCode.IsTyping:
          serverMessage = _decodeIsTypingMessage(message);
          break;
        case MessageCode.WebRtcInquire:
          serverMessage = _decodeWebRtcInquireMessage(message);
          break;
        case MessageCode.WebRtcOffer:
          serverMessage = _decodeWebRtcOfferMessage(message);
          break;
        case MessageCode.WebRtcAnswer:
          serverMessage = _decodeWebRtcAnswerMessage(message);
          break;
        case MessageCode.WebRtcCandidate:
          serverMessage = _decodeWebRtcCandidateMessage(message);
          break;
        case MessageCode.WebRtcGrant:
        case MessageCode.WebRtcRefuse:
        case MessageCode.WebRtcDecline:
        case MessageCode.WebRtcEndSession:
        case MessageCode.WebRtcCancel:
          serverMessage = _decodeWebRtcMessage(message);
          break;
        default:
          break;
      }
    }

    return serverMessage;
  }
}
