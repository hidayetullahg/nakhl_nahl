# NAKHL & NAHL — CORE DATABASE SPECIFICATION v2.0 (PRODUCTION READY)

## 1. Genel Mimari
NAKHL & NAHL küresel SaaS ERP platformunun çekirdek veri mimarisi; çok kiracılı (multi-tenant), çok şirket/şube ve çoklu para birimi destekli, PostgreSQL 15+ ve Row Level Security (RLS) tabanlıdır.

Sistemin hiyerarşik organizasyon yapısı:
```
PLATFORM (SaaS SuperAdmin)
  └── TENANTS (Bağımsız Kiracılar / Holding Grupları)
        ├── SaaS Subscriptions & Module Permissions (003-005)
        └── COMPANIES (Tüzel Kişilikler - KSA, TR, DE vb.) (007, 046)
              ├── BRANCHES (Şubeler) (008)
              ├── WAREHOUSES & LOCATIONS (Depo / Koridor / Raf / Göz) (011-012)
              ├── BUSINESS UNITS & DEPARTMENTS (Tesisler / Departmanlar) (009-010)
              └── BOUNDED CONTEXTS (22 Modüler Alan)
```

---

## 2. Bounded Context Tabloları ve Veritabanı Şeması (50 Migrasyon)

### A. Çekirdek ve Organizasyonel Altyapı (001–021)
- `saas_plans`, `tenants`, `tenant_subscriptions`, `tenant_modules`
- `public.users`, `companies`, `branches`, `business_units`, `departments`
- `warehouses`, `warehouse_locations`, `roles`, `permissions`, `role_permissions`
- `tenant_users`, `user_company_access`, `audit_logs`

### B. Dil, Yazı Sistemi ve Dinamik Menü (027–028, 031)
- `languages`, `scripts`, `system_translations`, `menu_items`, `user_menu_preferences`
- ISO 15924 script desteği (Arapça, Latin, Kiril vb.), RTL/LTR dinamik yönlendirme.

### C. Cariler ve Taraflar (Party / Cari Core - 022, 032)
- `parties`, `party_roles`, `party_contacts`, `party_bank_accounts`, `party_tax_profiles`, `cariler`
- Müşteri, tedarikçi, taşıyıcı, çiftlik operatörü, sertifikasyon kuruluşu tiplemeleri.

### D. Envanter, Parti/Lot ve Çift Taraflı Stok Defteri (024, 033)
- `items`, `item_categories`, `units_of_measure`, `item_lots`, `stock_ledger_entries`
- `view_current_stock`: Append-only defterden gerçek zamanlı bakiye hesaplayan görünüm.

### E. Çift Taraflı Muhasebe ve Finans (General Ledger - 023, 034)
- `chart_of_accounts`, `fiscal_years`, `fiscal_periods`, `journal_entries`, `journal_lines`
- `financial_transactions`: Kasa, banka, çek/senet işlemleri.

### F. Satış ve Satın Alma (Sales & Purchase - 029, 035)
- `sales_orders`, `sales_order_lines`, `purchase_orders`, `purchase_order_lines`
- `invoices`, `invoice_lines`, `create_sales_invoice_atomic()` RPC.

### G. Tarım, Çiftlik ve Hasat Yönetimi (Agriculture & Harvest - 036)
- `farms`, `fields`, `crops`, `harvests`, `agricultural_activities`
- GPS koordinatları, sulama/toprak tipi, ağaç sayısı, brix/nem oranı takibi.

### H. Kalite Yönetimi ve Helal Uygunluk (025, 037, 038)
- `quality_specifications`, `quality_parameters`, `quality_inspections`
- `halal_certification_bodies`, `halal_certificates`, `halal_lot_compliance`, `halal_audit_logs`
- GSO 2055-1, SMIIC 1, TSE Helal standartları ve ihracat vizesi kontrolü.

### I. Dış Ticaret, İhracat ve Soğuk Zincir Lojistiği (026, 039, 040)
- `export_files`, `export_file_items`, `export_containers`, `customs_declarations`, `export_documents`
- `vehicles`, `drivers`, `transport_orders`, `shipments`, `cold_chain_telemetry_logs`
- 40ft Reefer sıcaklık telemetrisi (-18°C ila +4°C), ZATCA ve GİB gümrük tescili.

### J. Belge Yönetimi ve Versiyonlama (041)
- `documents`, `document_versions`, `document_access_logs`, `document_expiry_alerts`

### K. Mevzuat ve Vergi Motoru (042)
- `legislations`, `jurisdictions`, `tax_rules`, `tax_exemptions`, `calculate_tax_atomic()` RPC

### L. Raporlama ve Analitik Katmanı (043)
- Materialized view ve indekslerle optimize edilmiş satış, satın alma, kârlılık, lot izlenebilirlik görünümleri.

### M. Yapay Zeka, OCR ve Human-in-the-Loop (044)
- `ai_ocr_extractions`, `ai_document_classifications`, `ai_commercial_suggestions`, `ai_audit_logs`
- İnsan onayı olmaksızın kritik ticari işlemlerin (`ACCOUNTING_POST`, `STOCK_POST`) yapılmasını engelleyen fonksiyonel kalkan.

### N. POS ve Çoklu Şirket Grup İçi Ticaret (Intercompany - 045, 046)
- `pos_terminals`, `pos_shifts`, `pos_sales`, `pos_sale_items`, `pos_payments`
- `intercompany_agreements`, `intercompany_transactions`, `intercompany_transaction_lines`
- OECD transfer fiyatlandırması (Cost-Plus vb.) ve ikiz yevmiye (133 / 333) entegrasyonu.

### O. Uçtan Uca İzlenebilirlik ve Geri Çağırma (Traceability & Recall - 047)
- `factory_processings`, `recall_incidents`, `recall_impacted_lots`, `recall_action_logs`
- Çiftlikten sofraya ileri ve geri izlenebilirlik zinciri.

### P. Güvenlik, Denetim ve Ölçeklenebilirlik Sertleştirme (048, 049, 050)
- Kriptografik SHA-256 denetim zinciri, 10 yıllık WORM saklama politikası.
- Şema genelinde `%100 FORCED ROW LEVEL SECURITY`, `SET search_path = public` ve girdi temizleme kalkanı.
