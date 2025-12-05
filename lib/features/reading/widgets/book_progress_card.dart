import 'package:flutter/material.dart';
import '../../../data/bible_data.dart';

class BookProgressCard extends StatefulWidget {
  final BibleBook book;
  final int chaptersRead;
  final VoidCallback onTap;
  final bool shouldAnimateEntry;
  final VoidCallback? onAnimationStarted;

  const BookProgressCard({
    super.key,
    required this.book,
    required this.chaptersRead,
    required this.onTap,
    this.shouldAnimateEntry = true,
    this.onAnimationStarted,
  });

  @override
  State<BookProgressCard> createState() => _BookProgressCardState();
}

class _BookProgressCardState extends State<BookProgressCard> {
  // This variable controls the width of the bar
  double _displayProgress = 0.0;

  @override
  void initState() {
    super.initState();
    
    final realProgress = widget.book.chapters > 0 
        ? widget.chaptersRead / widget.book.chapters 
        : 0.0;

    if (widget.shouldAnimateEntry) {
      // SCENARIO 1: First time loading (Animate 0 -> X)
      _displayProgress = 0.0;
      
      // Tell the parent "I have started animating, don't ask me again"
      widget.onAnimationStarted?.call();

      // Wait one frame, then trigger the animation to the real value
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _displayProgress = realProgress;
          });
        }
      });
    } else {
      // SCENARIO 2: Scrolled back into view (Jump instantly to X)
      // This prevents the "reloading" feel
      _displayProgress = realProgress;
    }
  }

  @override
  void didUpdateWidget(covariant BookProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // SCENARIO 3: User marked a chapter as read (Animate Old -> New)
    if (oldWidget.chaptersRead != widget.chaptersRead) {
      final newProgress = widget.book.chapters > 0 
          ? widget.chaptersRead / widget.book.chapters 
          : 0.0;
      
      setState(() {
        _displayProgress = newProgress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final realProgress = widget.book.chapters > 0 
        ? widget.chaptersRead / widget.book.chapters 
        : 0.0;
    final bool isCompleted = realProgress >= 1.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: RepaintBoundary( // Performance optimization
        child: Container(
          clipBehavior: Clip.antiAlias, 
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCompleted 
                  ? Theme.of(context).colorScheme.primary 
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              // Implicit Animation Widget
              // It will automatically animate whenever _displayProgress changes
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                widthFactor: _displayProgress.clamp(0.0, 1.0),
                alignment: Alignment.centerLeft,
                child: Container(
                  color: isCompleted 
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3) 
                      : Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.book.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      "${widget.chaptersRead} / ${widget.book.chapters}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}