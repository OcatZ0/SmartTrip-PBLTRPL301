/// One day of the Open-Meteo forecast (F025).
class DayForecast {
  const DayForecast({
    required this.date,
    required this.weatherCode,
    required this.maxTemperature,
    required this.minTemperature,
    required this.rainChance,
  });

  /// Rain from this chance on counts as a rainy day.
  static const rainyChance = 60;

  /// WMO codes for drizzle, rain, showers and thunderstorms.
  static bool isRainCode(int code) =>
      (code >= 51 && code <= 67) || (code >= 80 && code <= 82) || (code >= 95 && code <= 99);

  final DateTime date;
  final int weatherCode;
  final double maxTemperature;
  final double minTemperature;

  /// 0-100, the day's highest hourly chance of rain.
  final int rainChance;

  bool get isRainy => rainChance >= rainyChance || isRainCode(weatherCode);
}
