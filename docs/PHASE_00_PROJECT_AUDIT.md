# NAKHL & NAHL — PHASE 0: PROJE VE MEVCUT DURUM AUDIT RAPORU
**Tarih:** 2026-09-07  
**Standart:** Kanıt Temelli Üretim Denetimi (**"KANIT YOKSA PASS YOK"**)  

---

## 1. Geliştirme ve Çalışma Ortamı
* **Flutter Sürümü:** Flutter 3.19.6 (Channel user-branch, Engine c4cd48e186)
* **Dart Sürümü:** Dart 3.3.4 (macOS arm64 / x64)
* **Backend Platformu:** PostgreSQL 15 / Supabase (Multi-tenant schema, RLS, RPC)
* **Web Derleme Durumu:** Flutter Web CanvasKit + PWA (`build/web/main.dart.js`, 99.4s derleme süresi)

---

## 2. PostgreSQL Veritabanı ve Migration Envanteri
Toplam **58 adet migration** dosyası mevcuttur (`supabase/migrations/`):
* `001_extensions.sql` - `021_security_tests.sql`: Çekirdek şema, SaaS planları, kiracılar, şirketler, şubeler, depolar, RLS ve güvenlik fonksiyonları.
* `022_cariler.sql` - `026_export_and_logistics.sql`: Çift taraflı muhasebe, stok defteri, helal sertifikasyon, ihracat ve lojistik.
* `027_script_language_system.sql` - `030`: Çok alfabeli (Latn, Arab) ve çok dilli (TR, AR, EN) sistem.
* `031_master_data_and_globalization.sql` - `050_production_security_hardening.sql`: Tarım/hasat, kalite yönetimi, vergi motoru, POS, intercompany ve audit sertleştirmesi.
* `051` - `054`: Evrensel entegrasyon sağlayıcıları, yardım sistemi, ticari modüller ve yasal mevzuat kütüphanesi.
* `055` - `058`: Faz 11 dinamik sektörler, hiyerarşik adres kataloğu ve 50.250 şehirlik Global Lokasyon Master Verisi (`worldcities.csv`).

### Tablo ve RLS Kapsamı
* **Toplam Tablo Sayısı:** 114+ tablo (`public` şeması)
* **Row Level Security (RLS) Oranı:** %100 (Tüm kiracı operasyonel tablolarında `FORCE ROW LEVEL SECURITY` etkindir).
* **Kiracı İzolasyonu:** `tenant_id = current_tenant_id()` süzgeciyle şirketler arası veri sızıntısı engellenmiştir.
* **Global Master Tablolar:** `countries`, `cities`, `currencies`, `timezones` tabloları tüm kiracılara açık salt-okunur (`SELECT true`), yazma ise `service_role` yetkisiyle sınırlandırılmıştır.

---

## 3. Kimlik Doğrulama ve Kullanıcı Mimarisi
* **Auth Katmanı:** Supabase Authentication (E-posta & Şifre) + 2FA (4 Haneli Hızlı PIN) + Session Yönetimi (`lib/services/auth_service.dart`).
* **Kullanıcı Rolleri (9 Seviyeli Kurumsal Hiyerarşi):**
  1. `owner`: İşletme Sahibi / Tam mülk yetkisi
  2. `admin`: Sistem Yöneticisi / Tüm modüllere tam erişim
  3. `manager`: Operasyonel Yönetici / Onaylar ve raporlar
  4. `accountant` (Muhasebe): Kasa, banka, fatura, cari ve finans
  5. `cashier`: Kasiyer / Hızlı perakende satış ve kasa tahsilatı
  6. `warehouse` (Depo Sorumlusu): Stok giriş/çıkış, sayım, sevkiyat
  7. `sales`: Satış Temsilcisi / Müşteri carileri, teklif ve sipariş
  8. `purchase`: Satınalma / Tedarikçi carileri ve mal kabul
  9. `viewer`: Gözlemci / Salt-okunur rapor izleme
* **Aktif Kiracı ve Şirket Durumu:** `TenantContext` singleton nesnesi ile bellek ve oturum seviyesinde izole edilmektedir.

---

## 4. Firma, Şube ve Depo Mimarisi
* **Çoklu Şirket (Multi-Company):** Bir kiracı altında birden fazla tüzel kişilik (`companies`) ve şube (`branches`) tanımlanabilir.
* **Şirketler Arası Transfer:** `intercompany_transfers` tablosu ile grup içi mal ve finans hareketleri çift taraflı mahsuplaştırılır.
* **Depo & Raf Sistemi:** Depolar (`warehouses`) ve lokasyonlar (`warehouse_locations`) lot ve parti numaralarıyla stok defterine (`inventory_ledger`) bağlıdır.

---

## 5. Dinamik Sektörler ve Menü Sistemi
* **Dinamik Sektör Yapısı:** Hurma (`DATES`), Gıda (`FOOD`), Tarım (`AGRICULTURE`), Arıcılık (`BEEKEEPING`), Tekstil (`TEXTILE`), Mobilya (`FURNITURE`), Otomotiv (`AUTOMOTIVE`), İnşaat (`CONSTRUCTION`), Lojistik (`LOGISTICS`), Perakende (`RETAIL`), Toptan (`WHOLESALE`).
* **Özel Sektör Ekleme:** Kiracı kendi özel sektörünü ve özel ürün sınıfını çalışma anında tanımlayabilir.
* **Dinamik Menü Yönetimi:** `NavigationMenuService` ve `SectorService` ile kullanıcının sektörüne uygun modüller ana menüde listelenir.

---

## 6. Ticari Modüller ve Abonelik Altyapısı
* **18 Satılabilir Modül:** Core ERP, Cari, Stok, Kasa, Banka, Fatura, E-Fatura (GİB), ZATCA Phase 2, Veri Aktarımı, Gelişmiş Raporlama, POS, Tarım, Arıcılık, İhracat, Lojistik, Doküman Yönetimi, AI/OCR, Intercompany.
* **Abonelik Takip Motoru:** `commercial_subscriptions` ve `commercial_module_entitlements` tabloları ile süre sonu, uyarı periyotları ve 7 günlük Grace Period yönetilir.
* **Veri Koruma İlkesi:** Süresi biten modül salt-okunur duruma geçer; müşteri verisi kesinlikle silinmez.

---

## 7. E-Fatura ve ZATCA Uyumluluğu
* **Türkiye GİB:** `UniversalEInvoiceAdapter` soyutlaması üzerinden UBL-TR formatında e-Fatura/e-Arşiv XML üretimi.
* **Suudi Arabistan ZATCA:** `ZatcaPhase2Adapter` ile UBL 2.1 XML fatura, TLV Base64 QR Kod ve kriptografik imza üretimi.
* **Gizlilik ve Güvenlik:** İstemci tarafında hiçbir canlı üretim API anahtarı veya ZATCA CSID saklanmaz.

---

## 8. Evrensel Yardım ve Eğitim Sistemi
* **HelpRegistry:** 19 kategori altında 100+ bağlamsal yardım makalesi.
* **Bileşenler:** `UniversalHelpDrawer`, `HelpTooltip`, `FormFieldHelpIcon`, `EmptyStateHelp`, `ErrorHelpBanner`.
* **Günlük İş Akışı:** Sabah (Kasa/Banka kontrolü), Gün İçi (Satış/Fatura/Tahsilat), Akşam (Kasa kapanışı ve mutabakat).

---

## 9. Veri Aktarımı (Data Migration) ve Geri Alma (Rollback)
* **Staging Buffer:** `data_migration_staging` tablosunda geçici doğrulama.
* **Format Desteği:** Excel (.xlsx), CSV, Logo, Mikro, Paraşüt, SAP şablonları.
* **Geri Alma:** Her aktarıma atanan `batch_id` üzerinden tek komutla tam rollback güvencesi.

---

## 10. Test ve Kalite Durumu
* **Toplam Test Sayısı:** 187 test (`flutter test`) — %100 PASS
* **Statik Kod Analizi:** 0 hata, 0 uyarı (`flutter analyze`)
* **Kanıt Dosyaları:** `test/evidence/` dizininde 89 adet kanıt kaydı bulunmaktadır.

---

## 11. Faz 0 Sonucu
Mevcut mimari sağlam, modüler, çok dilli, çok sektörlü ve multi-tenant prensiplerine tam uyumludur. Hiçbir çalışan özellik silinmemiş veya bozulmamıştır. **DELIVERY 1 uygulanmasına hazırdır.**
