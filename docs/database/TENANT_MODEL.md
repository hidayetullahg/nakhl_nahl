# NAKHL & NAHL — TENANT VE ORGANİZASYON MODELİ v2.0

## 1. Tenant İzolasyonu
Tenant, platformdaki en yüksek yalıtım sınırıdır.
- Her kiracı kendi bağımsız tekil UUID'sine ve koduna (`code`) sahiptir.
- Aynı veritabanı kümesinde yer alan kiracılar, PostgreSQL Row Level Security (RLS) sayesinde birbirlerinin hiçbir kaydını (Cari, Stok, Hasat, Fatura, Sevkiyat, Yevmiye) göremez ve değiştiremez.
- `tenant_id` parametresi istemciden gelmiş olsa dahi `auth.uid()` -> `public.users` -> `tenant_users` zinciriyle veritabanı çekirdeğinde doğrulanır.

---

## 2. Çoklu Şirket (Multi-Company) ve Grup İçi Ticaret (Intercompany)
Bir tenant altında birden fazla ülkede farklı para birimlerine ve vergi mevzuatlarına tabi tüzel şirketler yer alabilir:
- **Örnek Senaryo:**
  - `Company A: Nakhl Al-Madinah Ltd` (Suudi Arabistan - SAR - ZATCA E-Fatura Uyumlu)
  - `Company B: Nahl Gıda A.Ş.` (Türkiye - TRY - GİB E-Fatura/E-İrsaliye Uyumlu)
  - `Company C: Nakhl Europe GmbH` (Almanya - EUR - GoBD Uyumlu)

- **Intercompany Entegrasyonu:**
  - Şirketler arası mal transferleri ve satışlar OECD transfer fiyatlandırması (Cost-Plus, Resale-Minus vb.) ilkelerine göre yürütülür.
  - Tek bir işlemle Şirket A'da satış faturası ve stok çıkışı, Şirket B'de satın alma faturası ve stok girişi tetiklenir.
  - Muhasebede karşılıklı hesaplar (133 İlişkili Taraflardan Alacaklar / 333 İlişkili Taraflara Borçlar) ikiz kayıt olarak dengelenir.

---

## 3. Depo, Lojistik ve Tesis Hiyerarşisi
Depolar doğrudan tüzel bir şirkete ve operasyonel bir şubeye bağlıdır:
- **Depo Sınıfları:**
  - `RAW_MATERIAL`: Çiftlikten yeni gelen ham hurma
  - `FINISHED_GOODS`: İşlenmiş, paketlenmiş hurma
  - `COLD_STORAGE`: Soğuk hava deposu (+4°C)
  - `FREEZER`: Şoklama ve dondurucu (-18°C)
  - `PACKAGING`: Ambalaj ve paketleme malzemeleri
  - `QUARANTINE`: Kalite/Helal incelemesindeki karantina lotları
  - `BONDED`: Gümrüklü antrepo

- **Hiyerarşik Depo Lokasyonları:**
  `Depo (Warehouse) → Koridor (Aisle) → Raf (Rack) → Kat (Shelf) → Göz / Palet Yeri (Bin)`
