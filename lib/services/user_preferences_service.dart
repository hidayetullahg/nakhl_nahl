import 'package:flutter/material.dart';
import 'supabase_service.dart';
import '../models/user_preferences_model.dart';
import '../core/i18n/locale_script_manager.dart';

class UserPreferencesService extends ChangeNotifier {
  UserPreferencesService._();
  static final UserPreferencesService instance = UserPreferencesService._();

  UserPreferencesModel? _currentPreferences;
  UserPreferencesModel? get currentPreferences => _currentPreferences;

  /// Kullanıcının tenant tercihlerini yükler ve LocaleScriptManager'ı senkronize eder
  Future<UserPreferencesModel> loadPreferences({
    required String userId,
    required String tenantId,
  }) async {
    try {
      final response = await SupabaseService.client
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .eq('tenant_id', tenantId)
          .maybeSingle();

      if (response != null) {
        _currentPreferences = UserPreferencesModel.fromMap(response);
      } else {
        // Varsayılan tercihler oluştur
        _currentPreferences = UserPreferencesModel(
          id: '',
          userId: userId,
          tenantId: tenantId,
          primaryLanguageCode: 'tr',
          primaryScriptCode: 'Latn',
          activeLocaleId: 'tr-Latn',
          textDirection: 'ltr',
        );
      }
    } catch (_) {
      // Çevrimdışı / Hata durumunda varsayılan
      _currentPreferences ??= UserPreferencesModel(
        id: '',
        userId: userId,
        tenantId: tenantId,
        primaryLanguageCode: 'tr',
        primaryScriptCode: 'Latn',
        activeLocaleId: 'tr-Latn',
        textDirection: 'ltr',
      );
    }

    _applyToLocaleManager(_currentPreferences!);
    notifyListeners();
    return _currentPreferences!;
  }

  /// Kullanıcı tercihlerini kaydeder ve arayüze anında yansıtır
  Future<void> savePreferences(UserPreferencesModel preferences) async {
    _currentPreferences = preferences;
    _applyToLocaleManager(preferences);
    notifyListeners();

    try {
      final map = preferences.toMap();
      await SupabaseService.client
          .from('user_preferences')
          .upsert(map, onConflict: 'user_id,tenant_id');
    } catch (_) {
      // Offline toleransı
    }
  }

  void _applyToLocaleManager(UserPreferencesModel prefs) {
    LocaleScriptManager.instance.configureUserLanguages(
      primaryLanguage: prefs.primaryLanguageCode,
      primaryScript: prefs.primaryScriptCode,
      secondaryLanguage: prefs.secondaryLanguageCode,
      secondaryScript: prefs.secondaryScriptCode,
      tertiaryLanguage: prefs.tertiaryLanguageCode,
      tertiaryScript: prefs.tertiaryScriptCode,
    );

    if (prefs.activeLocaleId.isNotEmpty) {
      LocaleScriptManager.instance.setLocale(prefs.activeLocaleId);
    }
  }
}
