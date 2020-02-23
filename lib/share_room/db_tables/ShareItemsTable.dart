import 'package:owl/contact/db_tables/ContactsTable.dart';
import 'package:owl/share_room/db_tables/ShareRoomsTable.dart';
import 'package:owl/share_room/enums/ShareItemAckedStatus.dart';

class ShareItemsTable {
  static const String name = 'ShareItems';

  static const String requestIdentifierC = 'RequestIdentifier';
  static const String idC = 'Id';
  static const String roomIdentifierC = 'RoomIdentifier';
  static const String creatorIdC = 'CreatorId';
  static const String timeOfCreationC = 'TimeOfCreation';
  static const String typeC = 'Type';
  static const String contentC = 'Content';
  static const String isConfirmedC = 'IsConfirmedItem';
  static const String reasonC = 'Reason';
  static const String statusC = 'Status';
  static const String palsToExpectAcksFromC = 'PalsToExpectAcksFrom';
  static const String ackedStatusC = 'AckedStatus';
  static const String isUploadedToFirebaseC = 'IsUploadedToFirebase';
  static const String imageUrlsC = 'ImageUrls';

  // @@NOTE: Share items created by others are always confirmed, and also have NULL
  // reason, status, palsToExpectAcksFrom, isUploadedToFirebase, and imageUrls.
  // Share items created by us have NULL ackedStatus.
  static const String createTableStatement = '''
    CREATE TABLE IF NOT EXISTS $name (
      $requestIdentifierC TEXT,
      $idC INTEGER PRIMARY KEY AUTOINCREMENT,
      $roomIdentifierC BLOB NOT NULL,
      $creatorIdC INTEGER NOT NULL,
      $timeOfCreationC INTEGER NOT NULL,
      $typeC INTEGER NOT NULL,
      $contentC BLOB,
      $isConfirmedC INTEGER NOT NULL,
      $reasonC INTEGER,
      $statusC INTEGER,
      $palsToExpectAcksFromC TEXT,
      $ackedStatusC INTEGER,
      $isUploadedToFirebaseC INTEGER,
      $imageUrlsC TEXT,
      FOREIGN KEY ($roomIdentifierC)
        REFERENCES ${ShareRoomsTable.name} (${ShareRoomsTable.identifierC})
        ON UPDATE CASCADE
        ON DELETE CASCADE
    )
  ''';

  static const String dropTableStatement = '''
    DROP TABLE IF EXISTS $name
  ''';

  static const String unreadCountTC = 'UnreadCount';

  static String getAllRoomsWithLatestItemStatement = '''
    SELECT
      sr.${ShareRoomsTable.identifierC} ${ShareRoomsTable.identifierC},
      sr.${ShareRoomsTable.nameC} ${ShareRoomsTable.nameC},
      CASE
        WHEN a.$unreadCountTC IS NULL THEN 0
        ELSE a.$unreadCountTC
      END $unreadCountTC,
      si.$creatorIdC $creatorIdC,
      si.$timeOfCreationC $timeOfCreationC,
      si.$typeC $typeC,
      si.$contentC $contentC,
      si.$ackedStatusC $ackedStatusC,
      c.${ContactsTable.usernameC} ${ContactsTable.usernameC},
      c.${ContactsTable.firebaseUserIdentifierC} ${ContactsTable.firebaseUserIdentifierC}
    FROM
      ${ShareRoomsTable.name} AS sr
      LEFT JOIN (
        SELECT $roomIdentifierC, COUNT($ackedStatusC) $unreadCountTC
        FROM $name
        WHERE $ackedStatusC IN (
          ${ShareItemAckedStatus.None.index},
          ${ShareItemAckedStatus.AckedReceive.index}
        )
        GROUP BY $roomIdentifierC
      ) AS a
        ON (sr.${ShareRoomsTable.identifierC} = a.$roomIdentifierC)
      LEFT JOIN (
        SELECT $roomIdentifierC, MAX($timeOfCreationC) $timeOfCreationC
        FROM $name
        GROUP BY $roomIdentifierC
      ) AS b
        ON (sr.${ShareRoomsTable.identifierC} = b.$roomIdentifierC)
      LEFT JOIN $name AS si
        ON (
          sr.${ShareRoomsTable.identifierC} = si.$roomIdentifierC
          AND
          b.$timeOfCreationC = si.$timeOfCreationC
        )
      LEFT JOIN ${ContactsTable.name} AS c
        ON (sr.${ShareRoomsTable.otherGuyIdC} = c.${ContactsTable.userIdC})
    ORDER BY si.$timeOfCreationC DESC -- @@NOTE: Empty rooms will be last
  ''';

  static const String getConfirmedRoomsWithLatestConfirmedTimeOfCreationStatement = '''
    SELECT
      sr.${ShareRoomsTable.identifierC} ${ShareRoomsTable.identifierC},
      CASE
        WHEN a.$timeOfCreationC IS NULL THEN 0
        ELSE a.$timeOfCreationC
      END $timeOfCreationC
    FROM
      ${ShareRoomsTable.name} AS sr
      LEFT JOIN (
        SELECT $roomIdentifierC, MAX($timeOfCreationC) $timeOfCreationC
        FROM $name
        WHERE $isConfirmedC = 1
        GROUP BY $roomIdentifierC
      ) AS a
        ON (sr.${ShareRoomsTable.identifierC} = a.$roomIdentifierC)
    WHERE sr.${ShareRoomsTable.isConfirmedC} = 1
  ''';

  static const String itemCountTC = 'ItemCount';
}