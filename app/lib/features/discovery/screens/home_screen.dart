import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import 'discovery_screen.dart';
import '../screens/connections_screen.dart';
import '../screens/profile_tab_screen.dart';
import '../services/discovery_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  int _pendingRequestCount = 0;

  final _screens = const [
    DiscoveryScreen(),
    ConnectionsScreen(),
    ProfileTabScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    try {
      final service = ref.read(discoveryServiceProvider);
      final result = await service.getConnections(type: 'received', status: 'PENDING');
      final connections = result['connections'] as List;
      if (mounted) {
        setState(() => _pendingRequestCount = connections.length);
      }
    } catch (_) {}
  }

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
                    // Notifications placeholder
                    IconButton(
                      icon: const Icon(Icons.notifications_none, color: HCColors.textMuted, size: 22),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notifications coming soon!')),
                        );
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
        onDestinationSelected: (i) {
          setState(() => _currentIndex = i);
          if (i == 1) _loadPendingCount(); // Refresh count when switching to connections
        },
        backgroundColor: HCColors.bgDark,
        indicatorColor: HCColors.primary.withValues(alpha: 0.2),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore, color: HCColors.primary),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _pendingRequestCount > 0,
              label: Text('$_pendingRequestCount'),
              child: const Icon(Icons.people_outline),
            ),
            selectedIcon: Badge(
              isLabelVisible: _pendingRequestCount > 0,
              label: Text('$_pendingRequestCount'),
              child: const Icon(Icons.people, color: HCColors.primary),
            ),
            label: 'Connections',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: HCColors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
