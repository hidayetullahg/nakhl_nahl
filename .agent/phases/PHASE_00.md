# PHASE_00 — DISCOVERY

STATUS: READ_ONLY

Bu faz proje dosyalarını değiştirmez, commit oluşturmaz ve STATE'i güncellemez.

Oku: `.cursorrules`, `nakhl_nahl_anayasa.md`, `ARCHITECTURE.md`, `pubspec.yaml`, `lib/main.dart`, `.agent/CONSTITUTION.md`, `.agent/STATE.md`.

Çalıştır: `.agent/scripts/project_scan.sh`, `flutter --version`, `flutter pub get`, `flutter analyze`, `flutter test`, `dart format --output=none --set-exit-if-changed lib/`, `git status`, `git log --oneline -10`.

Raporla: Dart dosya/satır sayısı, migration sayısı/en yüksek numara, test sayısı, Flutter sürümü, duplicate root adayları, analyze/test/format sonucu, mevcut git değişiklikleri ve baseline riskleri. Kullanıcı değişiklikleri varsa commit yapma. Rapor sonrası dur.
