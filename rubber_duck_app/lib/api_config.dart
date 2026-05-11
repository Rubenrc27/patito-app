class ApiConfig {
  // Configuración para el backend en Render
  static const String baseUrl = 'https://tfg-backend-mlek.onrender.com';
  
  static const String loginUrl = '$baseUrl/api/auth/login/';
  static const String registerUrl = '$baseUrl/api/auth/register/';
  static String profileUrl(int userId) => '$baseUrl/api/auth/profile/$userId/';
  static const String surveysUrl = '$baseUrl/api/surveys/';
}
