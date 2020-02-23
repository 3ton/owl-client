import 'package:owl/contact/db_tables/ContactsTable.dart';

class ShareRoomsTable {
  static const String name = 'ShareRooms';

  static const String requestIdentifierC = 'RequestIdentifier';
  static const String identifierC = 'Identifier';
  static const String nameC = 'Name';
  static const String isConfirmedC = 'IsConfirmedRoom';
  static const String palsC = 'Pals';
  static const String otherGuyIdC = 'OtherGuyId';

  static const String createTableStatement = '''
    CREATE TABLE IF NOT EXISTS $name (
      $requestIdentifierC TEXT,
      $identifierC BLOB PRIMARY KEY,
      $nameC TEXT NOT NULL,
      $isConfirmedC INTEGER NOT NULL,
      $palsC TEXT NOT NULL,
      $otherGuyIdC INTEGER,
      FOREIGN KEY ($otherGuyIdC)
        REFERENCES ${ContactsTable.name} (${ContactsTable.userIdC})
    )
  ''';

  static const String dropTableStatement = '''
    DROP TABLE IF EXISTS $name
  ''';
}