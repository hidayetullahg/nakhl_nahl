# PHASE_01 — MONEY PRECISION

Amaç: Finansal hesaplamalarda kayan nokta kullanımını kaldırmak.

Oku/tara: `pubspec.yaml`, `lib/core/money/`, `lib/repositories/accounting_repository.dart`, `lib/services/raporlama_servisi.dart`, tüm Money/Accounting çağıranları ve ilgili testler.

Uygula: `decimal` uyumlu Money/Decimal akışı, currency mismatch koruması, tarih/kaynak taşıyan kur modeli, exact DB serialization. Parasal olmayan miktar/tonaj double'larına dokunma.

Test: `test/money_precision_test.dart`; 0.1+0.2, 10.000 tekrar, farklı currency exception, JPY/KWD rounding, 1.000 journal balance, historical rate metadata.

Kapı: `flutter analyze`, `flutter test`, `.agent/scripts/verify.sh`. Tam proje baseline başarısızsa STATUS=BLOCKED yaz; test assertion gevşetme. Raporla ve dur.
