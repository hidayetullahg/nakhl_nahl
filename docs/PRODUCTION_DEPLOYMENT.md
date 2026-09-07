# NAKHL & NAHL — CANLIYA ALMA REHBERİ (PRODUCTION DEPLOYMENT RUNBOOK)

## 1. Dağıtım Mimarisi
* **Öncelikli Platform:** Web Uygulaması (Flutter Web CanvasKit / PWA).
* **Tarayıcı Desteği:** Apple Safari (iOS & macOS), Google Chrome (Android & Desktop), Microsoft Edge.
* **Veritabanı & Backend:** Supabase (PostgreSQL 15+) with Row Level Security (RLS).
* **Alan Adı (Domain):** `beeofdate.com` (Marka yapılandırması `AppBrandConfig` ile soyutlanmıştır).

---

## 2. Dağıtım Adımları (Deployment Checklist)

1. **Canlı Veritabanı Göçleri:**
   ```bash
   # 001'den 058'e kadar tüm göçler sırayla uygulanır
   psql -h $DB_HOST -U $DB_USER -d $DB_NAME -f supabase/migrations/057_global_country_and_city_master.sql
   psql -h $DB_HOST -U $DB_USER -d $DB_NAME -f supabase/migrations/058_seed_priority_ksa_turkey_cities.sql
   ```

2. **Güvenlik ve RLS Testi:**
   ```bash
   psql -h $DB_HOST -U $DB_USER -d $DB_NAME -f supabase/security_tests/053_integration_and_help_security_tests.sql
   psql -h $DB_HOST -U $DB_USER -d $DB_NAME -f supabase/security_tests/054_commercial_and_migration_security_tests.sql
   ```

3. **Flutter Web Release Derlemesi:**
   ```bash
   flutter build web --release --dart-define=APP_DOMAIN=beeofdate.com
   ```

4. **Web Paketinin Dağıtımı:**
   - `build/web/` içeriği CDN veya statik barındırma sunucusuna yüklenir.
   - HTTPS / SSL sertifikası aktifleştirilir.

5. **Bahtiyar Tenant ve Kullanıcı Kurulumu:**
   - Şirket Adı: Bahtiyar KSA Trading
   - Ülke: Suudi Arabistan (`SA`)
   - Şehir: Riyadh
   - Para Birimi: SAR
   - ZATCA Phase 2 Fatoora modülü aktif edilir.
