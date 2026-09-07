# NAKHL & NAHL — IAM VE YETKİLENDİRME (RBAC) v2.0

## 1. Kimlik ve Oturum Yönetimi
- Kimlik doğrulama katmanı **Supabase Auth** üzerinden yönetilir.
- Parolalar, tuzlanmış hash'ler (bcrypt) ve oturum anahtarları uygulama tablolarında asla düz metin (plaintext) tutulmaz.
- `public.users` tablosu `auth_user_id` alanı üzerinden doğrudan Supabase Auth kimlik havuzuna bağlanır.
- Oturum yaşam döngüsü:
  - Oturum süresi dolmuş token'lar (`isExpired`) anında reddedilir.
  - Refresh token mekanizması ile kesintisiz ve güvenli oturum yenileme (`oturumYenile()`).
  - Güvenli çıkış (`cikisYap()`): Hem yerel bellek hem de sunucu oturumu sıfırlanır.

---

## 2. Çok Seviyeli Rol Tabanlı Erişim Denetimi (Multi-Level RBAC)
Sistemde roller atomik izinlerle (`permissions`) eşleştirilmiştir:
1. **SUPER_ADMIN**: Platform seviyesinde tenant oluşturma ve SaaS plan yönetimi.
2. **TENANT_ADMIN**: Kiracı seviyesinde şirket, kullanıcı ve modül yönetimi.
3. **COMPANY_MANAGER**: Belirli bir tüzel şirketin tüm ticari operasyonları.
4. **ACCOUNTANT**: Yevmiye, fatura, KDV beyanı ve genel defter yetkisi.
5. **WAREHOUSE_MANAGER**: Stok kabul, transfer, parti/lot ve sevk yetkisi.
6. **QUALITY_INSPECTOR**: Kalite parametreleri, laboratuvar testleri ve helal vize onayları.
7. **SALES_REP / POS_CASHIER**: Satış siparişi oluşturma ve POS tahsilat yetkisi.

---

## 3. Şirket Kısıtlaması (Granular User-Company Access)
Kullanıcının tenant içindeki belirli şirketlerdeki yetki düzeyi `user_company_access` ile belirlenir:
- `VIEW`: Salt okunur rapor ve bakiye görüntüleme
- `OPERATE`: Fatura, irsaliye, transfer girişi yapabilme
- `MANAGE`: Şube, depo ve personel yönetebilme
- `ADMIN`: Şirket tam yöneticisi

---

## 4. Yapay Zeka ve İnsan Onayı Zorunluluğu (Human-in-the-Loop)
Yapay zeka (AI / OCR) motoru hiçbir kritik ticari işlemi otonom olarak gerçekleştiremez:
- `ACCOUNTING_POST` (Resmi Defter Kaydı)
- `STOCK_POST` (Stok Hareketi)
- `PAYMENT` (Ödeme ve Tahsilat)
- `EXPORT_FINALIZATION` (Gümrük ve İhracat Tescili)
- `LEGAL_DOCUMENT_FINALIZATION` (Yasal Belge Onayı)
Bu 5 kritik işlemde geçerli bir `human_user_id` bulunmaması halinde PostgreSQL seviyesinde `SECURITY_VIOLATION` hatası fırlatılır.
