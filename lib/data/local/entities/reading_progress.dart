import 'package:isar_community/isar.dart';

part 'reading_progress.g.dart';

@collection
class ReadingProgress {
  // We manually set the ID so we can easily find a specific chapter
  // Logic: (BookID * 1000) + ChapterNumber
  // Example: Genesis (1) Chapter 5 = 1005
  Id id; 

  @Index() // Indexing makes searching by book fast
  final int bookId;

  final int chapterNumber;

  bool isRead;

  final DateTime? readAt;

  ReadingProgress({
    required this.bookId,
    required this.chapterNumber,
    this.isRead = false,
    this.readAt,
  }) : id = (bookId * 1000) + chapterNumber;
}