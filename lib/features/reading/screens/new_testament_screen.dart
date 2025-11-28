import 'package:flutter/material.dart';
import '../../../data/bible_data.dart';
import '../widgets/book_grid.dart';

class NewTestamentScreen extends StatelessWidget {
  const NewTestamentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Filter the static data to get only NT books
    final ntBooks = kBibleBooks
        .where((b) => b.testament == Testament.newTestament)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("New Testament"),
      ),
      body: BookGrid(
        books: ntBooks,
        onBookTap: (book) {
          print("Tapped on ${book.name}");
        },
      ),
    );
  }
}