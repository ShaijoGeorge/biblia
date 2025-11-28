import 'package:flutter/material.dart';
import '../../../data/bible_data.dart';
import '../widgets/book_grid.dart';
import 'package:go_router/go_router.dart';

class OldTestamentScreen extends StatelessWidget {
  const OldTestamentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final otBooks = kBibleBooks
        .where((b) => b.testament == Testament.old)
        .toList();

    // Just return the content! The MainWrapper provides the Scaffold.
    return BookGrid(
      books: otBooks,
      onBookTap: (book) {
        GoRouter.of(context).push('/book/${book.id}');
      },
    );
  }
}