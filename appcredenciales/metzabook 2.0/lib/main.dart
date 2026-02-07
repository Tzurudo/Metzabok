import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:shared_preferences/shared_preferences.dart';
=======
>>>>>>> 5c92128 (Initial commit)
import 'pages/welcome_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
<<<<<<< HEAD
  // Pre-carga SharedPreferences para evitar lag en la primera lectura
  await SharedPreferences.getInstance();
=======
>>>>>>> 5c92128 (Initial commit)
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Metzabok',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const WelcomePage(),
    );
  }
}
