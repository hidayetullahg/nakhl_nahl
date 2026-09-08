# PHASE_03 — THEME AND GRID

Amaç: Kontrastı, ızgara standardını ve ortak seçim kartlarını sağlamlaştırmak.

Oku/tara: `lib/core/theme/`, seçim ekranları ve mevcut kart bileşenleri.

Uygula: Nötr yüksek kontrastlı açık zemin; marka sıcak kum yüzeyini yalnızca accent surface olarak koru. Maksimum içerik genişliği 1200px, responsive 4/2/1 grid, minimum 48px dokunma alanı, ortak `SelectionCard`; dışarıdan farklı kart boyutu kabul etme.

Test: WCAG AA kontrast testi ve SelectionCard ölçü/erişilebilirlik testi.

Kapı: `.agent/scripts/verify.sh`; faz dışı ekran refactor yapma; raporla ve dur.
