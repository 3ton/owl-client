import 'package:multi_image_picker/multi_image_picker.dart';

abstract class AccountEvent {}

class LoadAccountEvent extends AccountEvent {}

class ValidateSignUpFormEvent extends AccountEvent {
  final String email;
  final String username;
  final String password;

  ValidateSignUpFormEvent({this.email, this.username, this.password});
}

class SignUpEvent extends AccountEvent {}

class LogInEvent extends AccountEvent {}

class ValidateConfirmEmailFormEvent extends AccountEvent {
  final String confirmationCode;

  ValidateConfirmEmailFormEvent({this.confirmationCode});
}

class ConfirmEmailEvent extends AccountEvent {}

class AddProfilePictureEvent extends AccountEvent {
  final Asset profilePicture;

  AddProfilePictureEvent({this.profilePicture});
}

class SignInEvent extends AccountEvent {}