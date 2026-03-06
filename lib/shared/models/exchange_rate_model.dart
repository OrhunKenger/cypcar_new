class ExchangeRate {
  final double gbpToTry;
  final double tryToGbp;
  final DateTime fetchedAt;

  ExchangeRate({
    required this.gbpToTry,
    required this.tryToGbp,
    required this.fetchedAt,
  });

  factory ExchangeRate.fromJson(Map<String, dynamic> j) => ExchangeRate(
        gbpToTry: (j['gbp_to_try'] as num).toDouble(),
        tryToGbp: (j['try_to_gbp'] as num).toDouble(),
        fetchedAt: DateTime.parse(j['fetched_at']),
      );

  // Fallback sabit kur
  factory ExchangeRate.fallback() => ExchangeRate(
        gbpToTry: 42.0,
        tryToGbp: 1 / 42.0,
        fetchedAt: DateTime.now(),
      );
}
