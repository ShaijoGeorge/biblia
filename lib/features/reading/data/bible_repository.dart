import 'package:isar_community/isar.dart';
import '../../../core/database_service.dart';
import '../../../data/local/entities/reading_progress.dart';

class BibleRepository {
  final DatabaseService _dbService;

  BibleRepository(this._dbService);

  // Get reading status for a specific book
  Future<List<ReadingProgress>> getBookProgress(int bookId) async {
    final isar = await _dbService.db;
    return await isar.readingProgress.filter().bookIdEqualTo(bookId).findAll();
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
    return await isar.readingProgress.filter().isReadEqualTo(true).count();
  }

  // Calculate current reading streak (consecutive days)
  Future<int> getCurrentStreak() async {
    final isar = await _dbService.db;

    // Get all dates where chapters were read, sorted newest to oldest
    final readDates = await isar.readingProgress
        .filter()
        .isReadEqualTo(true)
        .readAtIsNotNull()
        .sortByReadAtDesc()
        .readAtProperty()
        .findAll();

    if (readDates.isEmpty) {
      return 0;
    }

    // Normalize dates to remove time (Just Year-Month-Day)
    // Use a Set to remove duplicates (e.g. reading 2 chapters in one day)
    final uniqueDays = readDates
        .map((d) => DateTime(d!.year, d.month, d.day))
        .toSet()
        .toList();

    if (uniqueDays.isEmpty) {
      return 0;
    }

    // Define "Today" and "Yesterday"
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Check if the streak is active (Must have read Today OR Yesterday)
    // If the last read was 2 days ago, the streak is broken.
    if (uniqueDays.first != today && uniqueDays.first != yesterday) {
      return 0;
    }

    // Count backwards
    int streak = 0;
    DateTime targetDate = uniqueDays.first;

    for (final day in uniqueDays) {
      if (day == targetDate) {
        streak++;
        // Move target back 1 day for next iteration
        targetDate = targetDate.subtract(const Duration(days: 1));
      } else {
        // Gap found (e.g., read today, skipped yesterday, read day before)
        break;
      }
    }

    return streak;
  }
}