import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'screens/splash_page.dart';
import 'screens/main_page.dart'; 

void main() {
  runApp(WiseWattsApp());
}

class WiseWattsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WiseWatts',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashPage(),   // First load Splash
        '/main': (context) => MainPage(),  // After Splash go to MainPage
      },
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
      ),
    );
  }
}
