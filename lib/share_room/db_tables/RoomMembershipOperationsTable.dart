import 'package:owl/share_room/db_tables/ShareRoomsTable.dart';

class RoomMembershipOperationsTable {
  static const String name = 'RoomMembershipOperations';

  static const String requestIdentifierC = 'RequestIdentifier';
  static const String roomIdentifierC = 'RoomIdentifier';
  static const String palsC = 'Pals';

  static const String createTableStatement = '''
    CREATE TABLE IF NOT EXISTS $name (
      $requestIdentifierC TEXT NOT NULL,
      $roomIdentifierC BLOB NOT NULL,
      $palsC TEXT,
      FOREIGN KEY ($roomIdentifierC)
        REFERENCES ${ShareRoomsTable.name} (${ShareRoomsTable.identifierC})
        ON DELETE CASCADE
    )
  ''';

  static const String dropTableStatement = '''
    DROP TABLE IF EXISTS $name
  ''';
}