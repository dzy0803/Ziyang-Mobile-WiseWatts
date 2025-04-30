import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  double _opacity = 0.0;
  double _progress = 0.0;
  bool _isIndeterminate = true;
  double _checkOpacity = 0.0;
  bool _showLoginButton = false;
  double _loginOpacity = 0.0;

  late AnimationController _haloController;
  late Animation<double> _haloSizeAnimation;
  late Animation<double> _haloOpacityAnimation;

  @override
  void initState() {
    super.initState();

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

    Future.delayed(Duration(milliseconds: 300), () {
      setState(() {
        _opacity = 1.0;
        _checkOpacity = 1.0;
      });
      _haloController.forward();
    });

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isIndeterminate = false;
      });
      _simulateLoading();
    });
  }

  void _simulateLoading() async {
    for (int i = 0; i <= 100; i++) {
      await Future.delayed(Duration(milliseconds: 5));
      setState(() {
        _progress = i / 100;
      });
    }

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _showLoginButton = true;
        _loginOpacity = 1.0;
      });
    });
  }

  @override
  void dispose() {
    _haloController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
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
            Container(
              width: 120,
              height: 120,
              child: Stack(
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
                      'assets/lottie/light.json',
                      repeat: false,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            AnimatedOpacity(
              opacity: _loginOpacity,
              duration: Duration(seconds: 2),
              child: _showLoginButton
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _navigateToLogin,
                      child: Text(
                        'Login / Sign Up',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    )
                  : SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
