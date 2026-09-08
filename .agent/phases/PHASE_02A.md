# PHASE_02A — I18N DATABASE AND SCRIPTS

Amaç: Locale/script veri tabanını genişletmek ve Dart/DB locale paritesini kurmak.

Oku/tara: `lib/data/app_translations.dart`, `lib/core/i18n/`, locale/script migration'ları ve testleri.

Uygula: Mevcut migration'ları değiştirmeden yeni ileri-only migration ekle. Script yönü, sayı sistemi, tarih/ondalık ayırıcıları, locale metadata'sı, translation key/value şeması ve `is_machine_translated` alanını parametrik tut. Hukuki/yerel veri tahmin etme.

Test: locale-script geçerliliği, RTL yönü, app translations karşılığı ve Çin locale tutarsızlığı.

Kapı: `.agent/scripts/verify.sh`; migration self-audit; raporla ve kullanıcı onayı bekleyerek dur. UI hardcode temizliği bu fazın dışıdır.
