import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/database_service.dart';
import '../../../data/local/entities/reading_progress.dart';

class BibleRepository {
  final DatabaseService _dbService;
  final SupabaseClient _supabase;

  BibleRepository(this._dbService, this._supabase);

  // Get Local Progress (No changes)
  Future<List<ReadingProgress>> getBookProgress(int bookId) async {
    final isar = await _dbService.db;
    return await isar.readingProgress
      .filter()
      .bookIdEqualTo(bookId)
      .findAll();
  }

  // Mark a chapter as read/unread (Updated: Writes to Local + Cloud)
  Future<void> toggleChapter(int bookId, int chapterNumber, bool isRead) async {
    final isar = await _dbService.db;
    final now = DateTime.now();

    // Create the record
    final progress = ReadingProgress(
      bookId: bookId,
      chapterNumber: chapterNumber,
      isRead: isRead,
      readAt: isRead ? now : null,
    );

    // A. Save to Local DB (Instant UI update)
    await isar.writeTxn(() async {
      await isar.readingProgress.put(progress);
    });

    // B. Save to Cloud (If logged in)
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      try {
        await _supabase.from('user_progress').upsert({
          'user_id': userId,
          'book_id': bookId,
          'chapter_number': chapterNumber,
          'is_read': isRead,
          'read_at': isRead ? now.toIso8601String() : null,
        }, onConflict: 'user_id, book_id, chapter_number'); 
        // Note: 'onConflict' ensures we update the existing row instead of creating duplicates
      } catch (e) {
        // Silently fail if offline. 
        // In a pro app, you'd add this to a "sync queue" to retry later.
        debugPrint('Cloud Sync Error: $e'); 
      }
    }
  }

  // Sync from Cloud
  // We call this when the user logs in or opens the app
  Future<void> syncFromCloud() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // A. Fetch all progress from Supabase
      final response = await _supabase
          .from('user_progress')
          .select()
          .eq('user_id', userId);

      final List<dynamic> data = response;
      if (data.isEmpty) return;

      // B. Save to Local DB
      final isar = await _dbService.db;
      
      await isar.writeTxn(() async {
        for (var row in data) {
          final bookId = row['book_id'] as int;
          final chapterNum = row['chapter_number'] as int;
          final isRead = row['is_read'] as bool;
          final readAtString = row['read_at'] as String?;
          final readAt = readAtString != null ? DateTime.parse(readAtString) : null;

          final progress = ReadingProgress(
            bookId: bookId,
            chapterNumber: chapterNum,
            isRead: isRead,
            readAt: readAt,
          );
          
          await isar.readingProgress.put(progress);
        }
      });
    } catch (e) {
      debugPrint('Sync From Cloud Error: $e');
    }
  }

  // Count total chapters read in the whole Bible
  Future<int> countTotalRead() async {
    final isar = await _dbService.db;
    return await isar.readingProgress
      .filter()
      .isReadEqualTo(true)
      .count();
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