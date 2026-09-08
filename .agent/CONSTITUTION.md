# NAKHL & NAHL ERP — AGENT CONSTITUTION

VERSION: 1.0

Bu proje sıfırdan yazılmaz. Agent, mevcut sistemi okur, kanıtlar, en küçük değişikliği yapar, test eder ve raporlar.

## 1. Dosya güvenliği
- Dosya/klasör silme, yeniden adlandırma veya paket/sınıf adı değiştirme yapılmaz.
- Kullanıcı değişiklikleri ezilmez ve otomatik commit edilmez.
- Migration geçmişi geriye dönük değiştirilmez.

## 2. Migration güvenliği
Yeni veritabanı değişiklikleri yalnızca ileri-only `063_`, `064_`... dosyalarıyla yapılır. Mevcut migration dosyaları salt okunur kabul edilir.

## 3. Okumadan yazma
Değişiklikten önce hedef dosya, sembol, çağıranlar, ilgili testler ve bağımlılıklar okunur. Eski satır numaraları kanıt değildir; mevcut kod esas alınır.

## 4. Tahmin yasağı
Vergi, gümrük, mevzuat, hukuki metin, yasal süre ve resmi finansal düzenleme tahmin edilmez. Kanıt yoksa `needs_expert_review=true` kullanılır.

## 5. Para güvenliği
Finansal hesaplamalarda `double` kullanılmaz. `Money`/`Decimal` veya exact fixed-point yapı kullanılır. Decimal'dan double'a dönüşüm yasaktır.

## 6. AI güvenliği
AI çıktısı muhasebe, vergi, hukuk, stok veya finansal belgeye doğrudan dönüşemez. İnsan onayına kadar `PROPOSAL` olarak kalır.

## 7. Çeviri ve RTL
Kullanıcıya görünen metinler mevcut `LocaleScriptManager`/`AppDictionary` mimarisinden gelir. Eksik çeviri sessiz fallback yapmaz; debug'da `[[key]]` görünür.

## 8. Faz protokolü
Her faz: START -> READ -> PLAN -> MODIFY -> TEST -> VERIFY -> REPORT -> STOP. Bir faz raporu ve kalite kapısı tamamlanmadan sonraki faza geçilmez.

## 9. Kalite kapısı
Faz PASS için `flutter analyze`, `flutter test`, salt-okuma `dart format --output=none --set-exit-if-changed lib/`, faz testleri, dosya güvenliği ve migration güvenliği PASS olmalıdır. Mevcut baseline hataları rapordan saklanmaz.

## 10. Auto-repair sınırı
En fazla üç kontrollü düzeltme döngüsü yapılır. Çözülemeyen veya yüksek riskli durumda `FAILED/BLOCKED` raporu üretilir ve agent durur.

## 11. Self-audit
Agent sonunda diff'i, değişen dosyaları, silinen dosyaları, migration değişikliklerini, secret/API key eklemelerini, test silme veya assertion gevşetme girişimlerini kontrol eder. Faz dışı değişiklikte durur.

## 12. Dürüst rapor
Eksik özellik tamamlandı denmez. `PHASE`, `STATUS`, `FILES_CHANGED`, `TESTS_ADDED`, `TEST_RESULTS`, `ANALYZE_RESULT`, `FORMAT_RESULT`, `DATABASE_CHANGES`, `KNOWN_ISSUES`, `NEXT_ACTION` alanları raporda bulunur.
