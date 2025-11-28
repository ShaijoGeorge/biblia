import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/database_service.dart';
import '../data/bible_repository.dart';
import '../../../data/local/entities/reading_progress.dart';

part 'reading_providers.g.dart';

// 1. Provide the db service (keep alive so we dont reopen db constantly)
@Riverpod(keepAlive: true)
DatabaseService databaseService(Ref ref) {
  return DatabaseService();
}

// 2. Provide the Repository
@Riverpod(keepAlive: true)
BibleRepository bibleRepository(Ref ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return BibleRepository(dbService);
}

// 3. Provide the Read Count for a specific Book (e.g. Genesis)
// This is used by the Book Cards to show "5/50"
@riverpod
Future<int> bookReadCount(Ref ref, int bookId) async {
  final repo = ref.watch(bibleRepositoryProvider);
  
  // Fetch all progress records for this book
  final progressList = await repo.getBookProgress(bookId);
  
  // Return the count of chapters marked as 'isRead'
  return progressList.where((p) => p.isRead).length;
}

// 4. Provide the list of reading data for a specific Book
// This is used by the Chapter Grid to show which chapters are green
@riverpod
Future<List<ReadingProgress>> bookProgress(Ref ref, int bookId) async { 
  final repo = ref.watch(bibleRepositoryProvider);
  return repo.getBookProgress(bookId);
}