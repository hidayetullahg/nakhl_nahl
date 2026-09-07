import '../services/supabase_service.dart';

class Script {
  final String code; // Latn, Arab, Hans, Cyrl
  final String name;
  final String defaultDirection; // ltr, rtl
  final bool isActive;

  const Script({
    required this.code,
    required this.name,
    required this.defaultDirection,
    required this.isActive,
  });

  bool get isRtl => defaultDirection.toLowerCase() == 'rtl';

  factory Script.fromMap(Map<String, dynamic> map) {
    return Script(
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      defaultDirection: map['default_direction'] ?? 'ltr',
      isActive: map['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'default_direction': defaultDirection,
      'is_active': isActive,
    };
  }
}

class ScriptRepository {
  ScriptRepository._();
  static final ScriptRepository instance = ScriptRepository._();

  /// Yazı sistemlerini (alfabeler) listeler
  Future<List<Script>> getScripts({bool onlyActive = true}) async {
    try {
      var query = SupabaseService.client.from('scripts').select();
      if (onlyActive) {
        query = query.eq('is_active', true);
      }
      final response = await query.order('name', ascending: true);
      return (response as List<dynamic>)
          .map((m) => Script.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Script koduna göre getirir
  Future<Script?> getScriptByCode(String code) async {
    try {
      final response = await SupabaseService.client
          .from('scripts')
          .select()
          .eq('code', code.trim())
          .maybeSingle();

      if (response != null) {
        return Script.fromMap(response);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
