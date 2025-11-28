import 'package:flutter/material.dart';
import '../../../data/bible_data.dart';
import 'book_progress_card.dart';

class BookGrid extends StatelessWidget {
  final List<BibleBook> books;
  final Function(BibleBook) onBookTap;
  
  // This function allows the grid to ask "How many chapters are read for this book?"
  // will connect this to our Database later.
  final int Function(int bookId)? getCompletedChapters;

  const BookGrid({
    super.key,
    required this.books,
    required this.onBookTap,
    this.getCompletedChapters,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive Design:
    // If screen is wide (> 600px), show 4 columns. Otherwise show 2.
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 600 ? 4 : 2;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.5, // Controls the shape (width vs height)
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        
        // If we haven't hooked up the DB yet, assume 0 chapters read.
        final completed = getCompletedChapters?.call(book.id) ?? 0;

        return BookProgressCard(
          book: book,
          chaptersRead: completed,
          onTap: () => onBookTap(book),
        );
      },
    );
  }
}