import 'package:isar_community/isar.dart';
import '../../../core/database_service.dart';
import '../../../data/local/entities/reading_progress.dart';

class BibleRepository {
  final DatabaseService _dbService;

  BibleRepository(this._dbService);

  // Get reading status for a specific book
  Future<List<ReadingProgress>> getBookProgress(int bookId) async {
    final isar = await _dbService.db;
    return await isar.readingProgress 
        .filter()
        .bookIdEqualTo(bookId)
        .findAll();
  }

  // Mark a chapter as read/unread
  Future<void> toggleChapter(int bookId, int chapterNumber, bool isRead) async {
    final isar = await _dbService.db;
    
    // Create the record
    final progress = ReadingProgress(
      bookId: bookId,
      chapterNumber: chapterNumber,
      isRead: isRead,
      readAt: isRead ? DateTime.now() : null,
    );

    // Save it to the DB (writeTxn is required for writing to Isar)
    await isar.writeTxn(() async {
      await isar.readingProgress.put(progress);
    });
  }

  // Count total chapters read in the whole Bible
  Future<int> countTotalRead() async {
    final isar = await _dbService.db;
    return await isar.readingProgress
        .filter()
        .isReadEqualTo(true)
        .count();
  }
}