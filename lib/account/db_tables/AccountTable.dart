class AccountTable {
  static const String name = 'Account';

  static const String emailC = 'Email';
  static const String usernameC = 'Username';
  static const String passwordC = 'Password';
  static const String userIdentifierC = 'UserIdentifier';
  static const String userIdC = 'UserId';
  static const String isConfirmedC = 'IsConfirmed';
  static const String sessionIdentifierC = 'SessionIdentifier';

  static const String createTableStatement = '''
    CREATE TABLE IF NOT EXISTS $name (
      $emailC TEXT NOT NULL,
      $usernameC TEXT NOT NULL,
      $passwordC TEXT NOT NULL,
      $userIdentifierC BLOB NOT NULL,
      $userIdC INTEGER,
      $isConfirmedC INTEGER NOT NULL,
      $sessionIdentifierC BLOB
    )
  ''';

  static const String dropTableStatement = '''
    DROP TABLE IF EXISTS $name
  ''';
}