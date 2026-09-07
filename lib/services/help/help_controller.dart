// NAKHL & NAHL — Universal Help State Controller & Persistence Manager
// Complies with Master Directive Sections 22, 23, 31, 32

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/help_models.dart';
import 'help_registry.dart';

class HelpController extends ChangeNotifier {
  static final HelpController _instance = HelpController._internal();
  factory HelpController() => _instance;
  HelpController._internal() {
    _loadPreferences();
  }

  HelpMode _mode = HelpMode.detailed;
  bool _isDrawerOpen = false;
  HelpContent? _activeContent;
  String _currentRole = 'all';
  String _currentLanguage = 'tr';
  final Set<String> _dismissedHelpIds = {};
  final Map<String, int> _completedWizardSteps = {};

  HelpMode get mode => _mode;
  bool get isDrawerOpen => _isDrawerOpen;
  HelpContent? get activeContent => _activeContent;
  String get currentRole => _currentRole;
  String get currentLanguage => _currentLanguage;
  Set<String> get dismissedHelpIds => _dismissedHelpIds;
  Map<String, int> get completedWizardSteps => _completedWizardSteps;

  bool get isHelpVisible => _mode != HelpMode.off;
  bool get isDetailedHelp => _mode == HelpMode.detailed;

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeIndex = prefs.getInt('nakhl_help_mode') ?? HelpMode.detailed.index;
      _mode = HelpMode.values[modeIndex.clamp(0, HelpMode.values.length - 1)];

      final dismissedList = prefs.getStringList('nakhl_dismissed_helps') ?? [];
      _dismissedHelpIds.addAll(dismissedList);

      notifyListeners();
    } catch (_) {}
  }

  void setHelpMode(HelpMode newMode) async {
    _mode = newMode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('nakhl_help_mode', newMode.index);
    } catch (_) {}
  }

  void setRole(String role) {
    _currentRole = role;
    notifyListeners();
  }

  void setLanguage(String language) {
    _currentLanguage = language;
    notifyListeners();
  }

  void openDrawer(HelpContent content) {
    _activeContent = content;
    _isDrawerOpen = true;
    notifyListeners();

    // Track analytics event
    recordHelpEvent('opened', content.id);
  }

  void openDrawerForRoute(String route) {
    final content = HelpRegistry().getContentByRoute(route, role: _currentRole, language: _currentLanguage);
    if (content != null) {
      openDrawer(content);
    }
  }

  void closeDrawer() {
    _isDrawerOpen = false;
    notifyListeners();
  }

  void dismissHelp(String helpId) async {
    _dismissedHelpIds.add(helpId);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('nakhl_dismissed_helps', _dismissedHelpIds.toList());
    } catch (_) {}

    recordHelpEvent('dismissed', helpId);
  }

  bool isDismissed(String helpId) => _dismissedHelpIds.contains(helpId);

  void markWizardStepCompleted(int step) async {
    _completedWizardSteps['step_$step'] = step;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nakhl_wizard_progress', jsonEncode(_completedWizardSteps));
    } catch (_) {}

    recordHelpEvent('tutorial_started', 'onboarding_wizard', metadata: {'step': step});
  }

  /// Privacy-preserving help usage tracking
  void recordHelpEvent(String eventName, String helpId, {Map<String, dynamic>? metadata}) async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      await client.from('help_usage_events').insert({
        'tenant_id': client.auth.currentUser?.userMetadata?['tenant_id'] ?? '11111111-1111-1111-1111-111111111111',
        'user_id': userId,
        'event_name': eventName,
        'help_id': helpId,
        'metadata': metadata ?? {},
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Non-blocking
    }
  }
}
