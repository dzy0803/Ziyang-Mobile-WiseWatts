import 'package:flutter/material.dart';

class SensorDataModel extends ChangeNotifier {
  // Singleton instance
  static final SensorDataModel _instance = SensorDataModel._internal();
  factory SensorDataModel() => _instance;
  SensorDataModel._internal();

  // History lists for each sensor (max 60 entries)
  final List<double> _lightHistory = [];
  final List<double> _temperatureHistory = [];
  final List<double> _humidityHistory = [];
  final List<double> _pressureHistory = [];

  // Public getters
  List<double> get lightHistory => List.unmodifiable(_lightHistory);
  List<double> get temperatureHistory => List.unmodifiable(_temperatureHistory);
  List<double> get humidityHistory => List.unmodifiable(_humidityHistory);
  List<double> get pressureHistory => List.unmodifiable(_pressureHistory);

  // Current averaged values
  double lightAvg = 0;
  double tempAvg = 0;
  double humidityAvg = 0;
  double pressureAvg = 0;

  // Timer for averaging once per minute
  void startAveraging() {
    _calculateAverages(); // Immediate initial average
    Future.delayed(Duration(seconds: 60), () {
      _calculateAverages();
      notifyListeners();
      startAveraging(); // Recursively trigger next update
    });
  }

  // Add new reading to each sensor history list
  void updateSensors({
    required double light,
    required double temperature,
    required double humidity,
    required double pressure,
  }) {
    _addToHistory(_lightHistory, light);
    _addToHistory(_temperatureHistory, temperature);
    _addToHistory(_humidityHistory, humidity);
    _addToHistory(_pressureHistory, pressure);
  }

  // Helper to update history list with max 60 items
  void _addToHistory(List<double> history, double value) {
    history.add(value);
    if (history.length > 60) history.removeAt(0);
  }

  // Calculate average values from current histories
  void _calculateAverages() {
    lightAvg = _calculateAvg(_lightHistory);
    tempAvg = _calculateAvg(_temperatureHistory);
    humidityAvg = _calculateAvg(_humidityHistory);
    pressureAvg = _calculateAvg(_pressureHistory);
  }

  double _calculateAvg(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }
}
