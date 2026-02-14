import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'config/routes.dart';

class HumanContactApp extends ConsumerWidget {
  const HumanContactApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Human Contact',
      debugShowCheckedModeBanner: false,
      theme: buildHCTheme(),
      routerConfig: router,
    );
  }
}
