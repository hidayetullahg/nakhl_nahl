# PHASE_04 — ADDRESS AND GEOGRAPHY

Amaç: Ülke -> bölge -> şehir -> ilçe -> mahalle parent-child izolasyonunu kurmak ve adres akışını tek kademeli ekranda toplamak.

Oku/tara: `first_time_setup_screen.dart`, `location_service.dart`, `address_catalog.dart`, ilgili modeller/testler.

Kural: İsim tek başına kimlik değildir; her sorguda countryCode ve parent code doğrulanır. Çoklu faaliyet ülkesi ile tek adres ülkesi ayrıdır. Offline boş liste sessiz bırakılmaz, elle giriş sunulur.

Veri: Ülke master'ı yeni ileri-only migration ile eklenir; vergi/gümrük oranları doldurulmaz, `needs_expert_review=true`.

Test: TR/SA izolasyonu, bölge filtresi, ülke değişince alt kademe reseti, çoklu ülke adres sorusu.

Kapı: `.agent/scripts/verify.sh`; migration geçmişine dokunma; raporla ve dur.
