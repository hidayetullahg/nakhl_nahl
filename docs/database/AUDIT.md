# NAKHL & NAHL — DEĞİŞTİRİLEMEZ AUDIT TRAIL VE UYUM v2.0

## 1. Denetim İzi (Audit Log) Mimarisi
NAKHL & NAHL küresel ERP'sinde gerçekleşen tüm kritik işlemler `audit_logs` tablosunda toplanır:
- `id`: Sıralı tekil kimlik (`BIGSERIAL`)
- `tenant_id`: Kiracı kimliği
- `user_id`: İşlemi yapan kullanıcı
- `company_id`: Tüzel şirket kimliği
- `action`: `CREATE`, `UPDATE`, `DELETE`, `POST`, `APPROVE`, `REJECT`, `REVERSE`, `EXPORT`, `IMPORT`, `LOGIN`, `LOGOUT`
- `entity_type`: Etkilenen tablo adı (`invoices`, `stock_ledger_entries`, `journal_entries` vb.)
- `entity_id`: Kaydın UUID kimliği
- `old_data`: JSONB formatında eski veri durumu
- `new_data`: JSONB formatında yeni veri durumu
- `ip_address` ve `user_agent`: Ağ ve istemci iz bilgileri
- `created_at`: `TIMESTAMPTZ` (UTC)

---

## 2. Kriptografik Bütünlük ve Blok-Benzeri Zincirleme (Cryptographic Chaining)
- Her audit kaydı bir önceki kaydın hash'i ile birleştirilerek SHA-256 algoritmasıyla özetlenir (`current_hash = SHA256(prev_hash || row_data)`).
- Bu sayede veritabanı dosyaları fiziksel olarak değiştirilse dahi `verify_audit_integrity()` RPC fonksiyonu araya eklenen veya silinen satırları tespit eder.

---

## 3. Değiştirilemezlik (Append-Only) Güvencesi
- `prevent_audit_log_modification` trigger'ı:
  * `DELETE` işlemleri kesinlikle engellenir.
  * `UPDATE` işlemleri kesinlikle engellenir.
  * Hatta `SUPER_ADMIN` veya `table_owner` dahi audit tablosundaki veriyi iz bırakmadan silemez.

---

## 4. WORM ve 10 Yıllık Yasal Saklama Politikası (Retention Policy)
- Uluslararası muhasebe ve denetim standartları (ZATCA, GİB, IFRS, Sarbanes-Oxley uyumlu) gereği tüm ticari defter ve denetim kayıtları en az **10 yıl** boyunca saklanır.
- 10 yıldan eski kayıtlar yalnızca yasal arşivleme protokolüyle salt okunur soğuk depolamaya (Cold Storage WORM) aktarılabilir.
