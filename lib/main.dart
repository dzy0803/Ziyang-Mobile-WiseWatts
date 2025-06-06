import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_page.dart';
import 'screens/main_page.dart';
import 'screens/login_page.dart';
import 'screens/sensor_data_model.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(WiseWattsApp());
}


class WiseWattsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SensorDataModel(),
      child: MaterialApp(
        title: 'WiseWatts',
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => SplashPage(),
          '/main': (context) => MainPage(),
          '/login': (context) => LoginPage(
            onLoginSuccess: () {
              Navigator.pushReplacementNamed(context, '/main');
            },
          ),
        },
        theme: ThemeData(
          useMaterial3: true,
          primarySwatch: Colors.blue,
        ),
      ),
    );
  }
}