/// NAKHL & NAHL — PARAMETRE KAPSAM (SCOPE) HİYERARŞİSİ
/// Öncelik Sırası: USER -> WAREHOUSE -> BUSINESS_UNIT -> BRANCH -> COMPANY -> TENANT -> COUNTRY -> GLOBAL

enum ParameterScope {
  user(80, 'USER', 'Kullanıcı Bazlı'),
  warehouse(70, 'WAREHOUSE', 'Depo Bazlı'),
  businessUnit(60, 'BUSINESS_UNIT', 'İş Birimi Bazlı'),
  branch(50, 'BRANCH', 'Şube Bazlı'),
  company(40, 'COMPANY', 'Şirket / Tüzel Kişilik Bazlı'),
  tenant(30, 'TENANT', 'Tenant / Kiracı Bazlı'),
  country(20, 'COUNTRY', 'Ülke / Hukuki Bölge Bazlı'),
  global(10, 'GLOBAL', 'Küresel / Sistem Geneli');

  final int priority;
  final String code;
  final String label;

  const ParameterScope(this.priority, this.code, this.label);

  /// Öncelik kıyaslaması: daha düşük priority değeri daha dar ve öncelikli kapsamdır.
  bool hasPrecedenceOver(ParameterScope other) => priority < other.priority;
}
