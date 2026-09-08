# PHASE_11 — FINAL QUALITY GATE

Amaç: Yeni özellik eklemeden temiz kurulum, DB migration ve regresyon teslim raporu.

Çalıştır: `flutter clean`, `flutter pub get`, `flutter analyze`, `flutter test`, `dart format --output=none --set-exit-if-changed lib/`, `flutter build web --release`. Supabase migration/security testleri yalnızca erişilebilir test DB ile çalıştırılır; çalıştırılamıyorsa açıkça BLOCKED yazılır.

Manuel kontrol: i18n/RTL, adres izolasyonu, eşit kartlar, kontrast, Money, SKU/UOM, consent, dashboard, AI secret.

Demo tenant ve gerçek dışı güvenli fixture ile uçtan uca senaryo çalıştır; gerçek hukuki/vergi verisi uydurma.

Final rapor: faz durumu, bulgu 1-10, test sayıları, kalite kapısı, bilinen riskler, canlıya hazır olup olmadığı. Raporla ve dur.
