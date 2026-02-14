import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'config/routes.dart';

class HumanContactApp extends StatelessWidget {
  const HumanContactApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Human Contact',
      debugShowCheckedModeBanner: false,
      theme: buildHCTheme(),
      routerConfig: appRouter,
    );
  }
}
