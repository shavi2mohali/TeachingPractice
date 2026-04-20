import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/providers/auth_provider.dart';

class TeachingPracticeApp extends StatelessWidget {
  const TeachingPracticeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Teaching Practice',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: const LoginPage(),
      ),
    );
  }
}
