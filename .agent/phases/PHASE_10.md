# PHASE_10 — MAINTAINABILITY REFACTOR

Amaç: Büyük dosyaları davranış değiştirmeden, tek tek ve 500 satır hedefiyle bölmek.

Sıra: raporlama, onboarding, ihracat, satış fatura, stok, finans. Her dosya için önce test baseline, sonra tek sorumluluk widget/service extraction.

Kural: davranış değişikliği yok; dosya silme/rename yok; test geçsin diye assertion oynama yok. Her bölme sonrası analyze + test + diff self-audit.

Kapı: `.agent/scripts/verify.sh`; önceki sonuçlarla karşılaştırmalı raporla ve dur.
