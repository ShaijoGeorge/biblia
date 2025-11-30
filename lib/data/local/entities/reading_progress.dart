import 'package:isar_community/isar.dart';

part 'reading_progress.g.dart';

@collection
class ReadingProgress {
  // ID is now a hash of UserID + BookID + Chapter
  // This ensures "User A's Genesis 1" is different from "User B's Genesis 1"
  Id id; 

  @Index() 
  final String userId; // This distinguishes User A from User B

  @Index()
  final int bookId;

  final int chapterNumber;

  bool isRead;

  final DateTime? readAt;

  ReadingProgress({
    required this.userId, 
    required this.bookId,
    required this.chapterNumber,
    this.isRead = false,
    this.readAt,
  }) : id = fastHash("$userId-$bookId-$chapterNumber"); 
}

// Helper to generate a unique ID string
int fastHash(String string) {
  var hash = 0xcbf29ce484222325;
  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }
  return hash;
}