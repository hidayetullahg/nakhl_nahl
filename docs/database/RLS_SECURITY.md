# NAKHL & NAHL — RLS GÜVENLİK VE ERİŞİM STRATEJİSİ v2.0

## 1. Temel Güvenlik İlkeleri (Zero Trust Database Layer)
1. **İstemci Beyanına Güvenilmez:** İstemciden (Flutter / Web / Mobile) gelen hiçbir `tenant_id` veya `company_id` filtresi sunucu tarafında doğrulanmadan kabul edilmez.
2. **%100 Zorunlu Satır Düzeyi Güvenlik (Forced RLS):** Public şemasındaki tüm tablolar istisnasız:
   - `ALTER TABLE ... ENABLE ROW LEVEL SECURITY;`
   - `ALTER TABLE ... FORCE ROW LEVEL SECURITY;`
   direktifleriyle korunur. Tablo sahibi (`table owner`) dahil hiç kimse RLS kalkanını baypas edemez.

---

## 2. Doğrulama Zinciri
Her bir veritabanı sorgusu (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) arka planda şu hiyerarşik güvenlik fonksiyonlarını çalıştırır:
```
auth.uid() (Supabase Auth Oturumu)
  └── public.users (Aktif Sistem Kullanıcısı)
        └── tenant_users (status = 'ACTIVE')
              └── is_tenant_member(tenant_id)
                    └── has_company_access(company_id)
                          └── has_permission(tenant_id, permission_code)
                                └── PostgreSQL RLS Policy
```

---

## 3. RLS Güvenlik Yardımcı Fonksiyonları (SECURITY DEFINER Hardening)
Bütün fonksiyonlar `SET search_path = public` direktifiyle donatılmış, genel erişim (`PUBLIC`) kısıtlanmıştır:
- `get_current_user_id()`: Mevcut Supabase oturum sahibinin `public.users.id` değerini getirir.
- `is_tenant_member(p_tenant_id)`: Kullanıcının ilgili kiracının aktif üyesi olup olmadığını kontrol eder.
- `is_tenant_admin(p_tenant_id)`: Kullanıcının kiracı yöneticisi veya süper yönetici olduğunu doğrular.
- `has_company_access(p_company_id)`: Şirket bazlı yetki matrisini (`user_company_access`) denetler.
- `has_permission(p_tenant_id, p_permission_code)`: Atomik işlem iznini (`INVENTORY.POST`, `SALES.INVOICE_CREATE` vb.) doğrular.

---

## 4. Cross-Tenant ve Cross-Company İhlal Savunması
- Yetkisiz bir kullanıcı başka bir kiracının veya şirketin verisini çekmeye çalıştığında, RLS politikaları sorguyu sessizce `0 rows` olarak döndürür veya `CHECK` kısıtıyla işlemi veritabanı düzeyinde keser.
- Tüm yetkisiz erişim girişimleri `audit_logs` tablosunda kalıcı olarak mühürlenir.
