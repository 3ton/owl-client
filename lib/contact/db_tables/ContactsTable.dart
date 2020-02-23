class ContactsTable {
  static const String name = 'Contacts';

  static const String userIdC = 'UserId';
  static const String usernameC = 'Username';
  static const String firebaseUserIdentifierC = 'FirebaseUserIdentifier';
  static const String isMyContactC = 'IsMyContact';
  static const String isFavoriteC = 'IsFavorite';

  static const String createTableStatement = '''
    CREATE TABLE IF NOT EXISTS $name (
      $userIdC INTEGER PRIMARY KEY,
      $usernameC BLOB NOT NULL,
      $firebaseUserIdentifierC BLOB NOT NULL,
      $isMyContactC INTEGER NOT NULL,
      $isFavoriteC INTEGER NOT NULL
    )
  ''';
}