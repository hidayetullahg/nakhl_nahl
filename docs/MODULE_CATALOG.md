# NAKHL & NAHL — 18 Commercial Modules Catalog & Specification

## 1. Overview

NAKHL & NAHL provides 18 distinct modular capabilities packaged into standalone subscription products. Each module can be enabled independently or as part of bundle tiers.

---

### Modül 1: `MOD_CORE` — Temel ERP & Multi-Tenant Altyapı
- **Kategori**: `CORE`
- **Fiyat**: Ücretsiz / Dahili (0.00 SAR / TRY)
- **Açıklama**: Multi-tenant mimari, tenant isolation (RLS), çoklu şirket yönetimi, kullanıcı rolleri (RBAC) ve sistem denetim altyapısı.
- **Özellikler**:
  - Çoklu kiracı (Tenant Context) yönetimi
  - Şirket / Şube açma ve değiştirme
  - Rol bazlı yetkilendirme (Admin, Muhasebe, Depo)
  - Oturum ve 2FA güvenliği

---

### Modül 2: `MOD_ACCOUNTING` — Genel Muhasebe & Finans
- **Kategori**: `FINANCE`
- **Fiyat**: 150 SAR/ay (1,500 SAR/yıl) | 1,250 TRY/ay (12,500 TRY/yıl)
- **Açıklama**: Tek düzen hesap planı, yevmiye defteri, mizan, gelir tablosu ve bilanço.
- **Özellikler**:
  - Çift taraflı kayıt sistemi (Double-entry bookkeeping)
  - Otomatik yevmiye fişi üretimi
  - Kasa ve banka hesap hareketleri
  - Finansal raporlama ve mizan

---

### Modül 3: `MOD_INVENTORY` — Stok & Depo Yönetimi
- **Kategori**: `OPERATIONS`
- **Fiyat**: 120 SAR/ay (1,200 SAR/yıl) | 1,000 TRY/ay (10,000 TRY/yıl)
- **Açıklama**: Çoklu depo, parti/lot takibi, stok hareket defteri ve sayım mutabakatı.
- **Özellikler**:
  - FIFO ve Ağırlıklı Ortalama maliyet hesaplama
  - Minimum/maksimum stok seviye uyarıları
  - Depolar arası transfer irsaliyesi
  - Barkodlu ürün kartları

---

### Modül 4: `MOD_SALES` — Satış & Müşteri İlişkileri
- **Kategori**: `OPERATIONS`
- **Gereksinim**: `MOD_INVENTORY`
- **Fiyat**: 100 SAR/ay (1,000 SAR/yıl) | 850 TRY/ay (8,500 TRY/yıl)
- **Açıklama**: Satış teklifi, sipariş, sevk irsaliyesi ve müşteri cari borç/alacak takibi.
- **Özellikler**:
  - Müşteri bazlı özel iskonto ve fiyat listeleri
  - Satış siparişi onay iş akışı
  - Vade ve tahsilat takibi
  - Satış ekibi performans analitiği

---

### Modül 5: `MOD_PURCHASE` — Satın Alma & Tedarikçi
- **Kategori**: `OPERATIONS`
- **Gereksinim**: `MOD_INVENTORY`
- **Fiyat**: 100 SAR/ay (1,000 SAR/yıl) | 850 TRY/ay (8,500 TRY/yıl)
- **Açıklama**: Tedarikçi siparişleri, mal kabul işlemleri, alış faturaları ve tedarikçi borç yönetimi.
- **Özellikler**:
  - Satın alma talepleri ve onay mekanizması
  - Mal kabul ve irsaliye eşleme
  - Tedarikçi mutabakatları
  - Ödeme planlama takvimi

---

### Modül 6: `MOD_POS` — Hızlı Satış POS & Perakende
- **Kategori**: `RETAIL`
- **Fiyat**: 80 SAR/ay (800 SAR/yıl) | 700 TRY/ay (7,000 TRY/yıl)
- **Açıklama**: Barkod okuyucu uyumlu hızlı kasa satışı, nakit/kredi kartı tahsilat ve gün sonu Z raporu.
- **Özellikler**:
  - Dokunmatik ekran ve barkod okuyucu optimizasyonu
  - Hızlı fiş / fatura kesimi
  - Kasa açılış / kapanış ve nakit devir
  - Çevrimdışı (offline) satış yeteneği

---

### Modül 7: `MOD_EINVOICE_TR` — Türkiye E-Fatura & GİB Entegrasyonu
- **Kategori**: `COMPLIANCE` (Addon)
- **Gereksinim**: `MOD_ACCOUNTING`
- **Fiyat**: 100 SAR/ay (1,000 SAR/yıl) | 750 TRY/ay (7,500 TRY/yıl)
- **Açıklama**: GİB onaylı özel entegratör üzerinden e-Fatura, e-Arşiv, e-İrsaliye gönderimi ve gelen fatura alma.
- **Özellikler**:
  - UBL-TR 1.2 XML formatlama ve şema doğrulama
  - GİB posta kutusu otomatik sorgulama
  - Mali mühür ve zaman damgası takibi
  - PDF fatura görselleştirme ve arşivleme

---

### Modül 8: `MOD_ZATCA_SA` — Suudi Arabistan ZATCA Fatoora Faz-2
- **Kategori**: `COMPLIANCE` (Addon)
- **Gereksinim**: `MOD_ACCOUNTING`
- **Fiyat**: 150 SAR/ay (1,500 SAR/yıl) | 1,250 TRY/ay (12,500 TRY/yıl)
- **Açıklama**: ZATCA Faz-2 e-Fatura entegrasyonu, kriptografik damga (ECDSA secp256k1), TLV Base64 QR kod ve Clearance/Reporting API.
- **Özellikler**:
  - CSID sertifika kayıt ve yenileme
  - UBL 2.1 XML üretimi ve hash zincirleme
  - ZATCA API sandbox / production bağlantısı
  - B2B Clearance ve B2C Reporting işlemleri

---

### Modül 9: `MOD_DATA_MIGRATION` — Veri Aktarımı & Geçiş Sihirbazı
- **Kategori**: `MIGRATION` (Stand-alone Addon)
- **Fiyat**: 500 SAR (Tek Seferlik) | 4,000 TRY (Tek Seferlik)
- **Açıklama**: Excel, CSV, JSON, Logo Tiger, Mikro, Netsis, Paraşüt, SAP ve Odoo verilerini tampon belleğe (staging) alarak doğrulayan ve canlıya aktaran sihirbaz.
- **Özellikler**:
  - Staging tampon mimarisi (canlı tabloya doğrudan yazmaz)
  - Otomatik akıllı kolon eşleme sözlüğü
  - Trafik ışığı doğrulama (Yeşil, Sarı, Kırmızı)
  - Atomik canlıya aktarım ve Rollback (Geri Alma) desteği

---

### Modül 10: `MOD_INITIAL_SETUP` — İlk Kurulum & Danışmanlık
- **Kategori**: `SERVICE` (Hizmet)
- **Fiyat**: 1,000 SAR | 8,000 TRY
- **Açıklama**: ERP uzmanı eşliğinde işletmeye özel hesap planı, şube, depo ve açılış bilançosu kurulumu.

---

### Modül 11: `MOD_TRAINING` — Kullanıcı & Personel Eğitimi
- **Kategori**: `SERVICE` (Hizmet)
- **Fiyat**: 800 SAR | 6,500 TRY
- **Açıklama**: İşletme personeline 8 saatlik canlı online eğitim, video kaynaklar ve kullanıcı sertifikasyonu.

---

### Modül 12: `MOD_REPORTING_ADV` — Gelişmiş Raporlama & BI Analitik
- **Kategori**: `ANALYTICS`
- **Fiyat**: 100 SAR/ay (1,000 SAR/yıl) | 850 TRY/ay (8,500 TRY/yıl)
- **Açıklama**: Dinamik pivot tablolar, grafikler, kârlılık analizleri ve nakit akış projeksiyonları.

---

### Modül 13: `MOD_AI_OCR` — Yapay Zekâ & Akıllı Belge OCR
- **Kategori**: `AI` (Addon)
- **Fiyat**: 150 SAR/ay (1,500 SAR/yıl) | 1,250 TRY/ay (12,500 TRY/yıl)
- **Açıklama**: Alış faturaları ve fişleri fotoğraftan okuyarak otomatik yevmiye kaydı oluşturan makine öğrenimi modülü.

---

### Modül 14: `MOD_LOGISTICS_EXPORT` — Uluslararası Ticaret & İhracat Lojistiği
- **Kategori**: `GLOBAL`
- **Gereksinim**: `MOD_INVENTORY`
- **Fiyat**: 120 SAR/ay (1,200 SAR/yıl) | 1,000 TRY/ay (10,000 TRY/yıl)
- **Açıklama**: Gümrük beyannameleri, konteyner takibi, çeki listesi (packing list) ve konşimento yönetimi.

---

### Modül 15: `MOD_AGRICULTURE` — Tarım & Hurma Bahçesi Yönetimi
- **Kategori**: `SPECIAL` (Sektörel)
- **Fiyat**: 100 SAR/ay (1,000 SAR/yıl) | 800 TRY/ay (8,000 TRY/yıl)
- **Açıklama**: Ağaç başına rekolte, hasat operasyonları, zirai ilaçlama/gübreleme takvimi ve fire analizi.

---

### Modül 16: `MOD_DOC_MANAGEMENT` — Doküman Yönetimi & Arşivleme
- **Kategori**: `STORAGE`
- **Fiyat**: 80 SAR/ay (800 SAR/yıl) | 650 TRY/ay (6,500 TRY/yıl)
- **Açıklama**: Şirket sözleşmeleri, ruhsatlar ve resmi evrakların bulutta şifreli saklanması ve erişim denetimi.

---

### Modül 17: `MOD_INTERCOMPANY` — Grup Şirketleri & Konsolidasyon
- **Kategori**: `ENTERPRISE`
- **Fiyat**: 200 SAR/ay (2,000 SAR/yıl) | 1,700 TRY/ay (17,000 TRY/yıl)
- **Açıklama**: Çoklu şirketler arası faturalaşma, çapraz stok transferi ve konsolide grup mizanı.

---

### Modül 18: `MOD_API_INTEGRATION` — Açık API & Webhook Entegrasyon Portalı
- **Kategori**: `DEVELOPER`
- **Fiyat**: 150 SAR/ay (1,500 SAR/yıl) | 1,200 TRY/ay (12,000 TRY/yıl)
- **Açıklama**: E-ticaret siteleri (WooCommerce, Shopify, Trendyol) ve harici yazılımlar için REST API anahtarları ve webhook olay dinleyicisi.
