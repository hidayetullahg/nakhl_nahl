import 'package:supabase_flutter/supabase_flutter.dart';

/// NAKHL & NAHL — Supabase Veritabanı ve Oturum Yönetim Servisi
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  /// Supabase İstemcisi
  static SupabaseClient get client => Supabase.instance.client;

  /// Supabase İstemcisini Başlat
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    // ignore: deprecated_member_use
    await Supabase.initialize(
      url: url,
      // ignore: deprecated_member_use
      anonKey: anonKey,
    );
  }

  /// Oturum açmış aktif kullanıcının kimliği
  static String? get currentAuthUserId => client.auth.currentUser?.id;

  /// Oturum açık mı?
  static bool get isAuthenticated => client.auth.currentUser != null;

  /// Carileri Gerçek Zamanlı Dinleme Akışı (Geriye dönük UI uyumluluğu için)
  static Stream<List<Map<String, dynamic>>> carileriGetirStream() {
    return client.from('cariler').stream(
        primaryKey: ['id']).order('olusturulma_tarihi', ascending: false);
  }
}
