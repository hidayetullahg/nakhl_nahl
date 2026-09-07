# NAKHL & NAHL — GLOBAL LOCATION MASTER DATA ARCHITECTURE
**Suudi Arabistan (KSA) ve Türkiye Öncelikli Dünya Ülke ve Şehir Veri Altyapısı**

---

## 1. Veri Kaynağı ve Lisans Bildirimi (Attribution)

NAKHL & NAHL küresel lokasyon altyapısı, dünya genelinde 241 ülke ve 50.250 şehri kapsayan **SimpleMaps World Cities Database (v1.91.4)** temel alınarak tasarlanmıştır.

### Lisans Şartı & Atıf (CC BY 4.0)
* **Kaynak:** [SimpleMaps World Cities Database](https://simplemaps.com/data/world-cities)
* **Lisans:** Creative Commons Attribution 4.0 International (CC BY 4.0)
* **Kullanım İzni:** Ticari ERP, SaaS ve çok kiracılı veritabanlarında serbestçe kullanılabilir, değiştirilebilir ve entegre edilebilir.
* **Yasal Gereklilik:** Bu veritabanı veya türevleri kullanıldığında SimpleMaps kaynağına atıfta bulunulması zorunludur. NAKHL & NAHL dokümantasyonunda ve uygulama hakkımızda/lisanslar alanında bu atıf eksiksiz korunmaktadır.

---

## 2. Mimari Prensipler

1. **Sıfır Flutter Şişkinliği (Zero Bundle Bloat):** 50.250 şehirlik 5.3 MB ham veri Flutter web/mobil paketine gömülmez; PostgreSQL/Supabase master tablolarında saklanır ve B-Tree indexli RPC arama fonksiyonları ile çekilir.
2. **0ms Hibrit Öncelik Önbelleği (Offline / Sandbox Resilience):** KSA (106 şehir) ve Türkiye (720 şehir / 81 il) `LocationService` katmanında bellek önbelleğinde tutulur. İnternet kesintisinde veya ilk açılışta 0ms tepki verir.
3. **Çok Dilli ve Çok Alfabeli Arama:** Ülke ve şehirler Türkçe, İngilizce, Arapça, ISO2, ISO3 ve aksansız ASCII formatlarında aranabilir (`normalizeSearchString`: `İ/ı`, `ç`, `ş`, `ğ`, `ö`, `ü`, Arapça hemze ve te marbuta dönüşümleri).
4. **Tenant İzolasyonu & RLS Güvenliği:** Master tablolar (`countries`, `cities`) herkese açık `SELECT` okuma iznine sahiptir. Kiracı kullanıcıları doğrudan `INSERT/UPDATE/DELETE` yapamaz (Salt Okunur Master Veri).

---

## 3. Veritabanı Şeması ve İndeksler

### `countries` Tablosu
```sql
CREATE TABLE IF NOT EXISTS countries (
    id TEXT PRIMARY KEY,
    iso2 VARCHAR(2) UNIQUE NOT NULL,
    iso3 VARCHAR(3) UNIQUE NOT NULL,
    country_name VARCHAR(150) NOT NULL,
    country_name_en VARCHAR(150),
    country_name_tr VARCHAR(150),
    country_name_ar VARCHAR(150),
    phone_code VARCHAR(20),
    currency_code VARCHAR(3) NOT NULL DEFAULT 'USD',
    currency_name VARCHAR(100),
    default_language VARCHAR(10) DEFAULT 'en',
    timezone VARCHAR(100) DEFAULT 'UTC',
    active BOOLEAN DEFAULT true,
    sort_order INT DEFAULT 100,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### `cities` Tablosu
```sql
CREATE TABLE IF NOT EXISTS cities (
    id TEXT PRIMARY KEY,
    country_id TEXT REFERENCES countries(id) ON DELETE CASCADE,
    country_code VARCHAR(2) NOT NULL,
    city_name VARCHAR(150) NOT NULL,
    city_name_ascii VARCHAR(150) NOT NULL,
    admin_name VARCHAR(150),
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    capital_type VARCHAR(50),
    population BIGINT DEFAULT 0,
    source_id TEXT,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_cities_country_code ON cities(country_code);
CREATE INDEX idx_cities_city_name ON cities(city_name);
CREATE INDEX idx_cities_city_name_ascii ON cities(city_name_ascii);
CREATE INDEX idx_cities_population ON cities(population DESC);
```

### RPC Arama Fonksiyonları
* `search_countries(p_query, p_lang)`: Çok dilli ülke araması.
* `search_cities(p_country_code, p_query, p_limit)`: Ülke filtreli hızlı şehir araması.

---

## 4. İçe Aktarım Özeti (worldcities.csv)

| Kategori | Adet | Durum |
| :--- | :--- | :--- |
| **Toplam Dünya Şehri** | 50.250 | İşlendi / Doğrulandı |
| **Toplam Ülke** | 241 | İşlendi / Doğrulandı |
| **Suudi Arabistan (SA) Şehirleri** | 106 | %100 Eksiksiz Aktarıldı |
| **Türkiye (TR) Şehirleri** | 720 | %100 Eksiksiz Aktarıldı |
| **Öncelikli Seed Göç Dosyası** | 976 Şehir | `supabase/migrations/058_seed_priority_ksa_turkey_cities.sql` |
| **Hatalı / Atlanan Satır** | 0 | Başarılı |

---

## 5. Ülke Bazlı Kurallar Motoru (Country Business Rules Engine)

| Ülke | Para Birimi | KDV / Vergi Oranı | Fatura Standardı | Adapter Türü | Vergi No Doğrulama |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Suudi Arabistan (SA)** | SAR (﷼) | %15 | ZATCA Phase 2 (Fatoora) | `zatca` | 15 hane (3 ile başlar, 3 ile biter) |
| **Türkiye (TR)** | TRY (₺) | %20, %10, %1 | GİB e-Fatura / e-Arşiv | `gib_efatura` | 10 hane VKN / 11 hane TCKN |
| **BAE (AE)** | AED (د.إ) | %5 | FTA UAE Standard | `fta_uae` | 15 hane TRN |
| **Almanya (DE)** | EUR (€) | %19, %7 | EU PEPPOL / XRechnung | `xrechnung_peppol` | DE + 9 hane |
| **ABD (US)** | USD ($) | Eyalet Bazlı | Generic Invoice | `generic_invoice` | EIN / SSN |
