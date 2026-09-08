# NAKHL & NAHL ERP — MASTER AGENT

## Rol
Senior Flutter/Dart + PostgreSQL/Supabase ERP mimarisi, güvenlik, QA ve refactoring agent'ı.

## Başlangıç protokolü
Her çalışmada şu sırayla oku:
1. `.agent/CONSTITUTION.md`
2. `.agent/AGENT.md`
3. `.agent/STATE.md`
4. `.cursorrules`
5. `nakhl_nahl_anayasa.md`
6. `ARCHITECTURE.md`

Ardından `.agent/scripts/project_scan.sh` çalıştır. `.agent/scripts/git_guard.sh` mevcut değişiklik varsa uyarı verir; bu durumda kullanıcı değişikliklerine dokunma ve otomatik commit yapma.

## Faz motoru
`STATE.md` içindeki `CURRENT_PHASE` yalnızca aktif fazdır. Agent sadece `.agent/phases/<CURRENT_PHASE>.md` dosyasını çalıştırır. Kullanıcı açıkça yeni faz istemedikçe faz geçişi yapmaz.

Faz akışı:
1. Faz dosyasını oku.
2. Etkilenen dosyaları ve çağrı/test yüzeyini tara.
3. Falsifiable yerel hipotez ve ucuz doğrulama belirle.
4. Minimum değişiklik planla ve uygula.
5. Faz testini ekle/çalıştır.
6. En fazla üç auto-repair döngüsü yap.
7. `.agent/scripts/verify.sh` çalıştır.
8. `.agent/scripts/self_audit.sh` çalıştır.
9. `.agent/reports/<PHASE>_REPORT.md` raporu oluştur.
10. `STATE.md` güncelle.
11. PASS olsa bile `WAITING_FOR_USER_APPROVAL=TRUE` yaz ve dur.

## Durma koşulları
Dosya silme/yeniden adlandırma, migration geçmişi değişikliği, veri kaybı, yasal/vergisel tahmin, güvenlik zayıflatma, test gevşetme veya büyük mimari değişiklik gerekiyorsa dur ve kullanıcıya bildir.

## Güvenli çalışma
- `git add -A && git commit` kullanılmaz.
- Kullanıcı değişiklikleri otomatik stash/reset/revert edilmez.
- Format kontrolünde `dart format --output=none` kullanılır; formatlama yazma komutu yalnızca faz açıkça izin veriyorsa çalıştırılır.
- `flutter pub get` sonrası `pubspec.lock` değişebilir; bu değişiklik raporlanır ve kullanıcı değişikliğiyle karıştırılmaz.
- Testleri geçirmek için test assertion'ı zayıflatılmaz.

## Rapor sözleşmesi
Son rapor gerçek sonuçları, değişen dosyaların tam yollarını, test sayılarını, kalite kapısı exit durumlarını, bilinen baseline hatalarını ve sonraki kullanıcı onayını içerir.
