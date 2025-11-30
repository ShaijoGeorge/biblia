import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/database_service.dart';
import '../../../data/local/entities/reading_progress.dart';

class BibleRepository {
  final DatabaseService _dbService;
  final SupabaseClient _supabase;

  BibleRepository(this._dbService, this._supabase);

  String get _currentUserId => _supabase.auth.currentUser?.id ?? '';

  // 1. Get Book Progress
  Future<List<ReadingProgress>> getBookProgress(int bookId) async {
    final userId = _currentUserId;
    if (userId.isEmpty) return [];

    final isar = await _dbService.db;
    return await isar.readingProgress
        .filter()
        .userIdEqualTo(userId)
        .and()
        .bookIdEqualTo(bookId)
        .findAll();
  }

  // 2. Toggle Chapter
  Future<void> toggleChapter(int bookId, int chapterNumber, bool isRead) async {
    final userId = _currentUserId;
    if (userId.isEmpty) return;

    final isar = await _dbService.db;
    final now = DateTime.now();

    final progress = ReadingProgress(
      userId: userId,
      bookId: bookId,
      chapterNumber: chapterNumber,
      isRead: isRead,
      readAt: isRead ? now : null,
    );

    // Save Local
    await isar.writeTxn(() async {
      await isar.readingProgress.put(progress);
    });

    // Save Cloud
    try {
      await _supabase.from('user_progress').upsert({
        'user_id': userId,
        'book_id': bookId,
        'chapter_number': chapterNumber,
        'is_read': isRead,
        'read_at': isRead ? now.toIso8601String() : null,
      }, onConflict: 'user_id, book_id, chapter_number');
    } catch (e) {
      debugPrint('Cloud Sync Error: $e');
    }
  }

  // 3. Sync from Cloud
  Future<void> syncFromCloud() async {
    final userId = _currentUserId;
    if (userId.isEmpty) return;

    try {
      final response = await _supabase
          .from('user_progress')
          .select()
          .eq('user_id', userId);

      final List<dynamic> data = response;
      if (data.isEmpty) return;

      final isar = await _dbService.db;
      
      await isar.writeTxn(() async {
        for (var row in data) {
          final progress = ReadingProgress(
            userId: userId,
            bookId: row['book_id'],
            chapterNumber: row['chapter_number'],
            isRead: row['is_read'],
            readAt: row['read_at'] != null ? DateTime.parse(row['read_at']) : null,
          );
          await isar.readingProgress.put(progress);
        }
      });
    } catch (e) {
      debugPrint('Sync Error: $e');
    }
  }

  // 4. Count Total
  Future<int> countTotalRead() async {
    final userId = _currentUserId;
    if (userId.isEmpty) return 0;

    final isar = await _dbService.db;
    return await isar.readingProgress
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isReadEqualTo(true)
        .count();
  }

  // 5. Calculate Streak
  Future<int> getCurrentStreak() async {
    final userId = _currentUserId;
    if (userId.isEmpty) return 0;

    final isar = await _dbService.db;
    
    final readDates = await isar.readingProgress
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isReadEqualTo(true)
        .readAtIsNotNull()
        .sortByReadAtDesc()
        .readAtProperty()
        .findAll();

    if (readDates.isEmpty) return 0;

    final uniqueDays = readDates
        .map((d) => DateTime(d!.year, d.month, d.day))
        .toSet()
        .toList();

    if (uniqueDays.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (uniqueDays.first != today && uniqueDays.first != yesterday) {
      return 0;
    }

    int streak = 0;
    DateTime targetDate = uniqueDays.first;

    for (final day in uniqueDays) {
      if (day == targetDate) {
        streak++;
        targetDate = targetDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }
}