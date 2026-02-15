import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../auth/providers/auth_provider.dart';
import 'discovery_screen.dart';
import '../screens/connections_screen.dart';
import '../screens/profile_tab_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    DiscoveryScreen(),
    ConnectionsScreen(),
    ProfileTabScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: HCColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: HCSpacing.lg,
                  vertical: HCSpacing.sm,
                ),
                child: Row(
                  children: [
                    Text(
                      'Human Contact',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: HCColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.logout, color: HCColors.textMuted, size: 20),
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) context.go(Routes.welcome);
                      },
                    ),
                  ],
                ),
              ),

              // Current screen
              Expanded(child: _screens[_currentIndex]),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: HCColors.bgDark,
        indicatorColor: HCColors.primary.withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore, color: HCColors.primary),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: HCColors.primary),
            label: 'Connections',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: HCColors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
