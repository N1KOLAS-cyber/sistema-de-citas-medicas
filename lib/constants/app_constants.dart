class AppConstants {
  // App Information
  static const String appName = 'Sistema de Citas Médicas';
  static const String appVersion = '1.0.0';
  
  // Admin Configuration
  static const String adminEmail = 'admin@sistemacitas.com';
  static const String adminPassword = 'admin123';
  
  // Test User Configuration
  static const String testUserEmail = 'usuario@test.com';
  static const String testUserPassword = '123456';
  
  // Anonymous User Configuration
  static const bool enableAnonymousLogin = true;
  
  // Colors
  static const int primaryColorValue = 0xFF1976D2;
  static const int secondaryColorValue = 0xFF42A5F5;
  static const int accentColorValue = 0xFF26A69A;
  static const int errorColorValue = 0xFFE57373;
  static const int successColorValue = 0xFF81C784;
  static const int warningColorValue = 0xFFFFB74D;
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String appointmentsCollection = 'appointments';
  static const String specialtiesCollection = 'specialties';
  
  // Time Slots
  static const List<String> timeSlots = [
    '08:00 AM',
    '08:30 AM',
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '12:00 PM',
    '12:30 PM',
    '01:00 PM',
    '01:30 PM',
    '02:00 PM',
    '02:30 PM',
    '03:00 PM',
    '03:30 PM',
    '04:00 PM',
    '04:30 PM',
    '05:00 PM',
    '05:30 PM',
    '06:00 PM',
    '06:30 PM',
    '07:00 PM',
    '07:30 PM',
  ];
  
  // Validation
  static const int minPasswordLength = 6;
  static const int minNameLength = 2;
  static const int minPhoneLength = 10;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 4.0;
  
  // Error Messages
  static const String genericError = 'Ha ocurrido un error inesperado';
  static const String networkError = 'Error de conexión. Verifica tu internet';
  static const String authError = 'Error de autenticación';
  static const String validationError = 'Por favor verifica los datos ingresados';
  
  // Success Messages
  static const String loginSuccess = 'Inicio de sesión exitoso';
  static const String registerSuccess = 'Registro exitoso';
  static const String updateSuccess = 'Actualización exitosa';
  static const String deleteSuccess = 'Eliminación exitosa';
  
  // Placeholder Images
  static const String defaultProfileImage = 'assets/images/default_profile.png';
  static const String defaultDoctorImage = 'assets/images/default_doctor.png';
  
  // API Endpoints (if needed in the future)
  static const String baseUrl = 'https://api.sistemacitas.com';
  static const String apiVersion = 'v1';
}
