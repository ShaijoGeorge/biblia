import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/widgets/profile_drawer.dart'; // Import the drawer

class MainWrapper extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainWrapper({
    super.key,
    required this.navigationShell,
  });

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine the title based on the current tab index
    String title;
    switch (navigationShell.currentIndex) {
      case 0:
        title = 'Old Testament';
        break;
      case 1:
        title = 'Biblia'; // Home Tab
        break;
      case 2:
        title = 'New Testament';
        break;
      default:
        title = 'Biblia';
    }

    return Scaffold(
      // 1. The Global App Bar
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      
      // 2. The Global Drawer (Hamburger Menu)
      drawer: const ProfileDrawer(),
      
      // 3. The Body (The current tab's content)
      body: navigationShell,
      
      // 4. The Bottom Navigation
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
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