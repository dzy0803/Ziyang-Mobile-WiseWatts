import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

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
        '/': (context) => SplashPage(),
        '/home': (context) => HomePage(),
        '/deviceDetail': (context) => DeviceDetailPage(),
      },
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
      ),
    );
  }
}

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  double _opacity = 0.0;
  double _progress = 0.0; // Progress value for the loading bar
  bool _isIndeterminate = true; // Whether the loading bar is indeterminate
  bool _showCheck = false; // Whether to show the checkmark animation
  double _checkOpacity = 0.0; // Opacity of the checkmark animation

  late AnimationController _haloController;
  late Animation<double> _haloSizeAnimation;
  late Animation<double> _haloOpacityAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize halo animation controller
    _haloController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    _haloSizeAnimation = Tween<double>(begin: 0, end: 200).animate(
      CurvedAnimation(parent: _haloController, curve: Curves.easeOut),
    );

    _haloOpacityAnimation = Tween<double>(begin: 0.5, end: 0).animate(
      CurvedAnimation(parent: _haloController, curve: Curves.easeOut),
    );

    // Logo fade-in
    Future.delayed(Duration(milliseconds: 300), () {
      setState(() {
        _opacity = 1.0;
      });
    });

    // First 2 seconds: keep indeterminate loading
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isIndeterminate = false;
      });
      _simulateLoading();
    });
  }

  void _simulateLoading() async {
    // Quickly fill the loading bar
    for (int i = 0; i <= 100; i++) {
      await Future.delayed(Duration(milliseconds: 5));
      setState(() {
        _progress = i / 100;
      });
    }

    // After loading is complete, show checkmark
    setState(() {
      _showCheck = true;
    });

    Future.delayed(Duration(milliseconds: 200), () {
      setState(() {
        _checkOpacity = 1.0;
      });
      _haloController.forward(); // Play halo expansion
    });

    // Navigate to Home after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  void dispose() {
    _haloController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double logoSize = screenWidth * 0.6;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo fade-in
            AnimatedOpacity(
              opacity: _opacity,
              duration: Duration(seconds: 2),
              curve: Curves.easeInOut,
              child: Image.asset(
                'assets/images/logo.png',
                width: logoSize,
                height: logoSize,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 40),
            // Loading bar
            AnimatedOpacity(
              opacity: _opacity,
              duration: Duration(seconds: 2),
              child: Container(
                width: screenWidth * 0.6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.orangeAccent,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: _isIndeterminate
                      ? LinearProgressIndicator(
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                        )
                      : LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                        ),
                ),
              ),
            ),
            SizedBox(height: 60),
            // Fixed area for checkmark and halo animation
            Container(
              width: 120,
              height: 120,
              child: _showCheck
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _haloController,
                          builder: (context, child) {
                            return Container(
                              width: _haloSizeAnimation.value,
                              height: _haloSizeAnimation.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.orangeAccent.withOpacity(_haloOpacityAnimation.value),
                              ),
                            );
                          },
                        ),
                        AnimatedOpacity(
                          opacity: _checkOpacity,
                          duration: Duration(seconds: 2),
                          child: Lottie.asset(
                            'assets/lottie/tickorange.json',
                            repeat: false,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    )
                  : SizedBox.shrink(), // Placeholder to maintain layout
            ),
          ],
        ),
      ),
    );
  }
}

// Home Page
class HomePage extends StatelessWidget {
  final List<String> deviceList = ['Fridge', 'Air Conditioner', 'Washer'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WiseWatts - Home'),
      ),
      body: ListView.builder(
        itemCount: deviceList.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(deviceList[index]),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/deviceDetail',
                arguments: deviceList[index],
              );
            },
          );
        },
      ),
    );
  }
}

// Device Detail Page
class DeviceDetailPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String deviceName = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(
        title: Text('$deviceName Detail'),
      ),
      body: Center(
        child: Text(
          'Details for $deviceName',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
