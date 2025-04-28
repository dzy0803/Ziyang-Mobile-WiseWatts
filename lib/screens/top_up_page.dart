import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart'; // for using the ticking animation

class TopUpPage extends StatefulWidget {
  @override
  _TopUpPageState createState() => _TopUpPageState();
}

class _TopUpPageState extends State<TopUpPage> {
  final TextEditingController _cardController = TextEditingController();   // card information enter
  final TextEditingController _amountController = TextEditingController(); // the amount that user want to top up
  bool _cardConfirmed = false; //for checking whether the user has confirmed its card information

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Top Up Credit'),
        backgroundColor: Colors.orangeAccent,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ✨ 1. Card Information first
              Text(
                'Card Information:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _cardController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: 'Enter any card info...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (_cardController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter card information!')),
                      );
                    } else {
                      setState(() {
                        _cardConfirmed = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Card information confirmed!')),
                      );
                    }
                  },
                  child: Text(
                    'Confirm Card',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),

              SizedBox(height: 30),

              // 2. Top Up Amount second
              Text(
                'Enter the amount you want to top up:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (£)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 30),
              
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _cardConfirmed ? _onTopUpPressed : null,
                  child: Text(
                    'Confirm Top Up',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTopUpPressed() {
    String enteredAmount = _amountController.text;
    if (enteredAmount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter an amount')),
      );
    } else {
      double amount = double.tryParse(enteredAmount) ?? 0;
      _showConfirmationDialog(amount);
    }
  }

  void _showConfirmationDialog(double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Top Up'),
        content: Text('Are you sure you want to top up £${amount.toStringAsFixed(2)}?'),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('No', style: TextStyle(fontSize: 18)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _processTopUp(amount);
            },
            child: Text('Yes', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  void _processTopUp(double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          color: Colors.orangeAccent,
        ),
      ),
    );

    Future.delayed(Duration(seconds: 1), () {
      Navigator.of(context).pop(); // Close loading
      _showSuccessDialog(amount);
    });
  }

  void _showSuccessDialog(double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/lottie/tickorange.json',
              width: 120,
              height: 120,
              repeat: false,
            ),
            SizedBox(height: 16),
            Text(
              'Top Up Successful!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pop(context, amount); // renturn to HomePage
            },
            child: Text('OK', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}
