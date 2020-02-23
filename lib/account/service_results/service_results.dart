abstract class AccountServiceResult {
  final String successMessage;
  final String errorMessage;

  AccountServiceResult({this.successMessage, this.errorMessage});
}

class SignUpServiceResult extends AccountServiceResult {
  SignUpServiceResult({
    String successMessage,
    String errorMessage,
  }) : super(
          successMessage: successMessage,
          errorMessage: errorMessage,
        );
}

class ConfirmEmailServiceResult extends AccountServiceResult {
  ConfirmEmailServiceResult({
    String successMessage,
    String errorMessage,
  }) : super(
          successMessage: successMessage,
          errorMessage: errorMessage,
        );
}

class AddProfilePictureServiceResult extends AccountServiceResult {
  AddProfilePictureServiceResult({
    String successMessage,
    String errorMessage,
  }) : super(
          successMessage: successMessage,
          errorMessage: errorMessage,
        );
}

class SignInServiceResult extends AccountServiceResult {
  SignInServiceResult({
    String successMessage,
    String errorMessage,
  }) : super(
          successMessage: successMessage,
          errorMessage: errorMessage,
        );
}