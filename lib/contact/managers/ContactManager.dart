import 'package:owl/contact/events/events.dart';
import 'package:owl/contact/services/ContactService.dart';
import 'package:owl/contact/services/IContactStorageService.dart';
import 'package:owl/general/mixins/WatchCombinedStateMixin.dart';
import 'package:owl/logging/services/LoggingService.dart';
import 'package:owl/share_room/models/UserModel.dart';
import 'package:rxdart/rxdart.dart';

class ContactManager with WatchCombinedStateMixin {
  final ContactService _contactService;
  final IContactStorageService _contactStorageService;
  final LoggingService _loggingService;

  final PublishSubject<ContactEvent> _eventSubject =
      PublishSubject<ContactEvent>();
  Sink<ContactEvent> get inEvent => _eventSubject.sink;

  final PublishSubject<List<UserModel>> _getMyContactsSubject =
      PublishSubject<List<UserModel>>();
  Stream<List<UserModel>> get getMyContacts$ => _getMyContactsSubject.stream;

  final BehaviorSubject<String> _emailUsernameIdSubject =
      BehaviorSubject<String>();
  Stream<String> get emailUsernameId$ => _emailUsernameIdSubject.stream;

  Stream<bool> get searchUsersFormIsValid$ =>
      watchCombinedState([emailUsernameId$]);

  final PublishSubject<List<UserModel>> _searchUsersSubject =
      PublishSubject<List<UserModel>>();
  Stream<List<UserModel>> get searchUsers$ => _searchUsersSubject.stream;

  final PublishSubject<List<UserModel>> _getFavoriteContactsSubject =
      PublishSubject<List<UserModel>>();
  Stream<List<UserModel>> get getFavoriteContacts$ =>
      _getFavoriteContactsSubject.stream;

  ContactManager(
    this._contactService,
    this._contactStorageService,
    this._loggingService,
  ) {
    _eventSubject.listen((event) {
      Future future;
      if (event is GetMyContactsEvent) {
        future = _getMyContacts();
      } else if (event is ValidateSearchUsersFormEvent) {
        future = _validateSearchUsersForm(event);
      } else if (event is SearchUsersEvent) {
        future = _searchUsers();
      } else if (event is GetFavoriteContactsEvent) {
        future = _getFavoriteContacts();
      } else if (event is AddContactEvent) {
        future = _addContact(event);
      } else if (event is AddContactToFavoritesEvent) {
        future = _addContactToFavorites(event);
      }

      _logError(future);
    });
  }

  void _logError(Future future) async {
    try {
      await future;
    } catch (e, s) {
      _loggingService.log('$e\n$s');
    }
  }

  Future _getMyContacts() async {
    List<UserModel> users = await _contactService.getMyContacts();
    _getMyContactsSubject.add(users);
  }

  Future _validateSearchUsersForm(ValidateSearchUsersFormEvent event) {
    if (event.emailUsernameId.isEmpty) {
      _emailUsernameIdSubject.addError('Cannot be empty');
    } else {
      _emailUsernameIdSubject.add(event.emailUsernameId);
    }
  }

  // @@INCOMPLETE
  Future _searchUsers() async {
    List<UserModel> users = await _contactService.searchUsers(
      _emailUsernameIdSubject.value,
    );
    _searchUsersSubject.add(users);
  }

  Future _getFavoriteContacts() async {
    List<UserModel> users = await _contactService.getFavoriteContacts();
    _getFavoriteContactsSubject.add(users);
  }

  Future _addContact(AddContactEvent event) async {
    await _contactStorageService.addContact(event.userId);
  }

  Future _addContactToFavorites(AddContactToFavoritesEvent event) async {
    await _contactStorageService.addContactToFavorites(event.userId);
    _getMyContacts();
  }
}
