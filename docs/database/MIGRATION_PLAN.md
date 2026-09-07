# NAKHL & NAHL — VERİTABANI MİGRATİON PLANI v2.0

## 1. Migration Sıralaması (50 Dosya — Tam Hiyerarşi)
Tüm migration dosyaları `supabase/migrations/` dizininde sıralı ve bağımlılık hiyerarşisine uygun olarak yapılandırılmıştır:

1. `001_extensions.sql`: uuid-ossp, pgcrypto, citext eklentileri
2. `002_core_types.sql`: entity_status, subscription_status, warehouse_type_enum tipleri
3. `003_saas_plans.sql`: SaaS abonelik paketleri
4. `004_tenants.sql`: Tenants ve tenant_subscriptions
5. `005_tenant_modules.sql`: Tenant modül izinleri
6. `006_users.sql`: public.users
7. `007_companies.sql`: Tüzel şirketler
8. `008_branches.sql`: Şubeler
9. `009_business_units.sql`: Tesisler ve işletmeler
10. `010_departments.sql`: Departmanlar
11. `011_warehouses.sql`: Depolar
12. `012_warehouse_locations.sql`: Depo içi hiyerarşik lokasyonlar
13. `013_roles_and_permissions.sql`: Roller, izinler ve eşleştirmeler
14. `014_tenant_users.sql`: Tenant üyelik köprüsü
15. `015_user_company_access.sql`: Şirket bazlı erişim kısıtlaması
16. `016_audit_logs.sql`: Append-only denetim izi ve trigger
17. `017_security_helper_functions.sql`: RLS güvenlik fonksiyonları
18. `018_row_level_security.sql`: RLS politikaları
19. `019_indexes_and_constraints.sql`: Performans indeksleri
20. `020_seed_system_data.sql`: Sistem başlangıç verileri
21. `021_security_tests.sql`: RLS ve izolasyon doğrulama testleri
22. `022_cariler.sql`: Cariler ve hesap planı entegrasyonu
23. `023_double_entry_accounting.sql`: Çift taraflı muhasebe (General Ledger)
24. `024_inventory_ledger.sql`: Stok hareket defteri ve parti/lot takibi
25. `025_halal_compliance.sql`: Helal uygunluk ve kalite yönetimi
26. `026_export_and_logistics.sql`: Dış ticaret, ihracat ve lojistik
27. `027_script_language_system.sql`: Dil ve yazı sistemi (Script decoupling)
28. `028_dynamic_menu_system.sql`: Dinamik menü ve modüler navigasyon
29. `029_audit_fixes_and_sales_invoice_rpc.sql`: Audit düzeltmeleri & create_sales_invoice_atomic RPC
30. `031_master_data_and_globalization.sql`: Master data & küreselleşme
31. `032_party_cari_core.sql`: Party / Cari / Customer / Supplier çekirdeği
32. `033_product_inventory_foundation.sql`: Ürün & envanter altyapısı
33. `034_accounting_finance_core.sql`: Muhasebe & finans çekirdeği
34. `035_sales_purchase_bounded_context.sql`: Satış & satın alma modelleri
35. `036_agriculture_farm_harvest.sql`: Tarım, çiftlik ve hasat yönetimi
36. `037_quality_management_core.sql`: Kalite spesifikasyon ve muayeneleri
37. `038_halal_compliance_core.sql`: Helal sertifikasyon ve parti uygunluğu
38. `039_export_international_trade_core.sql`: İhracat dosyaları ve gümrükleme
39. `040_logistics_transport_cold_chain.sql`: Lojistik ve soğuk zincir telemetrisi
40. `041_document_management_core.sql`: Belge yönetimi ve versiyonlama
41. `042_legislation_tax_engine.sql`: Mevzuat ve dinamik vergi hesaplama
42. `043_reporting_analytics_layer.sql`: Raporlama ve analitik görünümleri
43. `044_ai_intelligence_core.sql`: AI, OCR ve Human-in-the-Loop kalkanı
44. `045_pos_operational_sales_core.sql`: POS operasyonel satış ve vardiya
45. `046_multi_company_intercompany_core.sql`: Çoklu şirket ve grup içi ticaret
46. `047_end_to_end_traceability_core.sql`: Uçtan uca izlenebilirlik ve geri çağırma
47. `048_audit_compliance_hardening_core.sql`: Kriptografik denetim ve WORM saklama
48. `049_performance_and_scale_hardening.sql`: İndeks, sorgu ve ölçekleme optimizasyonu
49. `050_production_security_hardening.sql`: Canlı ortam güvenlik sertleştirmesi ve FORCED RLS

---

## 2. İdempotent Çalıştırma ve Güvenlik
- Tüm migrasyon dosyaları `CREATE TABLE IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS` ve `ON CONFLICT DO NOTHING` kurallarıyla donatılmıştır.
- Tüm `SECURITY DEFINER` fonksiyonları `SET search_path = public` direktifine sahiptir.
- Şema genelinde %100 oranında `FORCE ROW LEVEL SECURITY` uygulanmıştır.
