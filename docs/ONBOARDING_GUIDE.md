# NAKHL & NAHL — 16-STEP GLOBAL ONBOARDING & SETUP GUIDE

## 1. Genel Bakış
NAKHL & NAHL ERP platformuna ilk kez giriş yapan işletmeler, sisteme 16 adımlı dinamik sihirbaz (`FirstTimeSetupScreen`) ile dahil edilir. Sihirbaz, **50.250 şehirlik Global Master Data** altyapısına doğrudan bağlıdır.

---

## 2. 16 Adımlı Kurulum Akışı

| Adım | Başlık | Zorunlu Alanlar & Açıklama |
| :--- | :--- | :--- |
| **1. Dil** | Dil Seçimi | En az 1 ana dil (Türkçe, Arapça, İngilizce) seçimi zorunludur (Maks 3 dil). |
| **2. Alfabe** | Script / Yazı Sistemi | Latin (`Latn`) veya Arap (`Arab` - RTL) alfabesi eşlemesi. |
| **3. Ülke** | Faaliyet Ülkesi | KSA veya Türkiye öncelikli ülke seçimi. Seçilen ülkeye göre para birimi (SAR/TRY) ve vergi profili otomatik önerilir. |
| **4. Bölge** | İdari Bölge | Seçilen ülkeye ait bölge / eyalet listesinden seçim. |
| **5. Şehir** | Şehir Seçimi | 50.250 şehirlik veritabanından (KSA 106 şehir, TR 720 şehir/ilçe) autocomplete arama ve seçim. |
| **6. İlçe** | İlçe / Semt | Şehre bağlı ilçe veya belediye seçimi. |
| **7. Mahalle** | Mahalle / PK | Posta kodu ve mahalle seçimi. |
| **8. Açık Adres** | Yapılandırılmış Adres | Cadde, bina ve kapı no. "Hızlı Adres Sihirbazı" (`AddressPickerDialog`) ile tek tıkla doldurulabilir. |
| **9. Sektörler** | Sektör Seçimi | Çok sektörlü yapı: Hurma, Gıda, Tarım, Arıcılık, Tekstil, vb. |
| **10. Kategoriler** | Ürün Kategorileri | İşletmenin ana ürün kategorileri. |
| **11. Ürünler** | Başlangıç Stokları | İlk ürün SKU'su, alış/satış fiyatı, ölçü birimi ve miktarı. |
| **12. Kalite / Fire** | Sınıflandırma | Premium, 1. Sınıf, Sanayi ve Fire / Kusurlu ürün statüleri. |
| **13. Şirket & Vergi** | Resmî Kayıtlar | Ticari unvan, VKN / ZATCA Vergi Numarası (KSA: 15 hane, TR: 10/11 hane), para birimi. |
| **14. Yetkili Kişi** | Kurucu Yönetici | Ad, soyad, e-posta, telefon ve giriş PIN kodu. |
| **15. Rol / Yetki** | Yetki Seviyesi | Admin rolü ataması. |
| **16. Başlangıç Bilanço** | Kasa & Banka Açılışı | Kasa nakit, banka bakiye, müşteri alacakları ve tedarikçi borçları açılış kayıtları. |

---

## 3. Bahtiyar'ın Şirketi (KSA) İlk Kurulum Örneği
1. **Ülke:** Suudi Arabistan (`SA`)
2. **Şehir:** Riyadh (veya Jeddah / Medina / Buraydah)
3. **Para Birimi:** SAR (﷼)
4. **Vergi No:** 15 haneli ZATCA vergi numarası (`3...3`)
5. **Fatura Standardı:** ZATCA Phase 2 Fatoora
6. **Açılış Stokları:** Acve Hurması VIP Duble, Medine Mebrum, vb.
