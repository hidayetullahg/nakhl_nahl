# PHASE_02B — I18N UI

Amaç: Kullanıcıya görünen metinleri mevcut `LocaleScriptManager`/`AppDictionary` mimarisine bağlamak.

Sıra: dashboard, onboarding, navigation, login, help, sonra kalan ekranlar. Her dosyayı okumadan değiştirme; tüm `Text`, `Text.rich`, label/hint/tooltip/title/subtitle/semanticLabel ve dialog metinlerini tara.

Kural: Eksik çeviri sessiz fallback yapmaz; `[[namespace.key]]` görünür ve debug log üretir. Ana dil yönü RTL/LTR kararını verir; yardımcı diller düzeni değiştirmez.

Test: `no_hardcoded_ui_text_test.dart` yalnızca gerçek kullanıcı metinlerini yakalasın; teknik identifier, URL, route, sayı ve format istisnaları açıkça listelensin.

Kapı: Her dosya sonrası dar analyze, faz sonunda `.agent/scripts/verify.sh`; taşınan metin/anahtar sayısını raporla ve dur.
