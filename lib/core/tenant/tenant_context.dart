/// NAKHL & NAHL — Aktif Kiracı ve Şirket Durumu (Tenant Context)
class TenantContext {
  TenantContext._();
  static final TenantContext instance = TenantContext._();

  String? _activeTenantId;
  String? _activeTenantCode;
  String? _activeCompanyName;
  String? _activeCompanyId;
  String? _userId;
  String? _userEmail;

  String? get activeTenantId => _activeTenantId;
  String? get activeTenantCode => _activeTenantCode;
  String? get activeCompanyName => _activeCompanyName;
  String? get activeCompanyId => _activeCompanyId;
  String? get userId => _userId;
  String? get userEmail => _userEmail;

  bool get hasTenant => _activeTenantId != null;

  void setActiveTenant({
    required String tenantId,
    required String tenantCode,
    String? companyId,
    String? companyName,
  }) {
    _activeTenantId = tenantId;
    _activeTenantCode = tenantCode;
    _activeCompanyId = companyId;
    _activeCompanyName = companyName;
  }

  void setActiveCompany(String companyId, [String? companyName]) {
    _activeCompanyId = companyId;
    if (companyName != null) _activeCompanyName = companyName;
  }

  void setSession({required String userId, required String userEmail}) {
    _userId = userId;
    _userEmail = userEmail;
  }

  void clearSession() {
    _userId = null;
    _userEmail = null;
    clear();
  }

  void clear() {
    _activeTenantId = null;
    _activeTenantCode = null;
    _activeCompanyId = null;
    _activeCompanyName = null;
  }
}
