# NAKHL & NAHL — VERİ AKTARIM REHBERİ (DATA IMPORT GUIDE)

## 1. Genel Bakış
NAKHL & NAHL, kullanıcıların eski muhasebe veya ERP programlarından (Logo, Mikro, Paraşüt, Excel, CSV, SAP vb.) sorunsuz ve güvenli bir şekilde geçiş yapmasını sağlayan **Staging Buffer** mimarisine sahiptir.

---

## 2. 12 Adımlı İçe Aktarım Akışı (Import Wizard)
1. **Kaynak Seçimi:** Logo, Mikro, Paraşüt, Excel (.xlsx), CSV veya Özel API.
2. **Dosya Yükleme:** Dosya sürükle-bırak veya dosya seçici.
3. **Yapısal Analiz:** Dosyanın satır ve kolon yapısının taranması.
4. **Akıllı Kolon Eşleştirme:** `Müşteri Adı → customer_name`, `Vergi No → tax_number`, `Telefon → phone`, `Bakiye → opening_balance`.
5. **Eksik Alan Denetimi:** Zorunlu alanların varlık kontrolü.
6. **Mükerrer (Duplicate) Kontrolü:** Aynı vergi numarası veya e-posta ile mükerrer kayıt engelleme.
7. **Vergi Format Doğrulaması:** KSA için 15 hane (`3...3`), TR için 10 haneli VKN / 11 haneli TCKN.
8. **Para Birimi Doğrulaması:** SAR, TRY, USD, EUR tutarlılığı.
9. **Önizleme & Trafik Işığı:**
   - 🟢 Yeşil: Hatasız kayıtlar.
   - 🟡 Sarı: Otomatik düzeltilebilir (örn. telefon formatı).
   - 🔴 Kırmızı: Kritik hata (işlenemez).
10. **Kullanıcı Onayı:** Kullanıcının import öncesi son onayı.
11. **Atomik İçe Aktarım:** `data_migration_jobs` üzerinde tek bir transaction içinde çalıştırma.
12. **Özet Rapor:** Başarılı, atlanan ve hatalı kayıtların dökümü.

---

## 3. Geri Alma (Rollback) Güvencesi
Her import işlemi bir `batch_id` ile etiketlenir. Kullanıcı dilediğinde:
```sql
SELECT rollback_migration_batch('BATCH-20260907-001');
```
komutuyla veya UI üzerindeki "Bu Aktarımı Geri Al" butonu ile sisteme zarar vermeden içe aktarılan verileri geri alabilir.
