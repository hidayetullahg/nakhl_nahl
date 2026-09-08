# NAKHL & NAHL Agent Orchestration

Bu klasör, sohbet geçmişinden bağımsız çalışan faz kontrollü agent protokolüdür.

## Başlatma komutu

Antigravity/IDE agent'a şu metni ver:

```text
Bu projede .agent/AGENT.md ana çalışma protokolündür.
Önce .agent/CONSTITUTION.md, .agent/AGENT.md, .agent/STATE.md,
.cursorrules, nakhl_nahl_anayasa.md ve ARCHITECTURE.md dosyalarını oku.
.agent/STATE.md içindeki CURRENT_PHASE değerindeki tek fazı çalıştır.
.agent/scripts/project_scan.sh ve git_guard.sh ile başla.
Kullanıcı değişikliklerini ezme veya otomatik commit etme.
Faz kapısını, self-audit'i ve raporu üret; PASS olsa bile sonraki faza geçme.
Sonra dur.
```

## Faz geçişi

Agent kendi kendine faz değiştirmez. Kullanıcı açıkça onay verdiğinde `STATE.md` içindeki `CURRENT_PHASE` güncellenir. Faz PASS değilse yeni faz başlatılmaz.

## Scriptler

- `scripts/project_scan.sh`: salt-okuma proje ölçümü
- `scripts/git_guard.sh`: kirli çalışma ağacında otomatik commit'i engeller
- `scripts/self_audit.sh`: diff güvenlik taraması
- `scripts/verify.sh`: analyze, test ve salt-okuma format kalite kapısı

PowerShell karşılıkları Windows ortamında aynı amaçla kullanılabilir.

## Raporlar

Faz raporları `reports/PHASE_XX_REPORT.md` altına yazılır. `STATE.md` son bilinen durumdur. Bu dosyalar agent hafızasıdır; gerçek kod doğrulamasının yerine geçmez.
