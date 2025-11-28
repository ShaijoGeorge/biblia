import 'package:flutter/material.dart';
import '../../../data/bible_data.dart';
import '../widgets/book_grid.dart';
import 'package:go_router/go_router.dart';

class NewTestamentScreen extends StatelessWidget {
  const NewTestamentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ntBooks = kBibleBooks
        .where((b) => b.testament == Testament.newTestament)
        .toList();

    return BookGrid(
      books: ntBooks,
      onBookTap: (book) {
        GoRouter.of(context).push('/book/${book.id}');
      },
    );
  }
}