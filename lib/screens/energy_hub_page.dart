import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wisewatts/self_build_widget/budget_progress_ring.dart';
import 'energy_data_generator.dart';

enum TimeRange { week, month, year }

class EnergyHubPage extends StatefulWidget {
  @override
  _EnergyHubPageState createState() => _EnergyHubPageState();
}

class _EnergyHubPageState extends State<EnergyHubPage> {
  double _weeklyBudget = 2500.0;
  double _monthlyBudget = 50000.0;
  double _yearlyBudget = 600000.0;
  double _currentElectricityPrice = 0.30;
  final Map<String, List<double>> _simulatedData = {};
  TimeRange _selectedRange = TimeRange.week;

  double _lastTotalConsumption = 0.0;
  double _lastTotalCost = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchElectricityPrice();
  }

  double _getYAxisInterval(List<double> values) {
    final maxY = values.reduce(max);
    if (maxY <= 100) return 20;
    if (maxY <= 500) return 100;
    if (maxY <= 1000) return 200;
    if (maxY <= 3000) return 500;
    return 1000;
  }

  Future<void> _fetchElectricityPrice() async {
    final url = Uri.parse(
        'https://api.octopus.energy/v1/products/AGILE-FLEX-22-11-25/electricity-tariffs/E-1R-AGILE-FLEX-22-11-25-L/standard-unit-rates/');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['results'] as List;
        if (rates.isNotEmpty) {
          final latestRate = rates.first;
          final pricePence = latestRate['value_inc_vat'];
          setState(() {
            _currentElectricityPrice = (pricePence as num) / 100.0;
          });
        }
      }
    } catch (e) {
      print('Error fetching electricity price: $e');
    }
  }

  void _updateBudget(double value) {
    setState(() {
      switch (_selectedRange) {
        case TimeRange.month:
          _monthlyBudget = value;
          break;
        case TimeRange.year:
          _yearlyBudget = value;
          break;
        case TimeRange.week:
        default:
          _weeklyBudget = value;
      }
    });

    HapticFeedback.selectionClick();

    if (value == 50000 || value == 200000 || value == 2400000) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.white),
          SizedBox(width: 12),
          Expanded(child: Text("You’ve reached the maximum budget!")),
        ]),
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ));
    }

    _uploadEnergyStats(
      range: _selectedRange.name,
      budget: value,
      consumption: _lastTotalConsumption,
      cost: _lastTotalCost,
    );
  }

  double _getCurrentBudget() {
    switch (_selectedRange) {
      case TimeRange.month:
        return _monthlyBudget;
      case TimeRange.year:
        return _yearlyBudget;
      case TimeRange.week:
      default:
        return _weeklyBudget;
    }
  }

  Future<void> _uploadEnergyStats({
    required String range,
    required double budget,
    required double consumption,
    required double cost,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('energyStats')
        .doc(range);

    await docRef.set({
      'budget': budget,
      'consumption': consumption,
      'cost': cost,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  List<double> _calculateTotalEnergy(List<Map<String, dynamic>> devices) {
    int count = _selectedRange == TimeRange.week
        ? 7
        : _selectedRange == TimeRange.month
            ? 4
            : 12;
    bool monthly = _selectedRange == TimeRange.year;
    bool weeklyGroup = _selectedRange == TimeRange.month;

    List<double> totals = List.generate(count, (_) => 0.0);
    for (var device in devices) {
      final name = device['name'];
      final data = EnergyDataGenerator.generateEnergyData(name, count, monthly: monthly, weeklyGroup: weeklyGroup);

      _simulatedData[name] = data;
      for (int i = 0; i < count; i++) {
        totals[i] += data[i];
      }
    }
    return totals;
  }

  String _formatDateLabel(int index) {
    final now = DateTime.now();
    switch (_selectedRange) {
      case TimeRange.week:
        final date = now.subtract(Duration(days: 6 - index));
        return "${date.month}/${date.day}";
      case TimeRange.month:
        return "Week ${index + 1}";
      case TimeRange.year:
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final date = DateTime(now.year, now.month - 11 + index);
        return months[(date.month - 1) % 12];
    }
  }



  Widget _buildBudgetSection() {
    double minBudget, maxBudget, currentBudget;

    switch (_selectedRange) {
      case TimeRange.month:
        minBudget = 5000;
        maxBudget = 200000;
        currentBudget = _monthlyBudget;
        break;
      case TimeRange.year:
        minBudget = 60000;
        maxBudget = 2400000;
        currentBudget = _yearlyBudget;
        break;
      case TimeRange.week:
      default:
        minBudget = 1000;
        maxBudget = 50000;
        currentBudget = _weeklyBudget;
    }

    currentBudget = currentBudget.clamp(minBudget, maxBudget);

    return Column(
      children: [
        BudgetProgressRing(
          value: currentBudget,
          min: minBudget,
          max: maxBudget,
          color: _getBudgetColor(currentBudget),
        ),
        SizedBox(height: 20),
        Text(
          'Estimated Cost: £${(currentBudget / 1000 * _currentElectricityPrice).toStringAsFixed(2)}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _getBudgetColor(currentBudget),
              thumbColor: _getBudgetColor(currentBudget),
              overlayColor: _getBudgetColor(currentBudget).withOpacity(0.2),
            ),
            child: Slider(
              value: currentBudget,
              min: minBudget,
              max: maxBudget,
              divisions: ((maxBudget - minBudget) / 1000).round(),
              label: currentBudget.toStringAsFixed(0),
              onChanged: _updateBudget,
            ),
          ),
        ),
      ],
    );
  }

  Color _getBudgetColor(double budget) {
    return budget < 60000
        ? Color.lerp(Colors.green, Colors.red, (budget - 1000) / (50000 - 1000))!
        : Color.lerp(Colors.orange, Colors.red, (budget - 60000) / (2400000 - 60000))!;
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
              color: Colors.deepOrange,
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [Colors.deepOrange.withOpacity(0.4), Colors.deepOrange.withOpacity(0.05)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              dotData: FlDotData(show: false),
            )
          ],
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _getYAxisInterval(values),
                reservedSize: 40,
                getTitlesWidget: (value, _) => Text(
                  value.toStringAsFixed(0),
                  style: TextStyle(fontSize: 10),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) =>
                    Text(_formatDateLabel(value.toInt()), style: TextStyle(fontSize: 10)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(List<double> values) {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          barGroups: values.asMap().entries.map((e) {
            return BarChartGroupData(x: e.key, barRods: [
              BarChartRodData(
                toY: e.value,
                color: Colors.orangeAccent,
                width: 14,
                borderRadius: BorderRadius.circular(4),
              )
            ]);
          }).toList(),
          titlesData: FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _getYAxisInterval(values),
                reservedSize: 40,
                getTitlesWidget: (value, _) => Text(
                  value.toStringAsFixed(0),
                  style: TextStyle(fontSize: 10),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) =>
                    Text(_formatDateLabel(value.toInt()), style: TextStyle(fontSize: 10)),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
        ),
      ),
    );
  }

  Widget _buildTopConsumers(Map<String, List<double>> data) {
    final totals = data.entries
        .map((entry) => MapEntry(entry.key, entry.value.reduce((a, b) => a + b)))
        .toList();

    totals.sort((a, b) => b.value.compareTo(a.value));

    final top3 = totals.take(3).toList();
    final medals = ['🥇', '🥈', '🥉'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Text('Top 3 Energy Consumers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        ...List.generate(top3.length, (index) {
          final item = top3[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Text(medals[index], style: TextStyle(fontSize: 24)),
              title: Text(item.key),
              trailing: Text('${item.value.toStringAsFixed(1)} Wh'),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Center(child: Text("Not logged in"));

    return Scaffold(
      appBar: AppBar(title: Text('Energy Hub'), backgroundColor: Colors.orangeAccent),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('devices')
            .where('ownerId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final devices = snapshot.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();
          final total = _calculateTotalEnergy(devices);
          final totalWh = total.reduce((a, b) => a + b).toStringAsFixed(0);

          _lastTotalConsumption = double.tryParse(totalWh) ?? 0.0;
          _lastTotalCost = (_lastTotalConsumption / 1000) * _currentElectricityPrice;

          _uploadEnergyStats(
            range: _selectedRange.name,
            budget: _getCurrentBudget(),
            consumption: _lastTotalConsumption,
            cost: _lastTotalCost,
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  color: Colors.lightBlue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.electric_bolt, color: Colors.lightBlue, size: 28),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Current Price', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                            SizedBox(height: 4),
                            Text('£${_currentElectricityPrice.toStringAsFixed(2)} / kWh',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: ToggleButtons(
                  isSelected: [
                    _selectedRange == TimeRange.week,
                    _selectedRange == TimeRange.month,
                    _selectedRange == TimeRange.year,
                  ],
                  onPressed: (index) {
                    setState(() {
                      _selectedRange = TimeRange.values[index];
                    });
                  },
                  children: [
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("Week")),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("Month")),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("Year")),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(16),
                  children: [
                    _buildBudgetSection(),
                    SizedBox(height: 24),
                    Card(
                      elevation: 3,
                      color: Colors.orange.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(Icons.flash_on, color: Colors.orange, size: 32),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Total Consumption',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.orange)),
                                  SizedBox(height: 4),
                                  Text('$totalWh Wh',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 6),
                                  Text('Cost: £${_lastTotalCost.toStringAsFixed(2)}'),
                                  SizedBox(height: 8),
Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Padding(
      padding: const EdgeInsets.only(left: 2), 
      child: Icon(
        _lastTotalConsumption > _getCurrentBudget()
            ? Icons.warning_amber_rounded
            : Icons.check_circle_outline,
        color: _lastTotalConsumption > _getCurrentBudget()
            ? Colors.redAccent
            : Colors.green,
        size: 18, 
      ),
    ),
    SizedBox(width: 6),
    Flexible(
      child: Text(
        _lastTotalConsumption > _getCurrentBudget()
            ? 'Heads up ! Exceeded budget !'
            : 'Good performance, within budget.',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _lastTotalConsumption > _getCurrentBudget()
              ? Colors.redAccent
              : Colors.green,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    ),
  ],
),

                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.grey.shade200,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Energy Flow', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 12),
                            _buildLineChart(total),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    _buildTopConsumers(_simulatedData),
                    SizedBox(height: 24),
                    Text('Device Usage Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    ...devices.map((device) {
                      final name = device['name'];
                      final data = _simulatedData[name]!;
                      final avg = data.reduce((a, b) => a + b) / data.length;
                      final unit = _selectedRange == TimeRange.year
                          ? 'Wh/month'
                          : _selectedRange == TimeRange.month
                              ? 'Wh/week'
                              : 'Wh/day';

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ExpansionTile(
                          title: Text(name),
                          subtitle: Text('Avg: ${avg.toStringAsFixed(1)} $unit'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: _buildBarChart(data),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
