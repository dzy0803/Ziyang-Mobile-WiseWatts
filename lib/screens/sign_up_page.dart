import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = false;

  // Lookup address from UK postcode API and fill the address text field
  Future<void> _lookupAddressByPostcode() async {
    final postcode = _postcodeController.text.trim();
    if (postcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a postcode.'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final url = Uri.parse('https://api.postcodes.io/postcodes/$postcode');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['result'];
        final address = '${result['admin_ward']}, ${result['admin_district']}, ${result['region']}, ${result['country']}';
        _addressController.text = address;
      } else {
        throw Exception('Invalid postcode');
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Address lookup failed. Try a valid UK postcode.'), backgroundColor: Colors.red),
      );
    }
  }

  // Register user and save account info and address in Firestore
  void _register() async {
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final postcode = _postcodeController.text.trim();
    final address = _addressController.text.trim();

    if (password != confirmPassword) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match.'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user?.uid;

      // Parse structured address from address string
      final parts = address.split(',').map((e) => e.trim()).toList();
      final addressLine1 = parts.isNotEmpty ? parts[0] : '';
      final addressLine2 = parts.length > 1 ? parts[1] : '';
      final city = parts.length > 2 ? parts[2] : '';
      final country = parts.length > 3 ? parts[3] : '';

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': name,
        'phone': phone,
        'email': email,
        'postcode': postcode,
        'address': address,
        'addressLine1': addressLine1,
        'addressLine2': addressLine2,
        'city': city,
        'country': country,
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Registration successful! Please login.'), backgroundColor: Colors.green),
      );

      Future.delayed(Duration(seconds: 1), () => Navigator.pop(context));
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed.';
      if (e.code == 'email-already-in-use') message = 'This email is already registered.';
      if (e.code == 'invalid-email') message = 'The email address is not valid.';
      if (e.code == 'weak-password') message = 'Password should be at least 6 characters.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(TextEditingController controller, String labelText,
      {bool obscure = false, TextInputType keyboardType = TextInputType.text, Widget? suffix}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(),
        suffixIcon: suffix,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up'), backgroundColor: Colors.blueAccent),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text('Create a new account', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 30),
              _buildTextField(_nameController, 'Full Name'),
              SizedBox(height: 20),
              _buildTextField(_phoneController, 'Phone Number', keyboardType: TextInputType.phone),
              SizedBox(height: 20),
              _buildTextField(_postcodeController, 'Postcode', suffix: IconButton(
                icon: Icon(Icons.search),
                onPressed: _lookupAddressByPostcode,
              )),
              SizedBox(height: 20),
              _buildTextField(_addressController, 'Auto-filled Address'),
              SizedBox(height: 20),
              _buildTextField(_emailController, 'Email', keyboardType: TextInputType.emailAddress),
              SizedBox(height: 20),
              _buildTextField(_passwordController, 'Password (min 6 chars)', obscure: true),
              SizedBox(height: 20),
              _buildTextField(_confirmPasswordController, 'Confirm Password', obscure: true),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12)),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Register', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
