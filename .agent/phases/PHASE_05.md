# PHASE_05 — LEGISLATION AND TAX

Amaç: Versiyonlu ve tarih-duyarlı mevzuat/vergi kütüphanesi altyapısı.

Oku/tara: mevcut legislation migration/service/screen/test yüzeyi.

Uygula: Yeni ileri-only migration ile tax rules, legal documents, HS codes, PESTEL/SWOT şeması. Vergi oranı, gümrük veya hukuki özet uydurma. Belge özeti yalnızca insan doğrulamasıyla geçerli olsun. `getTaxRate(country, subdivision, taxType, transactionDate)` tarih olmadan hata versin.

Test: geçerli tarih aralığı, sınır tarihi, tarihsiz çağrı, expert review uyarısı.

Kapı: `.agent/scripts/verify.sh`; raporla ve dur.
