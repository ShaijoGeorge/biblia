import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/widgets/profile_drawer.dart';
import '../../features/reading/providers/reading_providers.dart'; // Import providers

class MainWrapper extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainWrapper({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends ConsumerState<MainWrapper> {
  
  @override
  void initState() {
    super.initState();
    // Trigger Sync when the main layout loads!
    // We use postFrameCallback to ensure the provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bibleRepositoryProvider).syncFromCloud().then((_) {
        // Optional: Refresh stats after sync finishes
        // ref.invalidate(userStatsProvider); 
      });
    });
  }

  void _goBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine the title based on the current tab index
    String title;
    switch (widget.navigationShell.currentIndex) {
      case 0: title = 'Old Testament'; break;
      case 1: title = 'Biblia'; break;
      case 2: title = 'New Testament'; break;
      default: title = 'Biblia';
    }

    return Scaffold(
      // 1. The Global App Bar
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      
      // 2. The Global Drawer (Hamburger Menu)
      drawer: const ProfileDrawer(),
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: _goBranch,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Old Testament',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: 'New Testament',
          ),
        ],
      ),
    );
  }
}