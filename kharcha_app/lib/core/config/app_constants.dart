abstract final class AppConstants {
  static const String appName = 'Kharcha';
  static const String defaultCurrency = 'NPR';

  /// How often the app asks the server whether a freshly uploaded receipt has been read.
  static const Duration receiptPollEvery = Duration(seconds: 2);

  /// Stop waiting after this many polls (about a minute); the receipt then stays "Reading..." in the list.
  static const int receiptPollMax = 30;
}
