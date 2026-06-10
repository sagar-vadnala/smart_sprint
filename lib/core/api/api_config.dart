abstract final class ApiConfig {
  static const String baseUrl = 'https://smartsprint-api.onrender.com';

  static const Duration connectTimeout = Duration(seconds: 60);

  // Render free tier can cold-start ~50s — give responses room to arrive.
  static const Duration receiveTimeout = Duration(seconds: 60);

  static const String googleClientId =
      '877311075483-gn9l3pe80c36mlfpap48i39227atraig.apps.googleusercontent.com';
}
