abstract class ContactEvent {}

class GetMyContactsEvent extends ContactEvent {}

class ValidateSearchUsersFormEvent extends ContactEvent {
  final String emailUsernameId;

  ValidateSearchUsersFormEvent({this.emailUsernameId});
}

class SearchUsersEvent extends ContactEvent {}

class GetFavoriteContactsEvent extends ContactEvent {}

class AddContactEvent extends ContactEvent {
  final int userId;

  AddContactEvent({this.userId});
}

class AddContactToFavoritesEvent extends ContactEvent {
  final int userId;

  AddContactToFavoritesEvent({this.userId});
}