# NAKHL&NAHL Adım Adım Kullanıcı Kılavuzu (User Guide)

## 1. NAKHL&NAHL Nedir?
NAKHL&NAHL; toptan ve perakende ticaret, e-ihracat, depo/stok yönetimi, cari hesaplar, resmi e-fatura (Türkiye GİB ve Suudi Arabistan ZATCA Phase 2) ve tam çift taraflı muhasebe kayıtlarını tek bir çatı altında toplayan modern, güvenli ve bulut tabanlı bir Kurumsal Kaynak Planlama (ERP) platformudur.

---

## 2. İlk Kurulum ve Şirket Yapılandırması (15 Adımlı Yolculuk)

### Adım 1: Şirket Kurulumu
- **Amaç:** Yasal işletme kimliğinizi sisteme tanıtmak.
- **Nereye Gidilir:** Menü → *Ayarlar* → *Şirket Bilgileri*.
- **Neye Tıklanır:** `[Şirket Bilgilerini Düzenle]`.
- **Hangi Bilgi Girilir:** Ticaret Unvanı, VKN/Vergi No, Vergi Dairesi, Adres, Telefon, Para Birimi (TRY / SAR / USD).
- **Sonuç Ne Olur:** Kesilecek tüm fatura ve irsaliyelerin antetine şirket bilgileriniz işlenir.
- **Dikkat Edilmesi Gerekenler:** VKN (10 hane) veya TCKN (11 hane) formatının hatasız olması e-fatura entegrasyonu için zorunludur.
- **Sık Yapılan Hatalar:** Vergi numarasını başında boşlukla girmek.

### Adım 2: Şube ve Depo Tanımlama
- **Amaç:** Ürünlerin fiziki olarak bulunduğu depoları ve satış noktalarını ayırmak.
- **Nereye Gidilir:** Menü → *Stok Yönetimi* → *Depolar*.
- **Neye Tıklanır:** `[+ Yeni Depo]`.
- **Hangi Bilgi Girilir:** Depo Kodu (örn. DEP-01), Depo Adı (örn. Merkez Depo), Sorumlu Personel.
- **Sonuç Ne Olur:** Satın alma ve satış işlemlerinde stok giriş ve çıkışları bu depoya kaydedilir.
- **Sık Yapılan Hatalar:** Depo tanımlamadan ürün ekleyip stok hareketi yapmaya çalışmak.

### Adım 3: İlk Müşterinizi ve Tedarikçinizi Ekleyin
- **Amaç:** Alım ve satım yapacağınız ticari tarafları cari kart olarak oluşturmak.
- **Nereye Gidilir:** Menü → *Müşteriler* → *Yeni Müşteri* (veya *Tedarikçiler*).
- **Neye Tıklanır:** `[+ Yeni Cari Kart]`.
- **Hangi Bilgi Girilir:** Ünvan, Yetkili Ad Soyad, Vergi Numarası, E-posta, Telefon, Vade Günü.
- **Sonuç Ne Olur:** Müşteriye ait açık hesap cari açılır; yapılan tüm satış ve tahsilatlar bu kartta izlenir.

### Adım 4: Ürünlerinizi Oluşturun
- **Amaç:** Satacağınız veya satın alacağınız malların stok kartlarını açmak.
- **Nereye Gidilir:** Menü → *Ürünler*.
- **Neye Tıklanır:** `[+ Yeni Ürün]`.
- **Hangi Bilgi Girilir:** Stok Kodu (SKU), Ürün Adı, Barkod, Birim (Adet/Kg), KDV Oranı (%1, %10, %20), Alış Fiyatı, Satış Fiyatı.
- **Sonuç Ne Olur:** Ürün katalogda listelenir ve faturalarda seçilebilir hale gelir.

### Adım 5: Açılış Stoklarını Girin
- **Amaç:** Sistemi kullanmaya başladığınız andaki mevcut depo sayımlarını sisteme işlemek.
- **Nereye Gidilir:** Menü → *Stok Yönetimi* → *Stok Hareketi Ekle*.
- **Hangi Bilgi Girilir:** Depo, Ürün, Miktar, Birim Maliyet, Hareket Tipi: `Açılış Stoğu`.
- **Sonuç Ne Olur:** Depodaki ürün miktarı güncellenir ve envanter maliyet tablosu oluşur.

### Adım 6: İlk Satışınızı Yapın ve Faturanızı Oluşturun
- **Amaç:** Müşteriye ürün satıp faturasını düzenlemek ve stoğu otomatik düşürmek.
- **Nereye Gidilir:** Menü → *Satış Yönetimi* → *Faturalar*.
- **Neye Tıklanır:** `[+ Yeni Satış Faturası]`.
- **Hangi Bilgi Girilir:** Müşteri seçimi, Fatura Tarihi, Ürün kalemleri ve miktarları, İskonto oranı.
- **Sonuç Ne Olur:** 
  1. Depodaki ürün stoğu otomatik düşer.
  2. Müşterinin cari hesabına borç kaydedilir.
  3. Çift taraflı muhasebe fişi (600 Yurtiçi Satışlar & 391 Hesaplanan KDV) otomatik oluşturulur.
  4. Eğer E-Fatura / ZATCA entegrasyonu açıksa, belge resmi otoriteye iletilir.
- **Dikkat Edilmesi Gerekenler:** Fatura onaylandıktan sonra yasal olarak iptal veya iade süreci gerektirir; taslak aşamasında kontrol ediniz.
