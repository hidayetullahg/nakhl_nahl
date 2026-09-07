/// NAKHL & NAHL — Kurumsal Konfigürasyon ve Ortam Yönetimi
/// Desteklenen Ortamlar: Development, Staging, Production

enum AppEnvironment {
  development,
  staging,
  production;

  static AppEnvironment fromString(String value) {
    switch (value.trim().toLowerCase()) {
      case 'prod':
      case 'production':
        return AppEnvironment.production;
      case 'stage':
      case 'staging':
        return AppEnvironment.staging;
      case 'dev':
      case 'development':
      default:
        return AppEnvironment.development;
    }
  }

  String get key {
    switch (this) {
      case AppEnvironment.production:
        return 'production';
      case AppEnvironment.staging:
        return 'staging';
      case AppEnvironment.development:
        return 'development';
    }
  }
}

class AppConfig {
  final AppEnvironment environment;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final bool enableLogging;
  final bool enableMockAuth;
  final Duration apiTimeout;
  final String appTitle;
  final String version;
  final String zatcaEnvironment;

  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.enableLogging = true,
    this.enableMockAuth = false,
    this.apiTimeout = const Duration(seconds: 30),
    this.appTitle = 'NAKHL & NAHL — Global ERP',
    this.version = '1.0.0+1',
    this.zatcaEnvironment = 'SIMULATION',
  });

  bool get isProduction => environment == AppEnvironment.production;
  bool get isStaging => environment == AppEnvironment.staging;
  bool get isDevelopment => environment == AppEnvironment.development;

  /// Compile-time environment flag'lerinden okunan aktif sistem konfigürasyonu.
  /// Örnek: flutter run --dart-define=APP_ENV=prod --dart-define=SUPABASE_URL=...
  static AppConfig get current {
    const envString = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    final env = AppEnvironment.fromString(envString);

    switch (env) {
      case AppEnvironment.production:
        return const AppConfig(
          environment: AppEnvironment.production,
          supabaseUrl: String.fromEnvironment(
            'SUPABASE_URL',
            defaultValue: 'https://nakhl-nahl.supabase.co',
          ),
          supabaseAnonKey: String.fromEnvironment(
            'SUPABASE_ANON_KEY',
            defaultValue: 'public-anon-key-prod',
          ),
          enableLogging: false,
          enableMockAuth: false,
          apiTimeout: Duration(seconds: 15),
          zatcaEnvironment: 'CORE_PRODUCTION',
        );

      case AppEnvironment.staging:
        return const AppConfig(
          environment: AppEnvironment.staging,
          supabaseUrl: String.fromEnvironment(
            'SUPABASE_URL',
            defaultValue: 'https://staging-nakhl-nahl.supabase.co',
          ),
          supabaseAnonKey: String.fromEnvironment(
            'SUPABASE_ANON_KEY',
            defaultValue: 'public-anon-key-staging',
          ),
          enableLogging: true,
          enableMockAuth: false,
          apiTimeout: Duration(seconds: 25),
          zatcaEnvironment: 'SIMULATION',
        );

      case AppEnvironment.development:
        return const AppConfig(
          environment: AppEnvironment.development,
          supabaseUrl: String.fromEnvironment(
            'SUPABASE_URL',
            defaultValue: 'https://nakhl-nahl.supabase.co',
          ),
          supabaseAnonKey: String.fromEnvironment(
            'SUPABASE_ANON_KEY',
            defaultValue: 'public-anon-key',
          ),
          enableLogging: true,
          enableMockAuth: true,
          apiTimeout: Duration(seconds: 60),
          zatcaEnvironment: 'DEVELOPER_SANDBOX',
        );
    }
  }
}
