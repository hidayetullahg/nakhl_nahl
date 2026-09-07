import '../services/supabase_service.dart';

class Language {
  final String code; // tr, ar, en, fa, ur
  final String englishName;
  final String nativeName;
  final String? isoCode;
  final bool isActive;

  const Language({
    required this.code,
    required this.englishName,
    required this.nativeName,
    this.isoCode,
    required this.isActive,
  });

  factory Language.fromMap(Map<String, dynamic> map) {
    return Language(
      code: map['code'] ?? '',
      englishName: map['english_name'] ?? '',
      nativeName: map['native_name'] ?? '',
      isoCode: map['iso_code'],
      isActive: map['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'english_name': englishName,
      'native_name': nativeName,
      'iso_code': isoCode,
      'is_active': isActive,
    };
  }
}

class LanguageRepository {
  LanguageRepository._();
  static final LanguageRepository instance = LanguageRepository._();

  /// Sistemde desteklenen dilleri listeler (TR, EN, AR, FA, UR vb.)
  Future<List<Language>> getLanguages({bool onlyActive = true}) async {
    try {
      var query = SupabaseService.client.from('languages').select();
      if (onlyActive) {
        query = query.eq('is_active', true);
      }
      final response = await query.order('english_name', ascending: true);
      return (response as List<dynamic>)
          .map((m) => Language.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Dil koduna göre dili getirir
  Future<Language?> getLanguageByCode(String code) async {
    try {
      final response = await SupabaseService.client
          .from('languages')
          .select()
          .eq('code', code.toLowerCase().trim())
          .maybeSingle();

      if (response != null) {
        return Language.fromMap(response);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
