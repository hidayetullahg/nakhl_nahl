// ==============================================================================
// NAKHL & NAHL — HİYERARŞİK ADRES KATALOĞU VE LİSTE SEÇİM TESTLERİ
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/core/address/address_catalog.dart';
import 'package:nakhl_nahl/screens/onboarding/first_time_setup_screen.dart';
import 'package:nakhl_nahl/screens/cari_kart_ekle_screen.dart';

void main() {
  group('1. AddressCatalog Veri ve Filtreleme Testleri', () {
    test('Suudi Arabistan ve Türkiye bölgeleri eksiksiz listelenmeli', () {
      final saRegions = AddressCatalog.getRegionsByCountry('SA');
      expect(saRegions, isNotEmpty);
      expect(saRegions.any((r) => r.name.contains('Riyad')), isTrue);
      expect(saRegions.any((r) => r.name.contains('Mekke')), isTrue);
      expect(saRegions.any((r) => r.name.contains('Medine')), isTrue);

      final trRegions = AddressCatalog.getRegionsByCountry('TR');
      expect(trRegions, isNotEmpty);
      expect(trRegions.any((r) => r.name.contains('Marmara')), isTrue);
      expect(trRegions.any((r) => r.name.contains('İç Anadolu')), isTrue);
    });

    test('Şehir listesi bölge ve ülke bazında doğru filtrelenmeli', () {
      final saCities = AddressCatalog.getCities(countryCode: 'SA');
      expect(saCities.any((c) => c.name == 'Riyad'), isTrue);
      expect(saCities.any((c) => c.name == 'Medine-i Münevvere'), isTrue);
      expect(saCities.any((c) => c.name == 'Cidde'), isTrue);

      final trCities = AddressCatalog.getCities(countryCode: 'TR');
      expect(trCities.any((c) => c.name == 'İstanbul'), isTrue);
      expect(trCities.any((c) => c.name == 'Ankara'), isTrue);
      expect(trCities.any((c) => c.name == 'İzmir'), isTrue);
    });

    test('İlçe ve mahalle hiyerarşisi doğru eşleşmeli', () {
      final riyadhDistricts = AddressCatalog.getDistrictsByCity('Riyad');
      expect(riyadhDistricts.any((d) => d.name == 'El-Olaya'), isTrue);

      final fatihNeighborhoods = AddressCatalog.getNeighborhoodsByDistrict('Fatih');
      expect(fatihNeighborhoods.any((n) => n.name == 'Akşemsettin Mah.'), isTrue);
      expect(fatihNeighborhoods.first.postalCode, isNotEmpty);
    });
  });

  group('2. FirstTimeSetupScreen Adres Liste Entegrasyon Testleri', () {
    testWidgets('Adım 4 Bölge Seçiminde hazır liste chip\'leri görüntülenmeli',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: FirstTimeSetupScreen(),
        ),
      );

      final nextBtn = find.text('Devam Et');

      // Step 1 -> 2 -> 3 -> 4
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      // Step 4 Bölge Seçimi
      expect(find.text('4. Bölge / Eyalet Seçimi'), findsOneWidget);
      expect(find.textContaining('Hazır Listeden Seçiniz'), findsOneWidget);
      expect(find.textContaining('Riyad Bölgesi'), findsWidgets);
    });
  });

  group('3. CariKartEkleScreen Adres Listesi Entegrasyonu', () {
    testWidgets('Listeden Adres Seç butonu render edilmeli',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: CariKartEkleScreen(),
        ),
      );

      expect(find.text('Listeden Adres Seç'), findsOneWidget);
      expect(find.text('Fatura Adresi & Lokasyon'), findsOneWidget);
    });
  });
}
