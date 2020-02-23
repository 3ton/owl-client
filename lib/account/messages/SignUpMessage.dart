import 'package:owl/general/messages/Message.dart';

class SignUpMessage extends Message {
  final String email;
  final String username;
  final String password;

  SignUpMessage({this.email, this.username, this.password});
}
