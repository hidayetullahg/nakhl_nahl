# NAKHL & NAHL — MODÜLER LİSANSLAMA VE ABONELİK SİSTEMİ

## 1. Ticari Model
NAKHL & NAHL modüler SaaS yapısında çalışır. Müşteriler yalnızca kullandıkları modülleri satın alır veya aboneliklerini diledikleri zaman genişletebilirler.

---

## 2. 18 Satılabilir Modül Kataloğu
1. **Core ERP (Temel Sistem):** Şirket, şube, kullanıcı, audit log, rol yönetimi.
2. **Cari Yönetimi:** Müşteri, tedarikçi, risk ve bakiye takibi.
3. **Stok & Depo:** Çoklu depo, seri/lot, fire/kalite ayrımı.
4. **Kasa & Banka:** Nakit akışı, banka hesapları, çek/senet.
5. **Fatura & İrsaliye:** Standart ticari faturalama, sevkiyat.
6. **E-Fatura (GİB / Türkiye):** UBL-TR, e-Arşiv, e-İrsaliye.
7. **ZATCA Phase 2 (KSA Fatoora):** UBL 2.1, TLV QR kod, kriptografik imza.
8. **Veri Aktarımı (Data Import Wizard):** Excel, CSV, Logo, Mikro geçiş araçları.
9. **Gelişmiş Raporlama & BI:** Karlılık, yaşlandırma, mizan, gelir tablosu.
10. **POS / Hızlı Satış:** Perakende mağaza ve sıcak satış arayüzü.
11. **Hurma & Tarım Modülü:** Hasat, kalite sınıfları, rekolte, ağaç/tarla takibi.
12. **Arıcılık & Bal Modülü:** Kovan, flora, petek/süzme bal takibi.
13. **İhracat & Uluslararası Ticaret:** Gümrük, navlun, konşimento, dövizli işlemler.
14. **Lojistik & Sevkiyat:** Rota, araç, teslimat noktası planlaması.
15. **Doküman Yönetimi:** Arşiv, sözleşmeler, analiz raporları.
16. **AI & OCR Zekası:** Fatura tarama, otomatik veri çıkarma.
17. **Çoklu Şirket (Intercompany):** Konsolide bilanço ve grup şirket transferleri.
18. **Halal & Kalite Uyumluluğu:** Helal sertifika ve laboratuvar testleri.

---

## 3. Abonelik Durumları ve Veri Koruma Kuralı
* **Statüler:** `ACTIVE`, `TRIAL`, `EXPIRING_SOON`, `EXPIRED`, `LOCKED`.
* **Veri Koruma:** Süresi dolan modüller yalnızca salt-okunur (read-only) moda geçer; kullanıcının ticari verisi asla silinmez.
