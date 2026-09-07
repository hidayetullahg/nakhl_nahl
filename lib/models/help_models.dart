// NAKHL & NAHL — Universal Help System Domain Models
// Complies with Master Directive Sections 12-25, 31, 32

enum HelpMode {
  off,
  basic,
  detailed;

  String get displayName {
    switch (this) {
      case HelpMode.off:
        return 'Yardım Kapalı';
      case HelpMode.basic:
        return 'Basit Yardım (Hızlı İpuçları)';
      case HelpMode.detailed:
        return 'Detaylı Yardım (Adım Adım & Kılavuzlar)';
    }
  }
}

class HelpStep {
  final int step;
  final String title;
  final String desc;
  final String? highlightWidgetId;

  const HelpStep({
    required this.step,
    required this.title,
    required this.desc,
    this.highlightWidgetId,
  });

  factory HelpStep.fromJson(Map<String, dynamic> json) {
    return HelpStep(
      step: (json['step'] as num?)?.toInt() ?? 1,
      title: json['title'] ?? '',
      desc: json['desc'] ?? '',
      highlightWidgetId: json['highlight_widget_id'],
    );
  }

  Map<String, dynamic> toJson() => {
    'step': step,
    'title': title,
    'desc': desc,
    if (highlightWidgetId != null) 'highlight_widget_id': highlightWidgetId,
  };
}

class HelpContent {
  final String id;
  final String? tenantId;
  final String route;
  final String menuKey;
  final String title;
  final String shortDescription;
  final String longDescription;
  final List<HelpStep> steps;
  final List<String> warnings;
  final List<String> tips;
  final List<String> relatedRoutes;
  final String? videoUrl;
  final String? documentationUrl;
  final String searchableText;
  final String language; // tr, en, ar
  final String role; // all, admin, accountant, warehouse, sales, pos
  final String version;
  final bool active;
  final int sortOrder;

  const HelpContent({
    required this.id,
    this.tenantId,
    required this.route,
    required this.menuKey,
    required this.title,
    required this.shortDescription,
    required this.longDescription,
    this.steps = const [],
    this.warnings = const [],
    this.tips = const [],
    this.relatedRoutes = const [],
    this.videoUrl,
    this.documentationUrl,
    required this.searchableText,
    this.language = 'tr',
    this.role = 'all',
    this.version = '1.0',
    this.active = true,
    this.sortOrder = 0,
  });

  factory HelpContent.fromJson(Map<String, dynamic> json) {
    List<HelpStep> stepsList = [];
    if (json['steps'] is List) {
      stepsList = (json['steps'] as List)
          .map((e) => HelpStep.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    List<String> warningsList = [];
    if (json['warnings'] is List) {
      warningsList = (json['warnings'] as List).map((e) => e.toString()).toList();
    }

    List<String> tipsList = [];
    if (json['tips'] is List) {
      tipsList = (json['tips'] as List).map((e) => e.toString()).toList();
    }

    List<String> relatedRoutesList = [];
    if (json['related_routes'] is List) {
      relatedRoutesList = (json['related_routes'] as List).map((e) => e.toString()).toList();
    }

    return HelpContent(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenant_id']?.toString(),
      route: json['route'] ?? '',
      menuKey: json['menu_key'] ?? '',
      title: json['title'] ?? '',
      shortDescription: json['short_description'] ?? '',
      longDescription: json['long_description'] ?? '',
      steps: stepsList,
      warnings: warningsList,
      tips: tipsList,
      relatedRoutes: relatedRoutesList,
      videoUrl: json['video_url'],
      documentationUrl: json['documentation_url'],
      searchableText: json['searchable_text'] ?? '',
      language: json['language'] ?? 'tr',
      role: json['role'] ?? 'all',
      version: json['version'] ?? '1.0',
      active: json['active'] ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenant_id': tenantId,
    'route': route,
    'menu_key': menuKey,
    'title': title,
    'short_description': shortDescription,
    'long_description': longDescription,
    'steps': steps.map((s) => s.toJson()).toList(),
    'warnings': warnings,
    'tips': tips,
    'related_routes': relatedRoutes,
    'video_url': videoUrl,
    'documentation_url': documentationUrl,
    'searchable_text': searchableText,
    'language': language,
    'role': role,
    'version': version,
    'active': active,
    'sort_order': sortOrder,
  };
}

class UserHelpProgress {
  final String id;
  final String userId;
  final String tenantId;
  final String helpId;
  final bool completed;
  final bool dismissed;
  final DateTime lastSeenAt;
  final Map<String, dynamic> progress;

  const UserHelpProgress({
    required this.id,
    required this.userId,
    required this.tenantId,
    required this.helpId,
    this.completed = false,
    this.dismissed = false,
    required this.lastSeenAt,
    this.progress = const {},
  });

  factory UserHelpProgress.fromJson(Map<String, dynamic> json) {
    return UserHelpProgress(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      tenantId: json['tenant_id']?.toString() ?? '',
      helpId: json['help_id'] ?? '',
      completed: json['completed'] ?? false,
      dismissed: json['dismissed'] ?? false,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'].toString())
          : DateTime.now(),
      progress: json['progress'] is Map ? json['progress'] : {},
    );
  }
}

class TaskGuide {
  final String id;
  final String title;
  final String description;
  final String category;
  final String role;
  final List<HelpStep> steps;
  final String targetRoute;

  const TaskGuide({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.role = 'all',
    required this.steps,
    required this.targetRoute,
  });
}
