import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'services/supabase_service.dart';
import 'services/auth_service.dart';
import 'screens/cari_kart_ekle_screen.dart';
import 'screens/login_screen.dart';
import 'screens/tenant_selection_screen.dart';
import 'screens/onboarding/first_time_setup_screen.dart';
import 'core/i18n/locale_script_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase Bağlantı Başlatması (Ortam konfigürasyonu üzerinden)
  final config = AppConfig.current;
  bool initializationSuccess = true;
  String? initializationError;

  try {
    await SupabaseService.initialize(
      url: config.supabaseUrl,
      anonKey: config.supabaseAnonKey,
    );
  } catch (e) {
    initializationSuccess = false;
    initializationError = e.toString();
  }

  runApp(NakhlNahlApp(
    initializationSuccess: initializationSuccess,
    initializationError: initializationError,
  ));
}

class NakhlNahlApp extends StatelessWidget {
  final bool initializationSuccess;
  final String? initializationError;

  const NakhlNahlApp({
    super.key,
    this.initializationSuccess = true,
    this.initializationError,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LocaleScriptManager.instance,
      builder: (context, _) {
        final profile = LocaleScriptManager.instance.currentLocale;

        return MaterialApp(
          title: 'NAKHL&NAHL — Global ERP',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFF5C4033),
            scaffoldBackgroundColor: const Color(0xFFFBF9F1),
            fontFamily: profile.typography.primaryFontFamily,
          ),
          builder: (context, child) {
            return Directionality(
              textDirection: profile.direction,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: initializationSuccess
              ? const GuvenliGirisEkrani()
              : ServiceUnavailableScreen(errorDetails: initializationError),
        );
      },
    );
  }
}


/// Supabase Veritabanı Bağlantı Hatası Ekranı (DATABASE_CONNECTION_ERROR / SERVICE_UNAVAILABLE)
class ServiceUnavailableScreen extends StatelessWidget {
  final String? errorDetails;

  const ServiceUnavailableScreen({super.key, this.errorDetails});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5C4033),
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text(
                'SERVICE_UNAVAILABLE',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB71C1C),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'DATABASE_CONNECTION_ERROR: Supabase sunucusuna erişilemedi veya bağlantı ayarları yapılandırılmadı.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              if (errorDetails != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    errorDetails!,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Re-launch app initialization
                  main();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Deneyin'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: const Color(0xFF5C4033),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GuvenliGirisEkrani extends StatefulWidget {
  const GuvenliGirisEkrani({super.key});

  @override
  State<GuvenliGirisEkrani> createState() => _GuvenliGirisEkraniState();
}

class _GuvenliGirisEkraniState extends State<GuvenliGirisEkrani> {
  final TextEditingController _pinController = TextEditingController();
  bool _hataliGiris = false;

  void _girisYap() {
    if (AuthService.instance.pinDogrula(_pinController.text.trim())) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TenantSelectionScreen()),
      );
    } else {
      setState(() => _hataliGiris = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5C4033),
      body: Center(
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 6))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.eco_rounded, size: 64, color: Color(0xFF5C4033)),
              const SizedBox(height: 14),
              const Text('NAKHL & NAHL ERP',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Color(0xFF5C4033))),
              const Text('Kurumsal Bulut Yönetim Sistemi',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 24),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'PIN',
                  errorText: _hataliGiris ? 'Hatalı PIN (Varsayılan: 1234)' : null,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (val) {
                  if (val.length == 4) _girisYap();
                  setState(() => _hataliGiris = false);
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _girisYap,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Hızlı Giriş Yap'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: const Color(0xFF5C4033),
                  foregroundColor: Colors.amberAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                icon: const Icon(Icons.lock_outline_rounded, size: 18),
                label: const Text('🔐 Kurumsal Giriş (E-Posta / Şifre)'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  foregroundColor: const Color(0xFF5C4033),
                  side: const BorderSide(color: Color(0xFF5C4033)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FirstTimeSetupScreen()),
                  );
                },
                icon: const Icon(Icons.rocket_launch_rounded, size: 18, color: Color(0xFFC89033)),
                label: const Text(
                  '✨ İlk Kez mi Açıyorsunuz? Şirketinizi Kurun',
                  style: TextStyle(color: Color(0xFF5C4033), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnaMenuEkrani extends StatelessWidget {
  const AnaMenuEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF5C4033),
        title: const Text('NAKHL&NAHL — Ana Menü (Supabase)',
            style: TextStyle(color: Colors.amberAccent)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hoş Geldiniz, Sayın Hidayetullah Hocam',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5C4033))),
            const Text('Supabase veritabanına bağlı modüller:',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CariKartEkleScreen()),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.brown.shade200),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.contacts,
                              size: 48, color: Color(0xFF5C4033)),
                          SizedBox(height: 12),
                          Text('Cari Kartlar',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
