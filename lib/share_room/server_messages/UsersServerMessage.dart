import 'package:owl/general/messages/MessageCode.dart';
import 'package:owl/general/server_messages/ServerMessage.dart';
import 'package:owl/share_room/models/UserModel.dart';

class UsersServerMessage extends ServerMessage {
  final List<UserModel> users;

  UsersServerMessage({
    String requestIdentifier,
    this.users,
  }) : super(
          messageCode: MessageCode.Users,
          isResponseToRequest: true,
          requestIdentifier: requestIdentifier,
        );
}
