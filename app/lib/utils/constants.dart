class AppConfig {
  // Android emulator → 10.0.2.2, iOS simulator → localhost, physical device → your LAN IP
  // After deploying to Render, replace with your Render URL
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    // defaultValue: 'http://10.0.2.2:3000',
    defaultValue: 'https://quick-slot-iapy.onrender.com',
  );
}
