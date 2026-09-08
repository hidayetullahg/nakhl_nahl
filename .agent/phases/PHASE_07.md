# PHASE_07 — PRIVACY AND CONSENT

Amaç: KVKK/GDPR/PDPL için kişi kaydından önce dayanak, bilgilendirme, isteğe bağlı ek rıza ve veri sahibi talepleri.

Oku/tara: mevcut privacy migration/repository/model/cari/personel/CRM akışları. Hukuki metinlerin başına taslak ve hukuk onayı bekliyor işareti koy; hukuki tavsiye üretme.

Uygula: ConsentService, privacy center, retention/audit, marketing fields lock. Dayanak veya bilgilendirme yoksa kayıt veritabanı ve UI katmanında engellenir.

Test: enforcement, optional CRM field lock, withdrawal lock, audit record.

Kapı: `.agent/scripts/verify.sh`; yeni migration ileri-only; raporla ve dur.
