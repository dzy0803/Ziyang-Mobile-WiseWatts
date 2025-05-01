import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'dart:math';

import 'package:wisewatts/self_build_widget/budget_progress_ring.dart'; // self-build widget

class EnergyHubPage extends StatefulWidget {
  @override
  _EnergyHubPageState createState() => _EnergyHubPageState();
}

class _EnergyHubPageState extends State<EnergyHubPage> {
  final Map<String, List<double>> _simulatedData = {};
  final List<String> _addedDevices = [
    'Air Conditioner',
    'Smart TV',
    'Washing Machine',
  ];

  List<double> _totalEnergyHistory = [];
  List<String> _energyTips = [];
  double _energyBudget = 2500.0;

  @override
  void initState() {
    super.initState();
    _generateSimulatedData();
  }

  void _generateSimulatedData() {
    final random = Random();
    for (String device in _addedDevices) {
      _simulatedData[device] =
          List.generate(24, (_) => 60 + random.nextInt(80) + random.nextDouble());
    }
    _calculateTotalEnergy();
    _generateEnergyTips();
  }

  void _calculateTotalEnergy() {
    _totalEnergyHistory = List.generate(24, (i) {
      double sum = 0;
      for (var list in _simulatedData.values) {
        sum += list[i];
      }
      return sum;
    });
  }

  void _generateEnergyTips() {
    _energyTips.clear();
    for (var entry in _simulatedData.entries) {
      double avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      if (avg > 120) {
        _energyTips.add("${entry.key} is consuming high power. Consider reducing usage.");
      } else if (avg < 80) {
        _energyTips.add("${entry.key} is operating efficiently. No action needed.");
      } else {
        _energyTips.add("${entry.key} has moderate power consumption. Monitor usage if necessary.");
      }
    }
  }

void _updateBudget(double newBudget) {
  setState(() {
    _energyBudget = newBudget;
  });

  HapticFeedback.selectionClick();

  if (newBudget == 5000) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text("You’ve reached the maximum budget!")),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }
}


  Color _getBudgetColor(double budget) {
    final t = (budget - 1000) / 4000;
    if (t <= 0.5) {
      return Color.lerp(Colors.green, Colors.orange, t * 2)!;
    } else {
      return Color.lerp(Colors.orange, Colors.red, (t - 0.5) * 2)!;
    }
  }

  Widget _buildBudgetSection() {
    return Column(
      children: [
        BudgetProgressRing(
          value: _energyBudget,
          min: 1000,
          max: 5000,
          color: _getBudgetColor(_energyBudget),
        ),
        SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _getBudgetColor(_energyBudget),
              inactiveTrackColor: Colors.grey.shade300,
              thumbColor: _getBudgetColor(_energyBudget),
              overlayColor: _getBudgetColor(_energyBudget).withOpacity(0.2),
            ),
            child: Slider(
              value: _energyBudget,
              min: 1000,
              max: 5000,
              divisions: 8,
              label: _energyBudget.toStringAsFixed(0),
              onChanged: _updateBudget,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart(List<double> values) {
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: values.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
              isCurved: true,
              color: Colors.orange,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [Colors.orange.withOpacity(0.4), Colors.orange.withOpacity(0.05)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              dotData: FlDotData(show: false),
              barWidth: 3,
            ),
          ],
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(show: false),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Energy Hub'),
        backgroundColor: Colors.orangeAccent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildBudgetSection(),
          SizedBox(height: 20),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Energy Usage (Last 24h)', style: TextStyle(fontSize: 18, color: Colors.grey[700])),
                  SizedBox(height: 16),
                  _buildLineChart(_totalEnergyHistory),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          ..._energyTips.map((tip) => Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orangeAccent),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(child: Text(tip, style: TextStyle(fontSize: 14))),
                  ],
                ),
              )),
          SizedBox(height: 24),
          Text('Device Energy Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
          SizedBox(height: 12),
          ..._addedDevices.map((device) {
            final history = _simulatedData[device]!;
            final current = history.last;
            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ExpansionTile(
                leading: Icon(Icons.power, color: Colors.orange),
                title: Text(device),
                subtitle: Text('Current: ${current.toStringAsFixed(1)} W'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _buildLineChart(history),
                  )
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
