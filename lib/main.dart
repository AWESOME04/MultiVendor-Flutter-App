import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'services/user_service.dart';

void main() async {
  // This is required to use platform channels before runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Create and initialize UserService
  final userService = UserService();
  await userService.initializeFromStorage();

  runApp(
    ChangeNotifierProvider.value(
      value: userService,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Multi Vendor App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
