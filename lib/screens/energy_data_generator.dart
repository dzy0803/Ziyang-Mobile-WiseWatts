import 'dart:math';

/// Utility class to generate simulated energy data for devices.
class EnergyDataGenerator {
  /// Generate energy data based on device name and selected range.
  static List<double> generateEnergyData(
    String deviceName,
    int count, {
    bool monthly = false,
    bool weeklyGroup = false,
  }) {
    final now = DateTime.now();
    return List.generate(count, (i) {
      DateTime date;
      if (monthly) {
        date = DateTime(now.year, now.month - 11 + i);
      } else if (weeklyGroup) {
        date = now.subtract(Duration(days: (4 - i) * 7));
      } else {
        date = now.subtract(Duration(days: count - 1 - i));
      }
      final seed = deviceName.hashCode ^ date.year ^ date.month ^ (monthly ? 0 : date.day);
      final random = Random(seed);
      return monthly
          ? 2500 + random.nextInt(1000) + random.nextDouble()
          : weeklyGroup
              ? 700 + random.nextInt(300) + random.nextDouble()
              : 100 + random.nextInt(100) + random.nextDouble();
    });
  }
}
